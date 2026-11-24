import { marked } from "marked";
import "./style.css";
import { modules, available, type Module } from "./content";
import { Linux, type Status, type CheckResult } from "./linux";
import { prefs, progress } from "./storage";

type Tab = "theory" | "tasks";

const $ = <T extends HTMLElement>(sel: string) => document.querySelector(sel) as T;
const esc = (s: string) => s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
const content = $("#content");
const statusEl = $("#vm-status");

// ---------- Linux ----------
const linux = new Linux($("#terminal"), (s: Status) => {
  statusEl.textContent = s.text;
  statusEl.dataset.kind = s.kind;
});
linux.start();

$("#save-btn").onclick = () => linux.save();
$("#reset-btn").onclick = () => {
  if (confirm("Вернуть Linux в чистое состояние? Все твои файлы внутри Linux пропадут.\nПрогресс по модулям сохранится.")) linux.reset();
};

// ---------- Маршруты: #/01/theory ----------
function parseRoute(): { num: string; tab: Tab } {
  const [, num, tab] = location.hash.match(/^#\/(\d{2})\/(theory|tasks)$/) || [];
  if (num && modules.some((m) => m.num === num && available(m))) return { num, tab: tab as Tab };
  const last = prefs.get("route");
  if (last && /^#\/\d{2}\/(theory|tasks)$/.test(last)) {
    history.replaceState(null, "", last);
    return parseRoute();
  }
  return { num: "01", tab: "theory" };
}

const go = (num: string, tab: Tab) => (location.hash = `#/${num}/${tab}`);

function render() {
  const { num, tab } = parseRoute();
  const mod = modules.find((m) => m.num === num)!;
  prefs.set("route", `#/${num}/${tab}`);

  $("#module-title").textContent = `Модуль ${Number(num)}. ${mod.title}`;
  document.title = `${mod.title} — Linux Lab`;
  document.querySelectorAll<HTMLElement>(".tab").forEach((b) => {
    b.setAttribute("aria-selected", String(b.dataset.tab === tab));
  });

  if (tab === "theory") {
    content.innerHTML = renderMarkdown(mod.theory ?? "");
  } else {
    // Раздел «✅ Проверка» из tasks.md (про lab check в терминале) заменяем кнопкой проверки
    const tasks = (mod.tasks ?? "").split(/^## ✅ Проверка/m)[0];
    content.innerHTML = renderMarkdown(tasks) + checkerHtml(num);
    bindChecker(num);
  }
  content.scrollTop = 0;

  // Кнопки внизу: теория → задания → теория следующего модуля
  const ready = modules.filter(available);
  const idx = ready.findIndex((m) => m.num === num);
  const prev: [string, Tab] | null = tab === "tasks" ? [num, "theory"] : idx > 0 ? [ready[idx - 1].num, "tasks"] : null;
  const next: [string, Tab] | null = tab === "theory" ? [num, "tasks"] : idx < ready.length - 1 ? [ready[idx + 1].num, "theory"] : null;
  setNav($("#prev-btn"), prev, "← Назад");
  setNav($("#next-btn"), next, tab === "theory" ? "К заданиям →" : `Модуль ${idx + 2} →`);
  const checkBtn = $<HTMLButtonElement>("#check-btn");
  checkBtn.hidden = tab !== "tasks";
  checkBtn.onclick = () => {
    $("#checker")?.scrollIntoView({ behavior: "smooth" });
    runCheck(num);
  };

  renderModuleList(num);
}

function setNav(btn: HTMLButtonElement, target: [string, Tab] | null, label: string) {
  btn.hidden = !target;
  btn.textContent = label;
  btn.onclick = () => target && go(...target);
}

function renderMarkdown(md: string): string {
  // Строки-подсказки для Docker-версии («открой задания: lab tasks 1») на сайте не нужны
  md = md.replace(/^👉.*lab (theory|tasks).*$/gm, "");
  return marked.parse(md, { async: false }) as string;
}

// ---------- Проверка заданий и квиз ----------
function checkerHtml(num: string): string {
  const done = progress.done(num);
  return `
    <section id="checker" class="checker">
      <h2>✅ Проверка</h2>
      <p class="muted">Выполни задания в терминале справа и нажми кнопку. Проверка смотрит на файлы внутри твоего Linux.</p>
      ${done ? `<p class="done-banner">🎉 Модуль уже пройден. Можно проверить ещё раз.</p>` : ""}
      <button id="run-check" class="btn primary">Проверить задания</button>
      <div id="check-results"></div>
      <div id="quiz"></div>
    </section>`;
}

function bindChecker(num: string) {
  $("#run-check").onclick = () => runCheck(num);
}

let checking = false;
async function runCheck(num: string) {
  if (checking) return;
  const out = $("#check-results");
  const btn = $<HTMLButtonElement>("#run-check");
  if (!linux.isReady) {
    out.innerHTML = `<p class="muted">Linux ещё загружается, подожди пару секунд…</p>`;
    return;
  }
  checking = true;
  btn.disabled = true;
  btn.textContent = "Проверяю…";
  try {
    const res = await linux.check(num);
    out.innerHTML = resultsHtml(res);
    const allOk = res.total > 0 && res.passed === res.total;
    progress.set(num, { tasks: allOk });
    if (res.quiz.length) renderQuiz(num, res);
    renderModuleList(num);
  } catch (e) {
    out.innerHTML = `<p class="fail">Не получилось проверить: ${esc((e as Error).message)}</p>`;
  } finally {
    checking = false;
    btn.disabled = false;
    btn.textContent = "Проверить ещё раз";
  }
}

function resultsHtml(res: CheckResult): string {
  if (res.total === 0) {
    return `<p class="fail">Проверка не вернула результатов. Попробуй ещё раз, а если не поможет — нажми «Сброс».</p>`;
  }
  const allOk = res.passed === res.total;
  const sections = res.sections
    .map(
      (s) => `
      <h3>${esc(s.title)}</h3>
      <ul class="results">${s.items
        .map(
          (i) => `<li class="${i.ok ? "ok" : "fail"}">
            <span class="mark">${i.ok ? "✔" : "✘"}</span>
            <span>${esc(i.text)}${!i.ok && i.hint ? `<span class="hint">подсказка: ${esc(i.hint)}</span>` : ""}</span>
          </li>`,
        )
        .join("")}</ul>`,
    )
    .join("");
  const head = allOk
    ? `<p class="score ok">Задания: ${res.passed}/${res.total} — всё верно! Теперь квиз ниже 👇</p>`
    : `<p class="score">Задания: ${res.passed}/${res.total}. Исправь отмеченные пункты и проверь ещё раз.</p>`;
  return head + sections;
}

function renderQuiz(num: string, res: CheckResult) {
  const box = $("#quiz");
  if (box.dataset.ready === num) return; // уже нарисован — не стираем ответы
  box.dataset.ready = num;
  box.innerHTML = `
    <h3>🧠 Квиз</h3>
    <p class="muted">Отвечай текстом. Сочетания клавиш тоже пиши текстом, например <code>ctrl+x</code>.</p>
    <ol class="quiz">${res.quiz
      .map(
        (q, i) => `<li>
          <label for="q${i}">${esc(q.question)}</label>
          <input id="q${i}" class="answer" autocomplete="off" autocapitalize="off" spellcheck="false">
          <span class="verdict" id="v${i}"></span>
        </li>`,
      )
      .join("")}</ol>
    <button id="quiz-btn" class="btn primary">Проверить ответы</button>
    <div id="quiz-result"></div>`;

  // Enter в поле → к следующему вопросу (на последнем — проверить)
  box.querySelectorAll<HTMLInputElement>(".answer").forEach((input, i, all) => {
    input.onkeydown = (e) => {
      if (e.key !== "Enter") return;
      if (all[i + 1]) all[i + 1].focus();
      else $("#quiz-btn").click();
    };
  });

  $("#quiz-btn").onclick = () => {
    let correct = 0;
    res.quiz.forEach((q, i) => {
      const value = ($(`#q${i}`) as HTMLInputElement).value.trim();
      const ok = q.pattern.test(value);
      if (ok) correct++;
      const v = $(`#v${i}`);
      v.className = "verdict " + (ok ? "ok" : "fail");
      v.textContent = ok ? "✔ верно" : value ? `✘ подсказка: ${q.hint}` : "✘ нет ответа";
    });
    const allOk = correct === res.quiz.length;
    progress.set(num, { quiz: allOk });
    const done = progress.done(num);
    $("#quiz-result").innerHTML = done
      ? `<p class="done-banner">🎉 Модуль ${Number(num)} пройден! Задания и квиз — всё верно.</p>`
      : allOk
        ? `<p class="score ok">Квиз: всё верно! Осталось добить задания выше.</p>`
        : `<p class="score">Квиз: ${correct}/${res.quiz.length}. Подумай над отмеченными вопросами.</p>`;
    renderModuleList(num);
  };
}

// ---------- Список модулей ----------
const drawer = $("#drawer");
const backdrop = $("#backdrop");
const toggleDrawer = (open: boolean) => {
  drawer.hidden = !open;
  backdrop.hidden = !open;
};
$("#menu-btn").onclick = () => toggleDrawer(drawer.hidden);
backdrop.onclick = () => toggleDrawer(false);
document.addEventListener("keydown", (e) => e.key === "Escape" && toggleDrawer(false));

function renderModuleList(current: string) {
  let lastPart = "";
  const doneCount = modules.filter((m) => progress.done(m.num)).length;
  $("#progress-text").textContent = `Пройдено ${doneCount} из ${modules.length}`;
  $<HTMLElement>("#progress-fill").style.width = `${(doneCount / modules.length) * 100}%`;
  $("#module-list").innerHTML = modules
    .map((m: Module) => {
      const head = m.part !== lastPart ? `<li class="part">${(lastPart = m.part)}</li>` : "";
      const cls = [available(m) ? "" : "soon", m.num === current ? "current" : ""].join(" ");
      const badge = !available(m)
        ? `<span class="badge">скоро</span>`
        : progress.done(m.num)
          ? `<span class="badge done">✓</span>`
          : "";
      const link = available(m) ? `href="#/${m.num}/theory"` : "";
      return `${head}<li class="${cls}"><a ${link}><span class="num">${m.num}</span>${m.title}${badge}</a></li>`;
    })
    .join("");
}
$("#module-list").addEventListener("click", (e) => {
  if ((e.target as HTMLElement).closest("a[href]")) toggleDrawer(false);
});

// ---------- Вкладки ----------
document.querySelectorAll<HTMLElement>(".tab").forEach((b) => {
  b.onclick = () => go(parseRoute().num, b.dataset.tab as Tab);
});

// ---------- Разделитель панелей ----------
const layout = $(".layout");
const savedWidth = prefs.get("split");
if (savedWidth) layout.style.setProperty("--lesson-width", savedWidth);
$("#splitter").addEventListener("pointerdown", (e) => {
  const splitter = e.currentTarget as HTMLElement;
  splitter.setPointerCapture(e.pointerId);
  document.body.classList.add("resizing");
  const move = (ev: PointerEvent) => {
    const pct = Math.min(70, Math.max(25, (ev.clientX / window.innerWidth) * 100));
    layout.style.setProperty("--lesson-width", `${pct}%`);
  };
  const up = () => {
    splitter.removeEventListener("pointermove", move);
    document.body.classList.remove("resizing");
    prefs.set("split", layout.style.getPropertyValue("--lesson-width"));
    linux.focus();
  };
  splitter.addEventListener("pointermove", move);
  splitter.addEventListener("pointerup", up, { once: true });
});

window.addEventListener("hashchange", render);
render();
