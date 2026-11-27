#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m11"
K="$HOME/.ssh/id_ed25519"

title "Проверка модуля 11: SSH"
[ -d "$D" ] || { fail "Папка ~/m11 не найдена" "сначала выполни: lab setup 11"; summary; }

# Подключения к «серверу» медленные (шифрование), поэтому делаем их заранее и по одному разу
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new)
KEY_LOGIN=0; ssh "${SSH_OPTS[@]}" deploy@localhost true 2>/dev/null && KEY_LOGIN=1
REMOTE_RELEASE="$(ssh "${SSH_OPTS[@]}" server 'cat ~/release.txt' 2>/dev/null)" && ALIAS_LOGIN=1 || ALIAS_LOGIN=0
NOPASS="$(ssh "${SSH_OPTS[@]}" -o PubkeyAuthentication=no deploy@localhost true 2>&1)"

section "Задание 1: ключ"
check "Ключ ~/.ssh/id_ed25519 создан (ed25519)" "ssh-keygen -t ed25519" \
  '[ -f "$K" ] && [ -f "$K.pub" ] && grep -q "^ssh-ed25519 " "$K.pub"'
check "Права: ~/.ssh — 700, приватный ключ — 600" "chmod 700 ~/.ssh; chmod 600 ~/.ssh/id_ed25519" \
  '[[ "$(stat -c %a "$HOME/.ssh")" =~ 700$ ]] && [[ "$(stat -c %a "$K")" =~ [46]00$ ]]'

section "Задание 2: вход по ключу"
check "Вход deploy@localhost по ключу, без пароля" "ssh-copy-id deploy@localhost" '[ "$KEY_LOGIN" = 1 ]'

section "Задание 3: ~/.ssh/config"
check "Host server → HostName localhost, User deploy" "в ~/.ssh/config: Host server / HostName localhost / User deploy" \
  'ssh -G server 2>/dev/null | grep -qx "hostname localhost" && ssh -G server 2>/dev/null | grep -qx "user deploy"'
check "Команда ssh server работает" "проверь: ssh server" '[ "$ALIAS_LOGIN" = 1 ] || [ -n "$REMOTE_RELEASE" ]'

section "Задание 4: команды на сервере"
check "remote_user.txt — результат whoami на сервере" "ssh server whoami > ~/m11/remote_user.txt" \
  '[ "$(tr -d "[:space:]" < "$D/remote_user.txt")" = deploy ]'
check "remote_disk.txt — место на диске сервера" "ssh server df -h > ~/m11/remote_disk.txt" \
  'grep -q "^Filesystem" "$D/remote_disk.txt"'

section "Задание 5: scp"
check "release.txt доставлен на сервер в домашнюю папку deploy" "scp ~/m11/release.txt server:~/" \
  '[ -n "$REMOTE_RELEASE" ] && [ "$REMOTE_RELEASE" = "$(cat "$D/release.txt")" ]'

section "Задание 6: защита сервера"
C=/etc/ssh/sshd_config
check "PasswordAuthentication no" "sudo nano /etc/ssh/sshd_config" 'grep -Eq "^PasswordAuthentication[[:space:]]+no" "$C"'
check "PermitRootLogin no" "sudo nano /etc/ssh/sshd_config" 'grep -Eq "^PermitRootLogin[[:space:]]+no" "$C"'
check "SSH-сервер перезапущен: вход по паролю больше не предлагается" "sudo rc-service sshd restart" \
  'grep -q "Permission denied" <<< "$NOPASS" && ! grep -q "password" <<< "$NOPASS"'
check "Вход по ключу после защиты всё ещё работает" "не закрывай себе дверь: ключ должен работать" '[ "$KEY_LOGIN" = 1 ]'

section "Квиз"
ask "Какой файл ключа можно отдавать другим (класть на сервер): id_ed25519 или id_ed25519.pub?" "публичный — public" 'id_ed25519\.pub|\.pub|pub' cs
ask "Какие права должны быть у приватного ключа? (цифрами)" "только владелец читает и пишет" '600|0600|400|0400'
ask "Какая команда копирует публичный ключ на сервер?" "ssh-copy-…" 'ssh-copy-id|ssh-copy-id .*'
ask "На каком порту по умолчанию работает SSH?" "мы видели его в модуле 10" '22'
ask "В каком файле настраиваются короткие имена серверов (Host)? (путь)" "в папке ~/.ssh" '~/\.ssh/config|\.ssh/config|/home/[a-z]+/\.ssh/config|config'

summary
