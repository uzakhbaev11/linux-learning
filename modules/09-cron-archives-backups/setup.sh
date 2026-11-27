#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m09"
prepare_dir "$D"

# Проект, который будем бэкапить
P="$D/myapp"
mkdir -p "$P"/{src,config,logs,node_modules/express,node_modules/lodash}
printf 'from flask import Flask\napp = Flask(__name__)\n' > "$P/src/app.py"
printf 'def test_ok():\n    assert True\n' > "$P/src/test_app.py"
printf '[db]\nhost=127.0.0.1\nname=shop\n' > "$P/config/settings.ini"
for m in express lodash; do
  for i in $(seq 1 30); do echo "module.exports = '$m-$i';" > "$P/node_modules/$m/file$i.js"; done
done
echo "2026-11-27 10:00:00 [INFO] started" > "$P/logs/app.log"

# Старый большой лог для gzip
for i in $(seq 1 2000); do
  if (( i % 40 == 0 )); then echo "2026-11-01 line $i [ERROR] disk is slow"; else echo "2026-11-01 line $i [INFO] ok"; fi
done > "$D/old.log"

echo "✅ Модуль 9 подготовлен: $D"
echo "Задания: lab tasks 9"
