#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m06"
prepare_dir "$D"

# Остановить процессы от прошлого запуска модуля
pkill -f "m06/stuck-worker.sh" 2>/dev/null || true
pkill -9 -f "m06/hung-job.sh" 2>/dev/null || true
pkill -f "httpd -p 5000" 2>/dev/null || true
sleep 1

# «Воркер очереди»: завис и грузит процессор, но умеет корректно завершаться по SIGTERM
cat > "$D/stuck-worker.sh" <<'EOF'
#!/usr/bin/env bash
LOG="$HOME/m06/worker.log"
trap 'echo "$(date +%T) получен SIGTERM: сохраняю задачи и корректно выхожу" >> "$LOG"; exit 0' TERM
echo "$(date +%T) воркер запущен (PID $$)" >> "$LOG"
while true; do
  i=0; while [ $i -lt 3000 ]; do i=$((i+1)); done
  sleep 0.3
done
EOF

# «Зависшая задача»: игнорирует вежливые сигналы
cat > "$D/hung-job.sh" <<'EOF'
#!/usr/bin/env bash
trap '' TERM INT HUP
while true; do sleep 1; done
EOF

# Отчёт, который долго считается
cat > "$D/report.sh" <<'EOF'
#!/usr/bin/env bash
echo "Считаю отчёт, это займёт несколько секунд..."
sleep 8
echo "Отчёт готов: 42 заказа за сутки"
EOF

# «Бэкенд» на порту 5000 (учебный веб-сервер httpd)
mkdir -p "$D/www"
echo "shop backend v1" > "$D/www/index.html"

# Запуск фоновых процессов
mkdir -p "$HOME/.cache/lab"
nohup bash "$D/stuck-worker.sh" >/dev/null 2>&1 &
echo $! > "$HOME/.cache/lab/m06-worker.pid"
nohup bash "$D/hung-job.sh" >/dev/null 2>&1 &
httpd -p 5000 -h "$D/www"

echo "✅ Модуль 6 подготовлен: $D"
echo "Запущены: воркер, зависшая задача и бэкенд на порту 5000"
echo "Задания: lab tasks 6"
