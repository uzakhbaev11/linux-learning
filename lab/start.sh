#!/usr/bin/env bash
# Запускает учебный Linux и открывает в нём терминал.
# Использование: ./lab/start.sh
set -e

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
IMAGE="linux-lab"
CONTAINER="linux-lab"

if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker не запущен. Открой Docker Desktop и попробуй снова."
  exit 1
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "📦 Первый запуск: собираю учебный Linux (займёт 3–7 минут)..."
  docker build -t "$IMAGE" lab
fi

if ! docker container inspect "$CONTAINER" >/dev/null 2>&1; then
  # Контейнера ещё нет — создаём
  docker run -d --name "$CONTAINER" --hostname linux-lab \
    -v "$ROOT":/course:ro "$IMAGE" >/dev/null
elif [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER")" != "true" ]; then
  # Есть, но остановлен — запускаем
  docker start "$CONTAINER" >/dev/null
fi

docker exec -it -u student -w /home/student "$CONTAINER" bash -l
