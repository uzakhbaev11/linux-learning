// Автотест: запускает Linux из снимка, решает задания модулей 1–3 и прогоняет проверки.
// Запуск (из site/):  docker run --rm -v "$PWD":/work -w /work node:22-slim node image/test-vm.mjs
import fs from "node:fs";
import path from "node:path";
import url from "node:url";
import zlib from "node:zlib";
import { V86 } from "v86";

const SITE = path.join(path.dirname(url.fileURLToPath(import.meta.url)), "..");
const CONFIG = JSON.parse(fs.readFileSync(path.join(SITE, "image/v86-config.json"), "utf8"));

const emulator = new V86({
  wasm_path: path.join(SITE, "node_modules/v86/build/v86.wasm"),
  bios: { url: path.join(SITE, "public/v86/bios/seabios.bin") },
  vga_bios: { url: path.join(SITE, "public/v86/bios/vgabios.bin") },
  filesystem: {
    baseurl: path.join(SITE, "public/images/rootfs-flat"),
    basefs: path.join(SITE, "public/images/fs.json"),
  },
  initial_state: { url: path.join(SITE, "public/images/state.bin.zst") },
  autostart: true,
  bzimage_initrd_from_filesystem: true,
  ...CONFIG,
});

let out = [];
emulator.add_listener("serial0-output-byte", (b) => out.push(b));
const text = () => Buffer.from(out).toString("utf8");

// Выполнить команду и дождаться маркера конца
let n = 0;
async function run(cmd, timeoutMs = 120000) {
  const marker = `__DONE_${++n}__`;
  out = [];
  emulator.serial_send_bytes(0, new TextEncoder().encode(`${cmd}; echo "${marker.slice(0, 4)}""${marker.slice(4)}"\n`));
  const start = Date.now();
  while (!text().includes(marker + "\r\n") && !text().includes(marker + "\n")) {
    if (Date.now() - start > timeoutMs) throw new Error(`Таймаут: ${cmd}\n${text()}`);
    await new Promise((r) => setTimeout(r, 100));
  }
  return text();
}

emulator.add_listener("emulator-started", async () => {
  const t0 = Date.now();
  try {
    await run("stty -echo cols 200; export PS1=''");
    console.log((await run("hostname; whoami; uname -m; man -w ls; lab list")).trim());

    await run("for n in 1 2 3; do lab setup $n </dev/null; done");
    await run(`cd ~/m01 && whoami > me.txt && uname -a > system.txt && echo penguin > code.txt && (cd /etc && ls > ~/m01/etc-list.txt) && seq 12 > history.txt`);
    await run(`cd ~/m02 && mkdir -p myapp/{src,tests,docs,config} && touch myapp/README.md myapp/src/main.py && cd downloads && mkdir images documents music && mv *.jpg *.png images/ && mv *.pdf *.txt documents/ && mv *.mp3 music/ && rm *.tmp && cd .. && mkdir found && cp "$(find maze -name treasure.txt)" found/ && realpath "$(find maze -size +1M)" > big.txt && cp -r myapp myapp-backup && mv myapp/docs myapp/documentation && rm -r trash`);
    await run(`cd ~/m03 && head -n 10 app.log > first10.txt && tail -n 3 app.log > last3.txt && grep -c ERROR app.log > errors_count.txt && grep -n ERROR app.log > errors.txt && grep user_id=1337 app.log > user1337.txt && grep -v INFO app.log > not_info.txt && sed -i "s/port=8080/port=3000/; s/debug=true/debug=false/" config.ini && echo "I can exit vim" > vim.txt; cd ~`);

    let failed = false;
    for (const m of [1, 2, 3]) {
      const res = await run(`lab check ${m} -q 2>&1 | sed 's/\\x1b\\[[0-9;]*m//g' | grep -E '✘|подсказка|Отлично|Результат'`);
      const lines = res.split(/\r?\n/).filter((l) => /✘|подсказка|Отлично|Результат/.test(l));
      console.log(`Модуль ${m}:\n  ` + lines.join("\n  "));
      if (!lines.some((l) => l.includes("Отлично"))) failed = true;
    }
    console.log(`Время тестов: ${Math.round((Date.now() - t0) / 1000)} с`);
    console.log(failed ? "❌ ЕСТЬ ОШИБКИ" : "✅ ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ");
    process.exit(failed ? 1 : 0);
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
});
