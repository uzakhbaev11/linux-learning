#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m05"
A="$D/app"

title "Проверка модуля 5: Пользователи и права"
[ -d "$A" ] || { fail "~/m05/app не найдена" "сначала выполни: lab setup 5"; summary; }

# последние 3 цифры прав: в Alpine у папок в домашнем каталоге стоит бит setgid (2755),
# он здесь не важен
perm()  { local p; p="$(stat -c %a "$1" 2>/dev/null)"; echo "${p: -3}"; }

section "Задание 1"
check "me.txt — твоя строка из /etc/passwd" "grep по /etc/passwd, строка должна начинаться с твоего имени (^)" \
  '[ "$(cat "$D/me.txt")" = "$(grep "^$(whoami):" /etc/passwd)" ]'

section "Задание 3"
check ".env — права 600" "chmod 600" '[ "$(perm "$A/.env")" = 600 ]'
check "deploy.sh — права 755 и он запускался" "chmod 755 (или +x), затем запусти и сохрани вывод в deploy.out" \
  '[ "$(perm "$A/deploy.sh")" = 755 ] && grep -q "Deploy OK" "$D/deploy.out"'
check "config.yml — права 644" "rw-r--r-- = 644" '[ "$(perm "$A/config.yml")" = 644 ]'
check "logs — права 700" "chmod 700" '[ "$(perm "$A/logs")" = 700 ]'

section "Задание 4"
check "payment.key — владелец root:root" "sudo chown пользователь:группа" \
  '[ "$(stat -c %U:%G "$D/payment.key")" = root:root ]'
check "payment.key — права 600" "chmod 600 (до chown или через sudo)" '[ "$(perm "$D/payment.key")" = 600 ]'

section "Задание 5"
check "Группа devs существует" "sudo groupadd devs" 'getent group devs >/dev/null'
check "student в группе devs" "usermod через sudo, не забудь про -a" \
  'getent group devs | cut -d: -f4 | tr "," "\n" | grep -qx student'
check "Группа папки shared — devs" "chgrp через sudo (в текущей сессии ты ещё не в группе devs)" '[ "$(stat -c %G "$D/shared")" = devs ]'
check "Права shared — 770" "chmod 770" '[ "$(perm "$D/shared")" = 770 ]'

section "Квиз"
ask "Какие права цифрами у rwxr-xr-x?" "r=4, w=2, x=1" '755'
ask "Какие права цифрами нужны для .env и SSH-ключа?" "только владелец читает и пишет" '600'
ask "В каком файле список пользователей системы? (полный путь)" "/etc/..." '/etc/passwd'
ask "Какой флаг usermod ОБЯЗАТЕЛЬНО добавить к -G, чтобы не потерять другие группы?" "append" '-a|a' cs
ask "umask 022. Какие права (цифрами) получит новый файл?" "666 − 022" '644'

summary
