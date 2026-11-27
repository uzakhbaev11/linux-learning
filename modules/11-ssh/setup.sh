#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m11"
prepare_dir "$D"

# Файл релиза, который нужно доставить на «сервер»
cat > "$D/release.txt" <<'TXT'
shop-api release 2.0.0
- новая корзина
- исправлен баг с оплатой
TXT

echo "✅ Модуль 11 подготовлен: $D"
echo "«Сервер» для заданий: пользователь deploy на этом же компьютере (ssh deploy@localhost, пароль: deploy)."
echo "Ключи (~/.ssh) и настройки сервера lab setup не сбрасывает: это твой настоящий SSH."
echo "Задания: lab tasks 11"
