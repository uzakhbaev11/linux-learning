// Доставка скриптов курса (lab, lib, modules) внутрь Linux через скрытого помощника lab-agent.
// Общий код для сайта (src/linux.ts) и автотестов (image/test-vm.mjs) — поэтому обычный JS.
//
// Зачем: если «запекать» курс в образ Linux, то каждый новый модуль меняет образ,
// и сохранения учеников становятся несовместимыми. А так образ стабилен,
// а курс обновляется на лету при каждом запуске сайта.


/**
 * @typedef {{ path: string, data: Uint8Array }} CourseFile
 * @typedef {(command: string) => Promise<string[]>} AgentSend
 */

/** Версия курса = SHA-256 от всех путей и содержимого (первые 16 символов) */
export async function courseVersion(/** @type {CourseFile[]} */ files) {
  const parts = [];
  for (const f of [...files].sort((a, b) => a.path.localeCompare(b.path))) {
    parts.push(new TextEncoder().encode(f.path + "\0"), f.data, new Uint8Array([0]));
  }
  const all = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
  let off = 0;
  for (const p of parts) { all.set(p, off); off += p.length; }
  const hash = new Uint8Array(await crypto.subtle.digest("SHA-256", all));
  return [...hash].map((b) => b.toString(16).padStart(2, "0")).join("").slice(0, 16);
}

async function gzip(/** @type {Uint8Array} */ data) {
  const stream = new Blob([data]).stream().pipeThrough(new CompressionStream("gzip"));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}

/** Простейший tar (формат ustar): заголовок 512 байт + содержимое, выровненное до 512 */
function makeTar(/** @type {CourseFile[]} */ files) {
  const enc = new TextEncoder();
  const blocks = [];
  const field = (/** @type {Uint8Array} */ h, /** @type {string} */ str, /** @type {number} */ off, /** @type {number} */ len) =>
    h.set(enc.encode(str).subarray(0, len), off);
  for (const f of files) {
    const h = new Uint8Array(512);
    field(h, f.path, 0, 100);                                        // имя
    field(h, "0000644\0", 100, 8);                                   // права
    field(h, "0001750\0", 108, 8);                                   // uid 1000
    field(h, "0001750\0", 116, 8);                                   // gid 1000
    field(h, f.data.length.toString(8).padStart(11, "0") + "\0", 124, 12); // размер
    field(h, "00000000000\0", 136, 12);                              // время
    field(h, "        ", 148, 8);                                     // место под контрольную сумму
    h[156] = 48;                                                      // тип «0» — обычный файл
    field(h, "ustar\0" + "00", 257, 8);
    const sum = h.reduce((a, b) => a + b, 0);
    field(h, sum.toString(8).padStart(6, "0") + "\0 ", 148, 8);
    blocks.push(h, f.data, new Uint8Array((512 - (f.data.length % 512)) % 512));
  }
  blocks.push(new Uint8Array(1024)); // конец архива
  const out = new Uint8Array(blocks.reduce((n, b) => n + b.length, 0));
  let off = 0;
  for (const b of blocks) { out.set(b, off); off += b.length; }
  return out;
}

async function sha256hex(/** @type {Uint8Array} */ data) {
  const hash = new Uint8Array(await crypto.subtle.digest("SHA-256", data));
  return [...hash].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function toBase64(/** @type {Uint8Array} */ bytes) {
  let s = "";
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

function expectOk(/** @type {string[]} */ lines, /** @type {string} */ what) {
  if (!lines.includes("@@OK")) throw new Error(`Не удалось ${what}: ${JSON.stringify(lines)}`);
}

/**
 * Установить курс в Linux, если там другая версия.
 * @param {AgentSend} send
 * @param {CourseFile[]} files
 * @returns {Promise<boolean>} true — курс обновлён, false — уже был актуальным
 */
export async function syncCourse(send, files) {
  const version = await courseVersion(files);
  const current = (await send("course-version")).find((l) => l.startsWith("@@VERSION"))?.split("\t")[1] || "";
  if (current === version) return false;

  expectOk(await send("course-begin"), "начать загрузку курса");
  // Весь курс — один tar.gz одной строкой: «course-tar <sha256> <base64>».
  // Внутри Linux распаковка — 3 процесса на всё сразу (запуск процесса в эмуляторе дорогой).
  const archive = await gzip(makeTar(files));
  expectOk(await send(`course-tar ${await sha256hex(archive)} ${toBase64(archive)}`), "загрузить курс");
  expectOk(await send(`course-commit ${version}`), "установить курс");
  return true;
}

/** Путь файла относительно корня курса: "../../modules/01-x/check.sh" → "modules/01-x/check.sh" */
export function coursePath(/** @type {string} */ p) {
  const m = p.replace(/\\/g, "/").match(/(?:^|\/)((?:lab|lib|modules)\/.+)$/);
  if (!m) throw new Error("Файл вне курса: " + p);
  return m[1];
}
