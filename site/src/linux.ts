// Linux в браузере: эмулятор v86 + терминал xterm.js
//   ttyS0 (serial0) — терминал пользователя
//   ttyS1 (serial1) — скрытый помощник lab-agent: через него сайт запускает проверки
import { V86 } from "v86";
import wasmUrl from "v86/build/v86.wasm?url";
import { Terminal } from "@xterm/xterm";
import { FitAddon } from "@xterm/addon-fit";
import "@xterm/xterm/css/xterm.css";
import vmConfig from "../image/v86-config.json";
import { vmStore } from "./storage";
import { syncCourse, coursePath } from "./course-sync.js";

// Скрипты курса (те же файлы, что и в Docker-лаборатории) — доставляются в Linux при запуске
const COURSE_SOURCES = import.meta.glob(["../../lab/lab", "../../lib/*.sh", "../../modules/*/*"], {
  query: "?raw",
  import: "default",
  eager: true,
}) as Record<string, string>;
const COURSE_FILES = Object.entries(COURSE_SOURCES).map(([path, text]) => ({
  path: coursePath(path),
  data: new TextEncoder().encode(text),
}));

const BASE = import.meta.env.BASE_URL;
const AUTOSAVE_MS = 60_000;
// Открой сайт с ?debug в адресе, чтобы видеть в консоли ответы скрытого помощника
const DEBUG = new URLSearchParams(location.search).has("debug");

export type Status = { text: string; kind: "loading" | "ok" | "error" };

// ---------- Результат проверки модуля ----------
export type CheckItem = { ok: boolean; text: string; hint: string };
export type QuizQuestion = { question: string; hint: string; pattern: RegExp };
export type CheckResult = {
  sections: Array<{ title: string; items: CheckItem[] }>;
  quiz: QuizQuestion[];
  passed: number;
  total: number;
};

function parseCheck(lines: string[]): CheckResult {
  const res: CheckResult = { sections: [], quiz: [], passed: 0, total: 0 };
  const current = () => {
    if (!res.sections.length) res.sections.push({ title: "", items: [] });
    return res.sections[res.sections.length - 1];
  };
  for (const line of lines) {
    const [tag, ...f] = line.split("\t");
    if (tag === "@@SECTION") res.sections.push({ title: f[0], items: [] });
    else if (tag === "@@PASS") current().items.push({ ok: true, text: f[0], hint: "" });
    else if (tag === "@@FAIL") current().items.push({ ok: false, text: f[0], hint: f[1] || "" });
    else if (tag === "@@QUIZ") {
      // Регулярка из check.sh (bash ERE) — те же простые выражения работают и в JS
      const flags = f[3] === "cs" ? "u" : "iu";
      res.quiz.push({ question: f[0], hint: f[1], pattern: new RegExp(`^(${f[2]})$`, flags) });
    } else if (tag === "@@SUMMARY") {
      res.passed = Number(f[0]);
      res.total = Number(f[1]);
    }
  }
  res.sections = res.sections.filter((s) => s.items.length);
  return res;
}

// ---------- Сжатие сохранений (снимок памяти Linux хорошо жмётся) ----------
async function gzip(buf: ArrayBuffer): Promise<ArrayBuffer> {
  return new Response(new Blob([buf]).stream().pipeThrough(new CompressionStream("gzip"))).arrayBuffer();
}
async function gunzip(buf: ArrayBuffer): Promise<ArrayBuffer> {
  return new Response(new Blob([buf]).stream().pipeThrough(new DecompressionStream("gzip"))).arrayBuffer();
}

export class Linux {
  private term: Terminal;
  private fit = new FitAddon();
  private emulator!: V86;
  private onStatus: (s: Status) => void;
  private ready = false;
  private imageVersion = "";
  private dirty = false;
  private saving: Promise<void> | null = null;
  private courseReady: Promise<void> = Promise.resolve();

  // Скрытый канал ttyS1
  private agentBuf: number[] = [];
  private agentLines: string[] = [];
  private agentWaiter: ((lines: string[]) => void) | null = null;
  private agentQueue: Promise<unknown> = Promise.resolve();

  constructor(container: HTMLElement, onStatus: (s: Status) => void) {
    this.onStatus = onStatus;
    this.term = new Terminal({
      fontFamily: '"JetBrains Mono", Menlo, "SF Mono", Consolas, monospace',
      fontSize: 14,
      cursorBlink: true,
      scrollback: 5000,
      theme: { background: "#0d1117", foreground: "#e6edf3", cursor: "#3fb950" },
    });
    this.term.loadAddon(this.fit);
    this.term.open(container);
    this.fit.fit();
    this.term.writeln("\x1b[2mЗагружаю Linux в браузере… Первый раз может занять до минуты.\x1b[0m");

    let resizeTimer: number | undefined;
    new ResizeObserver(() => {
      clearTimeout(resizeTimer);
      resizeTimer = window.setTimeout(() => this.syncSize(), 200);
    }).observe(container);
  }

  async start() {
    this.imageVersion = await fetch(BASE + "images/version.json")
      .then((r) => r.json())
      .then((j) => j.version as string)
      .catch(() => "dev");

    let saved: ArrayBuffer | undefined;
    const record = await vmStore.load();
    if (record && record.version === this.imageVersion) {
      saved = await gunzip(record.data).catch(() => undefined);
    } else if (record) {
      // Linux на сайте обновился — старое сохранение к нему не подходит
      await vmStore.clear();
      this.term.writeln("\x1b[33mКурс обновился, поэтому Linux запущен заново (старое сохранение не подходит).\x1b[0m");
    }

    this.emulator = new V86({
      wasm_path: wasmUrl,
      bios: { url: BASE + "v86/bios/seabios.bin" },
      vga_bios: { url: BASE + "v86/bios/vgabios.bin" },
      filesystem: { baseurl: BASE + "images/rootfs-flat/", basefs: BASE + "images/fs.json" },
      initial_state: saved ? undefined : { url: BASE + "images/state.bin.zst" },
      bzimage_initrd_from_filesystem: true,
      autostart: !saved,
      disable_keyboard: true,
      disable_mouse: true,
      ...vmConfig,
    } as any);

    this.emulator.add_listener("download-progress", (e: any) => {
      if (!this.ready && e.lengthComputable && e.total > 1e6) {
        this.onStatus({ text: `Загрузка Linux: ${Math.round((e.loaded / e.total) * 100)}%`, kind: "loading" });
      }
    });

    // Вывод Linux → терминал. Байты UTF-8 копим и отдаём пачкой раз в кадр.
    let pending: number[] = [];
    this.emulator.add_listener("serial0-output-byte", (b: number) => {
      if (pending.length === 0) {
        requestAnimationFrame(() => {
          this.term.write(new Uint8Array(pending));
          pending = [];
        });
      }
      pending.push(b);
    });

    // Ввод → Linux (в UTF-8, чтобы работала кириллица)
    const enc = new TextEncoder();
    this.term.onData((d) => {
      this.dirty = true;
      this.emulator.serial_send_bytes(0, enc.encode(d));
    });

    // Скрытый канал: собираем строки до @@END
    const dec = new TextDecoder();
    this.emulator.add_listener("serial1-output-byte", (b: number) => {
      if (b === 0x11 || b === 0x13) return; // XON/XOFF — служебные символы терминала
      if (b !== 10) {
        this.agentBuf.push(b);
        return;
      }
      const line = dec.decode(new Uint8Array(this.agentBuf)).replace(/\r$/, "");
      this.agentBuf = [];
      if (DEBUG) console.log("[agent]", JSON.stringify(line));
      if (line === "@@END") {
        const lines = this.agentLines;
        this.agentLines = [];
        this.agentWaiter?.(lines);
        this.agentWaiter = null;
      } else if (line !== "@@READY") {
        this.agentLines.push(line);
      }
    });

    this.emulator.add_listener("emulator-loaded", async () => {
      if (saved) {
        try {
          await this.emulator.restore_state(saved);
        } catch {
          await vmStore.clear();
          location.reload();
          return;
        }
        await this.emulator.run();
        this.term.clear();
        this.ready = true;
        this.syncSize();
      } else {
        this.ready = true;
        setTimeout(() => this.syncSize(), 300);
      }
      this.term.focus();
      this.startAutosave();
      // «Запущен» показываем только когда курс уже внутри Linux — иначе `lab` ответит «курс загружается»
      this.onStatus({ text: "Загружаю курс…", kind: "loading" });
      this.courseReady = this.installCourse();
      this.courseReady.then(
        () => this.onStatus({ text: saved ? "Linux восстановлен ✓" : "Linux запущен ✓", kind: "ok" }),
        () => {},
      );
    });
  }

  get isReady() {
    return this.ready;
  }

  /** Сообщить Linux размер окна терминала (иначе vim, less и nano рисуются криво) */
  private syncSize() {
    this.fit.fit();
    if (!this.ready) return;
    this.emulator.serial0_send(`stty rows ${this.term.rows} cols ${this.term.cols}; clear\n`);
  }

  focus() {
    this.term.focus();
  }

  /** Выполнить команду скрытого помощника и получить строки ответа */
  private agent(cmd: string, timeoutMs = 60_000): Promise<string[]> {
    const run = () =>
      new Promise<string[]>((resolve, reject) => {
        const timer = setTimeout(() => {
          this.agentWaiter = null;
          reject(new Error("Linux не ответил вовремя"));
        }, timeoutMs);
        this.agentWaiter = (lines) => {
          clearTimeout(timer);
          resolve(lines);
        };
        this.emulator.serial_send_bytes(1, new TextEncoder().encode(cmd + "\n"));
      });
    const p = this.agentQueue.then(run, run);
    this.agentQueue = p.catch(() => {});
    return p;
  }

  /** Установить/обновить скрипты курса внутри Linux (если версия изменилась) */
  private async installCourse() {
    try {
      const t0 = performance.now();
      const updated = await syncCourse((cmd: string) => this.agent(cmd), COURSE_FILES);
      if (DEBUG) console.log(`[course] ${updated ? "установлен" : "актуален"} за ${Math.round(performance.now() - t0)} мс`);
    } catch (e) {
      this.onStatus({ text: "Не удалось загрузить курс: " + (e as Error).message, kind: "error" });
      throw e;
    }
  }

  /** Проверить задания модуля (как `lab check N`, но результат — для интерфейса) */
  async check(num: string): Promise<CheckResult> {
    if (!this.ready) throw new Error("Linux ещё загружается");
    await this.courseReady;
    const lines = await this.agent(`check ${Number(num)}`);
    const res = parseCheck(lines);
    if (!lines.some((l) => l.startsWith("@@SUMMARY\t"))) {
      console.warn("[agent] неожиданный ответ проверки:", lines);
    }
    return res;
  }

  // ---------- Сохранение ----------
  async save(silent = false) {
    if (!this.ready) return;
    if (this.saving) return this.saving;
    this.saving = (async () => {
      if (!silent) this.onStatus({ text: "Сохраняю…", kind: "loading" });
      try {
        this.dirty = false;
        const state = await this.emulator.save_state();
        await vmStore.save({ version: this.imageVersion, data: await gzip(state) });
        this.onStatus({ text: silent ? "Автосохранено ✓" : "Сохранено ✓", kind: "ok" });
      } catch (e) {
        this.dirty = true;
        this.onStatus({ text: "Не удалось сохранить: " + (e as Error).message, kind: "error" });
      } finally {
        this.saving = null;
      }
    })();
    return this.saving;
  }

  private startAutosave() {
    setInterval(() => this.dirty && this.save(true), AUTOSAVE_MS);
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState === "hidden" && this.dirty) this.save(true);
    });
  }

  async reset() {
    await vmStore.clear();
    location.reload();
  }
}
