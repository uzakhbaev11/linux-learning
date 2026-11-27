#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m06"
REAL_PID_FILE="$HOME/.cache/lab/m06-worker.pid"

title "Проверка модуля 6: Процессы и сигналы"
[ -f "$D/stuck-worker.sh" ] || { fail "~/m06 не подготовлена" "сначала выполни: lab setup 6"; summary; }

num() { tr -d '[:space:]' < "$1"; }

section "Задание 2"
check "worker.pid — PID воркера" "ps aux | grep или pgrep -f, запиши только число (если воркер уже остановлен: lab setup 6)" \
  '[ -s "$D/worker.pid" ] && [ "$(num "$D/worker.pid")" = "$(num "$REAL_PID_FILE")" ]'

section "Задание 3"
check "Воркер остановлен" "kill PID" '! pgrep -f "m06/stuck-worker.sh"'
check "Воркер остановлен вежливо (SIGTERM, не -9)" "в worker.log должна быть запись о SIGTERM. Начать заново: lab setup 6" \
  'grep -q "SIGTERM" "$D/worker.log"'

section "Задание 4"
check "hung-job.sh остановлен" "он игнорирует SIGTERM — нужен сигнал 9" '! pgrep -f "m06/hung-job.sh"'

section "Задание 5"
check "port_owner.txt — программа на порту 5000" "ss -tlnp, смотри users:((\"...\"" \
  '[ "$(num "$D/port_owner.txt")" = httpd ]'
check "port_pid.txt — её PID" "ss -tlnp показывает pid=... (если httpd остановлен: lab setup 6)" \
  'P="$(pgrep -f "httpd -p 5000" | head -n 1)" && [ -n "$P" ] && [ "$(num "$D/port_pid.txt")" = "$P" ]'

section "Задание 7"
check "nohup.out — отчёт посчитан в фоне" "nohup + & из папки ~/m06, затем подожди ~10 секунд" \
  'grep -q "Отчёт готов" "$D/nohup.out"'

section "Квиз"
ask "Какой сигнал (номер) посылает kill по умолчанию?" "SIGTERM" '15|sigterm|term'
ask "Какой сигнал (номер) нельзя перехватить или проигнорировать?" "SIGKILL" '9|sigkill|kill'
ask "Какие клавиши ставят текущую программу на паузу? (напиши текстом)" "Ctrl + буква" 'ctrl\+z|ctrl-z|ctrl z|\^z'
ask "Какой командой вернуть фоновую задачу на передний план?" "foreground" 'fg|fg %?[0-9]+'
ask "Какой командой с флагами посмотреть, какие программы слушают порты?" "ss -..." '(sudo )?ss -[tlnpu]{3,5}|(sudo )?netstat -[tlnpu]{3,5}'

summary
