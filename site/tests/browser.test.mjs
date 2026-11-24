// Браузерный тест прототипа: настоящий Chromium (Playwright) открывает страницу,
// ждёт Linux, вводит команды, сохраняет состояние, перезагружает страницу и проверяет файлы.
// Запуск: site/tests/run-browser-test.sh
import { chromium } from "playwright";

const URL = process.env.SITE_URL || "http://host.docker.internal:8086/";
const log = (...a) => console.log(new Date().toISOString().slice(11, 19), ...a);

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1200, height: 800 } });
page.on("pageerror", (e) => log("❌ JS-ошибка на странице:", e.message));
page.on("console", (m) => m.type() === "error" && log("console.error:", m.text()));

const termText = () => page.locator(".xterm-rows").innerText();
async function waitForText(re, timeout = 180000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const t = await termText();
    if (re.test(t)) return t;
    await page.waitForTimeout(500);
  }
  throw new Error(`Не дождался ${re}. Экран:\n${await termText()}`);
}
async function type(cmd) {
  await page.locator(".xterm").click();
  await page.keyboard.type(cmd, { delay: 15 });
  await page.keyboard.press("Enter");
}

let ok = true;
const check = (name, cond) => { log(cond ? "✔" : "✘", name); if (!cond) ok = false; };

try {
  // 1. Первая загрузка
  let t0 = Date.now();
  await page.goto(URL);
  await waitForText(/student@linux-lab/);
  log(`Linux готов за ${((Date.now() - t0) / 1000).toFixed(1)} с`);
  check("Статус «Linux запущен»", /запущен/.test(await page.locator("#vm-status").innerText()));

  // 2. Команды, кириллица, размер терминала
  await type("echo 'Привет, Linux!' > hello.txt && cat hello.txt && stty size && lab list");
  const out = await waitForText(/03-text-and-editors/);
  check("Кириллица в файле и в выводе", out.includes("Привет, Linux!"));
  check("stty знает размер окна", /\n\d+ \d+\n/.test(out) && !/\n0 0\n/.test(out));
  check("Команда lab работает", out.includes("01-terminal-basics"));

  // 3. Сохранение → перезагрузка → файл на месте
  await page.click("#save-btn");
  await page.waitForFunction(() => /Сохранено/.test(document.querySelector("#vm-status").textContent), null, { timeout: 60000 });
  log("Статус:", await page.locator("#vm-status").innerText());
  t0 = Date.now();
  await page.reload();
  await page.waitForFunction(() => /восстановлен/.test(document.querySelector("#vm-status").textContent), null, { timeout: 120000 });
  log(`Восстановлено за ${((Date.now() - t0) / 1000).toFixed(1)} с`);
  await type("clear; cat ~/hello.txt; echo END-OF-TEST");
  const out2 = await waitForText(/^END-OF-TEST/m);
  check("Файл пережил перезагрузку страницы", out2.includes("Привет, Linux!"));
  const savedMB = await page.evaluate(() => new Promise((resolve) => {
    const r = indexedDB.open("linux-lab");
    r.onsuccess = () => {
      const g = r.result.transaction("state").objectStore("state").get("vm");
      g.onsuccess = () => resolve(g.result.data.byteLength / 1e6);
    };
  }));
  log(`Размер сохранения: ${savedMB.toFixed(1)} МБ`);
  check("Сохранение сжато (меньше 25 МБ)", savedMB < 25);

  // 3б. Проверка заданий и квиз (модуль 1)
  await page.goto(URL.replace(/\/$/, "") + "/#/01/tasks");
  await page.click("#check-btn");
  await page.waitForSelector("#check-results .score", { timeout: 60000 });
  check("Проверка без выполненных заданий показывает ✘ и подсказку",
    (await page.locator("#check-results").innerText()).includes("подсказка"));

  await type("clear; lab setup 1 && cd ~/m01 && whoami > me.txt && uname -a > system.txt && echo penguin > code.txt && (cd /etc && ls > ~/m01/etc-list.txt) && history > history.txt; seq 12 >> history.txt; cd; echo TASKS-DONE");
  await waitForText(/^TASKS-DONE/m, 60000);
  await page.click("#run-check");
  await page.waitForFunction(() => /всё верно/.test(document.querySelector("#check-results")?.textContent || ""), null, { timeout: 60000 });
  check("После выполнения заданий все пункты ✔", (await page.locator("#check-results .fail").count()) === 0);

  const answers = ["pwd", "-a", ".", "-S", "cd -", "ctrl+c"];
  const inputs = page.locator("#quiz .answer");
  check("Квиз из check.sh показан в интерфейсе (6 вопросов)", (await inputs.count()) === answers.length);
  await inputs.nth(3).fill("-s"); // сначала неверно: регистр важен
  for (const [i, a] of answers.entries()) if (i !== 3) await inputs.nth(i).fill(a);
  await page.click("#quiz-btn");
  check("Квиз: «-s» вместо «-S» не засчитан", (await page.locator("#v3").innerText()).includes("✘"));
  await inputs.nth(3).fill("-S");
  await page.click("#quiz-btn");
  check("Квиз пройден → модуль отмечен пройденным",
    (await page.locator("#quiz-result").innerText()).includes("Модуль 1 пройден"));
  await page.screenshot({ path: "build/screenshot-check.png", fullPage: false });
  await page.locator("#checker").screenshot({ path: "build/screenshot-checker.png" });
  await page.goto(URL.replace(/\/$/, "") + "/#/01/theory");

  // 4. Контент и навигация
  check("Теория модуля 1 отрисована", (await page.locator("#content h1").innerText()).includes("Модуль 1"));
  await page.screenshot({ path: "build/screenshot.png" });
  await page.click("#next-btn");
  await page.waitForFunction(() => location.hash === "#/01/tasks");
  check("Кнопка «К заданиям» открывает задания", (await page.locator("#content").innerText()).includes("Задание 1"));
  await page.click("#menu-btn");
  await page.click('#module-list a[href="#/02/theory"]');
  check("Переход к модулю 2 из списка", (await page.locator("#module-title").innerText()).includes("Файловая система"));
  check("Модуль 4 помечен «скоро»", (await page.locator("#module-list").innerText()).includes("скоро"));
  check("Прогресс: «Пройдено 1 из 12»", (await page.locator("#progress-text").innerText()).includes("Пройдено 1 из 12"));

  // 5. Телефон
  await page.setViewportSize({ width: 390, height: 800 });
  await page.waitForTimeout(1500);
  const noHScroll = await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth);
  check("На телефоне нет горизонтальной прокрутки", noHScroll);
  await page.screenshot({ path: "build/screenshot-mobile.png" });
  log("Скриншоты: site/build/screenshot*.png");
} catch (e) {
  ok = false;
  log("❌", e.message);
  await page.screenshot({ path: "build/screenshot-error.png" }).catch(() => {});
}
await browser.close();
log(ok ? "✅ БРАУЗЕРНЫЙ ТЕСТ ПРОЙДЕН" : "❌ БРАУЗЕРНЫЙ ТЕСТ НЕ ПРОЙДЕН");
process.exit(ok ? 0 : 1);
