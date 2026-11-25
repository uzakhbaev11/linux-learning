#!/usr/bin/env bash
# Печатает версию образа Linux — хеш всех файлов, из которых он собирается.
# Пока эти файлы не меняются, версия та же: CI берёт готовый образ из релиза,
# а сохранения учеников в браузере остаются совместимыми.
# Курс (lab, lib, modules) сюда НЕ входит — он доставляется на лету.
set -euo pipefail
cd "$(dirname "$0")/.."
V86_VERSION="$(node -p 'require("./package-lock.json").packages["node_modules/v86"].version' 2>/dev/null || grep -A1 '"node_modules/v86"' package-lock.json | grep version)"
{
  cat image/Dockerfile image/bashrc image/lab-agent image/v86-config.json image/build-state.mjs 
  echo "v86=$V86_VERSION"
} | { shasum -a 256 2>/dev/null || sha256sum; } | cut -c1-16
