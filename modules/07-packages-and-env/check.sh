#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m07"

title "Проверка модуля 7: Пакеты и окружение"
[ -d "$D" ] || { fail "Папка ~/m07 не найдена" "сначала выполни: lab setup 7"; summary; }

# Новый интерактивный bash читает ~/.bashrc — так проверяем, что настройки сохранятся навсегда.
# setsid: отдельная сессия, чтобы этот bash не забрал себе терминал
SHELL_OUT="$(cd /tmp && setsid -w bash -ic 'command -v hello; type -t ll; alias ll; hello' </dev/null 2>/dev/null)"

section "Задание 1"
check "owner.txt — какой пакет владеет /usr/bin/htop" "apk info --who-owns /usr/bin/htop > ~/m07/owner.txt" \
  'grep -Eq "owned by htop|^htop:" "$D/owner.txt"'

section "Задание 2"
check "jq установлен" "sudo apk update && sudo apk add jq" 'command -v jq'
check "version.txt — 2.4.1" "jq -r .version config.json" \
  '[ "$(tr -d "[:space:]" < "$D/version.txt")" = "2.4.1" ]'
check "db_port.txt — 5432" "вложенное поле: .db.port" \
  '[ "$(tr -d "[:space:]" < "$D/db_port.txt")" = "5432" ]'

section "Задание 3"
check "~/bin/hello — исполняемый скрипт" "chmod +x ~/bin/hello" '[ -x "$HOME/bin/hello" ]'
check "~/bin добавлена в PATH в ~/.bashrc" "export PATH=\"\$HOME/bin:\$PATH\" в конец ~/.bashrc" \
  'grep "PATH" "$HOME/.bashrc" | grep -q "bin"'
check "В новом терминале команда hello работает" "строка с PATH в ~/.bashrc, а не только в текущем терминале" \
  'grep -qx "$HOME/bin/hello" <<< "$SHELL_OUT" && grep -qx "Hello from bin" <<< "$SHELL_OUT"'

section "Задание 4"
check "alias ll='ls -la' в ~/.bashrc" "alias ll='ls -la' (без пробелов вокруг =)" \
  'grep -qx "alias" <<< "$SHELL_OUT" && grep -Eq "ll=.ls -la.$" <<< "$SHELL_OUT"'

section "Задание 5"
E="$D/.env"
check ".env с APP_PORT=3000 и DB_PASSWORD" "nano ~/m07/.env" \
  'grep -qx "APP_PORT=3000" "$E" && grep -Eq "^DB_PASSWORD=.+" "$E"'
check "Права .env — 600 (только владелец)" "chmod 600 ~/m07/.env" \
  '[ "$(stat -c %a "$E")" = "600" ]'
check "С переменными из .env приложение запускается" "set -a; source .env; set +a" \
  '(cd "$D" && set -a && source .env && set +a && ./start.sh) | grep -q "порту 3000"'

section "Квиз"
ask "Какой командой обновить СПИСОК пакетов в Ubuntu? (с sudo)" "apt + ..." 'sudo apt update|sudo apt-get update'
ask "Переменная задана как PORT=3000 без export. Увидит ли её запущенный скрипт? (да/нет)" "дочерние программы видят только экспортированные" 'нет|no'
ask "В каком файле прописывают настройки bash, чтобы они были всегда?" "файл в домашней папке" '~/\.bashrc|\.bashrc|/home/student/\.bashrc|\$HOME/\.bashrc'
ask "Какой командой узнать, где лежит программа htop?" "command -v или which" 'command -v htop|which htop|type htop|type -p htop|whereis htop'
ask "Какие права (числом) ставят на файл .env с секретами?" "только владелец: чтение и запись" '600|0600'

summary
