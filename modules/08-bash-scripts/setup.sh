#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m08"
prepare_dir "$D"

# Лог приложения: INFO 121, WARN 24, ERROR 9
for i in $(seq 1 154); do
  if (( i % 17 == 0 )); then lvl=ERROR; msg="Payment failed"
  elif (( i % 6 == 0 )); then lvl=WARN; msg="Slow query $((700 + i))ms"
  else lvl=INFO; msg="GET /api/orders 200"
  fi
  printf '2026-11-27 12:%02d:%02d [%s] %s\n' $((i / 60)) $((i % 60)) "$lvl" "$msg"
done > "$D/app.log"

# Что должно быть на сервере перед деплоем
cat > "$D/checklist.txt" <<'TXT'
/etc/passwd
/etc/hosts
/var/log
/etc/myapp/config.yml
/home/student
/srv/myapp/.env
TXT

echo "✅ Модуль 8 подготовлен: $D"
echo "Задания: lab tasks 8"
