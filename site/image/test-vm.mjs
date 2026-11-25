// Автотест Linux для сайта (без браузера):
//  1) запускает Linux из снимка, доставляет курс через скрытого помощника (как сайт);
//  2) для каждого модуля: проверка ДО выполнения заданий (должны быть ✘) и ПОСЛЕ (всё ✔),
//     в машинном формате, который читает сайт — каждая строка проверяется на корректность;
//  3) текстовый режим lab check (как в Docker-лаборатории).
// Запуск (из site/):  node image/test-vm.mjs   или   npm run test:vm
import fs from "node:fs";
import path from "node:path";
import url from "node:url";
import { V86 } from "v86";
import { syncCourse, coursePath } from "../src/course-sync.js";

const SITE = path.join(path.dirname(url.fileURLToPath(import.meta.url)), "..");
const ROOT = path.join(SITE, "..");
const CONFIG = JSON.parse(fs.readFileSync(path.join(SITE, "image/v86-config.json"), "utf8"));

// Файлы курса — те же, что сайт собирает через import.meta.glob
function listCourse() {
  const files = ["lab/lab"];
  for (const f of fs.readdirSync(path.join(ROOT, "lib"))) if (f.endsWith(".sh")) files.push(`lib/${f}`);
  for (const d of fs.readdirSync(path.join(ROOT, "modules"))) {
    for (const f of fs.readdirSync(path.join(ROOT, "modules", d))) files.push(`modules/${d}/${f}`);
  }
  return files.map((p) => ({ path: coursePath(p), data: new Uint8Array(fs.readFileSync(path.join(ROOT, p))) }));
}

const emulator = new V86({
  wasm_path: path.join(SITE, "node_modules/v86/build/v86.wasm"),
  bios: { url: path.join(SITE, "public/v86/bios/seabios.bin") },
  vga_bios: { url: path.join(SITE, "public/v86/bios/vgabios.bin") },
  filesystem: { baseurl: path.join(SITE, "public/images/rootfs-flat"), basefs: path.join(SITE, "public/images/fs.json") },
  initial_state: { url: path.join(SITE, "public/images/state.bin.zst") },
  autostart: true,
  bzimage_initrd_from_filesystem: true,
  ...CONFIG,
});

// ---------- Скрытый помощник (ttyS1) ----------
let agentBuf = [], agentLines = [], agentWaiter = null;
emulator.add_listener("serial1-output-byte", (b) => {
  if (b === 0x11 || b === 0x13) return; // XON/XOFF
  if (b !== 10) return void agentBuf.push(b);
  const line = Buffer.from(agentBuf).toString("utf8").replace(/\r$/, "");
  agentBuf = [];
  if (line === "@@END") { const l = agentLines; agentLines = []; agentWaiter?.(l); agentWaiter = null; }
  else if (line !== "@@READY") agentLines.push(line);
});
const agent = (cmd, timeout = 60000) => new Promise((resolve, reject) => {
  const t = setTimeout(() => reject(new Error("Таймаут помощника: " + cmd)), timeout);
  agentWaiter = (l) => { clearTimeout(t); resolve(l); };
  emulator.serial_send_bytes(1, new TextEncoder().encode(cmd + "\n"));
});

// ---------- Терминал пользователя (ttyS0) ----------
let out = [];
emulator.add_listener("serial0-output-byte", (b) => out.push(b));
let n = 0;
async function shell(cmd, timeoutMs = 120000) {
  const marker = `__DONE_${++n}__`;
  out = [];
  emulator.serial_send_bytes(0, new TextEncoder().encode(`${cmd}; echo "${marker.slice(0, 4)}""${marker.slice(4)}"\n`));
  const start = Date.now();
  const text = () => Buffer.from(out).toString("utf8");
  while (!/__DONE_\d+__\r?\n/.test(text()) || !text().includes(marker)) {
    if (Date.now() - start > timeoutMs) throw new Error(`Таймаут: ${cmd}\n${text()}`);
    await new Promise((r) => setTimeout(r, 100));
  }
  return text();
}

// Решения заданий (то, что сделал бы ученик)
const SOLUTIONS = {
  1: `cd ~/m01 && whoami > me.txt && uname -a > system.txt && echo penguin > code.txt && (cd /etc && ls > ~/m01/etc-list.txt) && seq 12 > history.txt; cd`,
  2: `cd ~/m02 && mkdir -p myapp/{src,tests,docs,config} && touch myapp/README.md myapp/src/main.py && cd downloads && mkdir images documents music && mv *.jpg *.png images/ && mv *.pdf *.txt documents/ && mv *.mp3 music/ && rm *.tmp && cd .. && mkdir found && cp "$(find maze -name treasure.txt)" found/ && realpath "$(find maze -size +1M)" > big.txt && cp -r myapp myapp-backup && mv myapp/docs myapp/documentation && rm -r trash; cd`,
  3: `cd ~/m03 && head -n 10 app.log > first10.txt && tail -n 3 app.log > last3.txt && grep -c ERROR app.log > errors_count.txt && grep -n ERROR app.log > errors.txt && grep user_id=1337 app.log > user1337.txt && grep -v INFO app.log > not_info.txt && sed -i "s/port=8080/port=3000/; s/debug=true/debug=false/" config.ini && echo "I can exit vim" > vim.txt; cd`,
};

// Строгая проверка машинного формата: ровно то, что умеет разбирать сайт
const FORMAT = {
  "@@SECTION": 2, "@@PASS": 2, "@@FAIL": 3, "@@SUMMARY": 3,
  "@@QUIZ": 5,
};
function validate(lines) {
  const errors = [];
  for (const l of lines) {
    const f = l.split("\t");
    if (!(f[0] in FORMAT)) errors.push("неизвестная строка: " + JSON.stringify(l.slice(0, 80)));
    else if (f.length !== FORMAT[f[0]]) errors.push(`${f[0]}: ${f.length} полей вместо ${FORMAT[f[0]]}: ` + JSON.stringify(l.slice(0, 80)));
    else if (f[0] === "@@QUIZ") {
      try { new RegExp(`^(${f[3]})$`, f[4] === "cs" ? "u" : "iu"); } catch (e) { errors.push("регулярка квиза не работает в JS: " + f[3]); }
    }
  }
  const sum = lines.find((l) => l.startsWith("@@SUMMARY\t"));
  if (!sum) errors.push("нет строки @@SUMMARY");
  const [, passed, total] = sum ? sum.split("\t").map(Number) : [];
  return { errors, passed, total };
}

let failed = false;
const ok = (cond, msg) => { console.log(cond ? "  ✔" : "  ✘", msg); if (!cond) failed = true; };

emulator.add_listener("emulator-started", async () => {
  const t0 = Date.now();
  try {
    await new Promise((r) => setTimeout(r, 500));
    await shell("stty -echo cols 200; export PS1=''");

    const files = listCourse();
    console.log(`Курс: ${files.length} файлов`);
    ok(await syncCourse(agent, files), "Курс доставлен в Linux через помощника");
    ok(!(await syncCourse(agent, files)), "Повторно курс не грузится (версия совпала)");
    const info = await shell("hostname; whoami; man -w ls; lab list");
    ok(/linux-lab/.test(info) && /student/.test(info), "hostname linux-lab, пользователь student");
    ok(/ls\.1/.test(info), "man-страницы на месте");

    const modules = fs.readdirSync(path.join(ROOT, "modules")).map((d) => Number(d.slice(0, 2))).sort();
    for (const m of modules) {
      console.log(`Модуль ${m}:`);
      if (!SOLUTIONS[m]) { ok(false, `нет решения для модуля ${m} в test-vm.mjs — добавь его в SOLUTIONS`); continue; }
      await shell(`lab setup ${m} </dev/null`);
      const before = validate(await agent(`check ${m}`));
      ok(before.errors.length === 0, "формат ответа ДО выполнения заданий" + (before.errors.length ? ": " + before.errors.join("; ") : ""));
      ok(before.total > 0 && before.passed < before.total, `до выполнения не всё засчитано (${before.passed}/${before.total})`);
      await shell(SOLUTIONS[m]);
      const after = validate(await agent(`check ${m}`));
      ok(after.errors.length === 0, "формат ответа ПОСЛЕ выполнения" + (after.errors.length ? ": " + after.errors.join("; ") : ""));
      ok(after.total > 0 && after.passed === after.total, `после выполнения всё засчитано (${after.passed}/${after.total})`);
      const text = await shell(`lab check ${m} -q 2>&1 | sed 's/\\x1b\\[[0-9;]*m//g' | tail -3`);
      ok(text.includes("Отлично!"), "текстовый режим lab check (как в Docker)");
    }
    console.log(`Время: ${Math.round((Date.now() - t0) / 1000)} с`);
  } catch (e) {
    console.error(e.message);
    failed = true;
  }
  console.log(failed ? "❌ ЕСТЬ ОШИБКИ" : "✅ ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ");
  process.exit(failed ? 1 : 0);
});
