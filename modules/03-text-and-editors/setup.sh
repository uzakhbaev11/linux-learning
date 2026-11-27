#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m03"
prepare_dir "$D"

# Лог приложения (300 строк)
users=(1001 1337 2048 1337 4096)
for i in $(seq 1 300); do
  ts="$(printf '2026-11-23 10:%02d:%02d' $((i / 60)) $((i % 60)))"
  u="${users[$((i % 5))]}"
  if (( i % 17 == 0 )); then
    lvl=ERROR
    if (( i % 2 == 0 )); then msg="Payment failed for user_id=$u"; else msg="Database connection timeout"; fi
  elif (( i % 5 == 0 )); then
    lvl=WARN;  msg="Slow query: $((800 + i))ms user_id=$u"
  else
    lvl=INFO;  msg="GET /api/products 200 $((i % 50 + 5))ms user_id=$u"
  fi
  printf '%s [%s] %s\n' "$ts" "$lvl" "$msg"
done > "$D/app.log"

cat > "$D/config.ini" <<'EOF'
[server]
host=127.0.0.1
port=8080
debug=true

[database]
name=shop
user=admin
EOF

cat > "$D/generator.sh" <<'EOF'
#!/usr/bin/env bash
LOG="$HOME/m03/live.log"
: > "$LOG"
echo "Генератор запущен: 40 секунд пишет строки в $LOG"
for i in $(seq 1 40); do
  if [ "$i" -eq 25 ]; then
    echo "$(date +%T) [INFO] SECRET=orbita" >> "$LOG"
  else
    echo "$(date +%T) [INFO] heartbeat #$i ok" >> "$LOG"
  fi
  sleep 1
done
echo "Генератор закончил (нажми Enter, если не видно приглашения)."
EOF

echo "✅ Модуль 3 подготовлен: $D"
echo "Задания: lab tasks 3"
