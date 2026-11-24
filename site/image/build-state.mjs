// Загружает Linux в v86 (под Node), ждёт приглашения командной строки
// и сохраняет состояние машины. Сайт стартует из этого состояния за секунды.
// Основано на v86/tools/docker/alpine/build-state.js (BSD-2-Clause).
import fs from "node:fs";
import path from "node:path";
import url from "node:url";
import { V86 } from "v86";

const SITE = path.join(path.dirname(url.fileURLToPath(import.meta.url)), "..");
const OUT = path.join(SITE, "public/images/state.bin");
export const CONFIG = JSON.parse(fs.readFileSync(path.join(SITE, "image/v86-config.json"), "utf8"));

const emulator = new V86({
  wasm_path: path.join(SITE, "node_modules/v86/build/v86.wasm"),
  bios: { url: path.join(SITE, "public/v86/bios/seabios.bin") },
  vga_bios: { url: path.join(SITE, "public/v86/bios/vgabios.bin") },
  filesystem: {
    baseurl: path.join(SITE, "public/images/rootfs-flat"),
    basefs: path.join(SITE, "public/images/fs.json"),
  },
  autostart: true,
  bzimage_initrd_from_filesystem: true,
  ...CONFIG,
});

console.log("Загружаю Linux...");
const started = Date.now();
let text = "";
let booted = false;

const timeout = setTimeout(() => {
  console.error("❌ Linux не загрузился за 10 минут. Последний вывод:\n" + text.slice(-2000) + "\n--- ttyS1:\n" + agentText.slice(-500));
  process.exit(1);
}, 10 * 60 * 1000);

let agentText = "";
emulator.add_listener("serial1-output-byte", (byte) => {
  agentText += String.fromCharCode(byte);
  maybeSave();
});
emulator.add_listener("serial0-output-byte", (byte) => {
  text += String.fromCharCode(byte);
  maybeSave();
});

// Сохраняем, когда готовы и терминал пользователя (ttyS0), и скрытый помощник (ttyS1)
function maybeSave() {
  if (!booted && text.includes("student@") && agentText.includes("@@READY")) {
    booted = true;
    console.log(`Загрузился за ${Math.round((Date.now() - started) / 1000)} с. Сохраняю состояние...`);
    emulator.serial0_send("sync; clear\n");
    setTimeout(async () => {
      const state = await emulator.save_state();
      fs.writeFileSync(OUT, new Uint8Array(state));
      console.log(`Сохранено: ${OUT} (${(state.byteLength / 1e6).toFixed(1)} МБ)`);
      clearTimeout(timeout);
      emulator.destroy();
      process.exit(0);
    }, 5000);
  }
}
