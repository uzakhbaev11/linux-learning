#!/usr/bin/env bash
# Сбрасывает учебный Linux в чистое состояние.
#   ./lab/reset.sh            — удалить контейнер (все твои файлы внутри Linux пропадут)
#   ./lab/reset.sh --rebuild  — ещё и пересобрать образ (если менялся Dockerfile)
set -e
cd "$(dirname "$0")/.."

read -r -p "⚠️  Всё, что ты создал внутри учебного Linux, будет удалено. Продолжить? [y/N] " ans
[[ "$ans" =~ ^[yYдД]$ ]] || { echo "Отменено."; exit 0; }

docker rm -f linux-lab >/dev/null 2>&1 || true
if [ "${1:-}" = "--rebuild" ]; then
  docker rmi linux-lab >/dev/null 2>&1 || true
  docker build -t linux-lab lab
fi
echo "✅ Готово. Запусти ./lab/start.sh"
