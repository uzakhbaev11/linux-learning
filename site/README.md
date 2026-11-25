# 🌐 Linux Lab — сайт

**Живой сайт: https://uzakhbaev11.github.io/linux-learning/**

Курс Linux прямо в браузере: теория слева, настоящий Linux справа.
Linux (Alpine, 32-бит x86) работает в эмуляторе [v86](https://github.com/copy/v86) на WebAssembly,
поэтому сайту не нужен сервер — подходит GitHub Pages.

## Команды

```bash
cd site
npm install          # один раз: зависимости
npm run image        # собрать Linux для браузера (нужен Docker, ~5 мин) → public/images/
npm run dev          # разработка: http://localhost:5173 (обновляется при изменениях)
npm run build        # сборка сайта → dist/
npm run preview      # посмотреть собранный сайт: http://127.0.0.1:8086
npm run test:vm      # автотест: задания модулей внутри Linux
npm run test:browser # автотест в настоящем Chrome (нужен запущенный preview)
```

**Курс не «запекается» в образ Linux.** Скрипты (`lab/lab`, `lib/`, `modules/`) сайт при запуске
отправляет внутрь Linux через скрытого помощника `image/lab-agent` (второй последовательный порт ttyS1)
одним архивом `tar.gz` с контрольной суммой. Поэтому:
- новый модуль = просто `git push`, Linux пересобирать не нужно;
- сохранения учеников в браузере не сбрасываются при обновлении курса.

Образ Linux пересобирается только при изменении `site/image/*` или версии v86 (см. `image/version.sh`).
Готовые образы лежат в релизах `image-<версия>` — CI берёт их оттуда.

Отладка: открой сайт с `?debug` в адресе — в консоли браузера будут ответы помощника и время загрузки курса.

## Как устроено

```
site/
├── index.html           разметка страницы
├── src/
│   ├── main.ts          интерфейс: маршруты, вкладки, список модулей, разделитель
│   ├── linux.ts         Linux: запуск v86, терминал xterm.js, сохранение
│   ├── content.ts       модули курса (берёт markdown из ../modules)
│   ├── storage.ts       IndexedDB (снимок Linux) и localStorage (настройки)
│   └── style.css        стили (светлая и тёмная тема, телефон)
├── image/               сборка Linux: Dockerfile → формат v86 → снимок состояния
├── public/v86/bios/     BIOS для эмулятора
├── public/images/       собранный Linux (не в git, собирается CI)
├── tests/               браузерный тест (Playwright в Docker)
└── tools/               конвертеры из проекта v86 (BSD-2-Clause)
```

## Этапы

- [x] 0. Прототип: Linux в браузере
- [x] 1–2. Каркас сайта: теория/задания + терминал, навигация
- [x] 3. Кнопка «Проверить» и квиз в интерфейсе
- [x] 4. Сжатие сохранений, автосохранение, прогресс
- [x] 5. GitHub Actions: сборка и деплой на GitHub Pages

Браузерный тест живого сайта через свой Chrome (без Docker):
`SITE_URL=https://uzakhbaev11.github.io/linux-learning/ BROWSER_CHANNEL=chrome node tests/browser.test.mjs`
(нужен `npm i playwright@1.49.1` рядом со скриптом)
