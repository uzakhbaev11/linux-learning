#!/usr/bin/env bash
# Устанавливает курс (команду lab) на настоящий Linux: виртуальную машину Ubuntu или VPS.
# Нужен для модуля 12 (systemd) и итогового проекта — в браузере systemd нет.
#
#   curl -fsSL https://raw.githubusercontent.com/uzakhbaev11/linux-learning/main/lab/install-vm.sh | bash
#
# Повторный запуск обновляет курс до последней версии.
# Для тестов можно взять курс из локальной папки: LAB_SRC=/путь/к/linux-learning bash install-vm.sh
set -euo pipefail

REPO="uzakhbaev11/linux-learning"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ -n "${LAB_SRC:-}" ]; then
  SRC="$LAB_SRC"
else
  echo "▶ Скачиваю курс с GitHub..."
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/main" | tar -xz -C "$TMP"
  SRC="$(echo "$TMP"/*)"
fi

echo "▶ Устанавливаю в /course (нужен sudo)..."
sudo rm -rf /course
sudo mkdir -p /course
sudo cp -r "$SRC/lab" "$SRC/lib" "$SRC/modules" /course/
sudo chmod -R a+rX,go-w /course
sudo ln -sf /course/lab/lab /usr/local/bin/lab

echo "✅ Готово. Команды курса: lab help"
echo "   Например: lab setup 12, затем lab check 12"
