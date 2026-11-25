#!/usr/bin/env bash
# Собирает образ Linux для браузера.
# Результат: site/public/images/{fs.json, rootfs-flat/, state.bin.zst}
# Нужен только Docker (Node и Python запускаются в контейнерах).
set -euo pipefail

cd "$(dirname "$0")/../.."          # корень linux-learning
ROOT="$(pwd)"
OUT="site/public/images"
IMAGE="linux-lab-v86"

mkdir -p "$OUT"

echo "▶ 1/4 Собираю Alpine (i386)..."
docker build --platform linux/386 -f site/image/Dockerfile -t "$IMAGE" .

echo "▶ 2/4 Экспортирую файловую систему..."
docker rm -f "$IMAGE-export" >/dev/null 2>&1 || true
docker create --platform linux/386 --name "$IMAGE-export" "$IMAGE" >/dev/null
docker export "$IMAGE-export" -o "$OUT/rootfs.tar"
docker rm "$IMAGE-export" >/dev/null

echo "▶ 3/4 Конвертирую в формат v86..."
rm -rf "$OUT/rootfs-flat" "$OUT/fs.json"
mkdir -p "$OUT/rootfs-flat"
docker run --rm -v "$ROOT/site":/work -w /work python:3.12-slim bash -c '
  set -e
  pip install -q --root-user-action=ignore zstandard
  tar -f public/images/rootfs.tar --delete .dockerenv 2>/dev/null || true
  python3 tools/fs2json.py --zstd --out public/images/fs.json public/images/rootfs.tar
  python3 tools/copy-to-sha256.py --zstd public/images/rootfs.tar public/images/rootfs-flat
'
rm -f "$OUT/rootfs.tar"

echo "▶ 4/4 Загружаю Linux и сохраняю готовое состояние (быстрый старт)..."
docker run --rm -v "$ROOT/site":/work -w /work node:22-slim bash -c '
  set -e
  apt-get update -qq && apt-get install -y -qq zstd >/dev/null
  node image/build-state.mjs
  zstd -q -f -19 --rm public/images/state.bin
'

# Версия образа (хеш входных файлов): сайт сравнивает её с версией сохранения в браузере
printf '{ "version": "%s" }\n' "$(bash site/image/version.sh)" > "$OUT/version.json"

echo "✅ Готово: $OUT"
du -sh "$OUT"/*
