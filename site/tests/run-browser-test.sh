#!/usr/bin/env bash
# Запускает браузерный тест в Docker (Playwright + Chromium).
# Перед запуском сайт должен отдаваться на порту 8086:
#   cd site && python3 -m http.server 8086
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
docker run --rm --ipc=host -v "$PWD":/work -w /work \
  mcr.microsoft.com/playwright:v1.49.1-noble \
  bash -c 'cd /tmp && npm init -y >/dev/null && npm i -s playwright@1.49.1 >/dev/null && cp /work/tests/browser.test.mjs . && cd /work && NODE_PATH=/tmp/node_modules node /tmp/browser.test.mjs'
