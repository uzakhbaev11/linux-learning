#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m09"

title "Проверка модуля 9: Cron, архивы, бэкапы"
[ -d "$D/myapp" ] || { fail "Папка ~/m09/myapp не найдена" "сначала выполни: lab setup 9"; summary; }

A="$D/myapp.tar.gz"
section "Задание 1: архив"
check "myapp.tar.gz — рабочий архив с myapp/src/app.py" "tar -czf ~/m09/myapp.tar.gz -C ~/m09 ..." \
  'tar -tzf "$A" | grep -qx "myapp/src/app.py"'
check "В архиве нет node_modules" "--exclude=node_modules" \
  '! tar -tzf "$A" | grep -q node_modules'
check "contents.txt — список файлов архива" "tar -tzf ... > ~/m09/contents.txt" \
  'diff -q <(tar -tzf "$A") "$D/contents.txt"'

section "Задание 2: восстановление"
check "Архив распакован в ~/m09/restore" "mkdir ~/m09/restore, затем tar -xzf ... -C ~/m09/restore" \
  'diff -q "$D/myapp/config/settings.ini" "$D/restore/myapp/config/settings.ini"'

section "Задание 3: gzip"
check "old.log сжат: есть old.log.gz, а old.log нет" "gzip ~/m09/old.log" \
  '[ ! -e "$D/old.log" ] && gzip -t "$D/old.log.gz"'
check "old_errors.txt — число строк с ERROR" "zcat old.log.gz | grep -c ERROR" \
  '[ "$(tr -d "[:space:]" < "$D/old_errors.txt")" = "$(zcat "$D/old.log.gz" | grep -c ERROR)" ]'

B="$D/backups"
section "Задание 4: backup.sh"
check "backup.sh исполняемый и начинается с #!" "chmod +x ~/m09/backup.sh" \
  '[ -x "$D/backup.sh" ] && head -1 "$D/backup.sh" | grep -q "^#!"'
# Подкладываем 4 «старых» бэкапа и запускаем скрипт из другой папки: должно остаться 3, свежий — рабочий
if [ -x "$D/backup.sh" ] && ls "$B"/myapp_*.tar.gz >/dev/null 2>&1; then
  real="$(ls -t "$B"/myapp_*.tar.gz | head -1)"
  for n in 1 2 3 4; do cp "$real" "$B/myapp_2000-01-0${n}_00-00-00.tar.gz"; touch -d "2000-01-0$n" "$B/myapp_2000-01-0${n}_00-00-00.tar.gz"; done
  sleep 1
  BACKUP_OUT="$(cd / && "$D/backup.sh" 2>&1)"
fi
check "Скрипт создаёт архив в ~/m09/backups и пишет «Бэкап создан»" "tar -czf \"\$HOME/m09/backups/myapp_\$(date +%F_%H-%M-%S).tar.gz\" ..." \
  'grep -q "Бэкап создан" <<< "$BACKUP_OUT" && tar -tzf "$(ls -t "$B"/myapp_*.tar.gz | head -1)" | grep -qx "myapp/src/app.py"'
check "Ротация: остаётся 3 самых свежих" "ls -t ... | tail -n +4 | xargs -r rm --" \
  '[ "$(ls "$B"/myapp_*.tar.gz | wc -l)" -eq 3 ] && ! ls "$B"/myapp_2000-* >/dev/null 2>&1'

section "Задание 5: cron"
CRON="$(crontab -l 2>/dev/null | grep -v "^[[:space:]]*#")"
check "В crontab: каждую минуту запускать backup.sh по полному пути" "* * * * * /home/student/m09/backup.sh >> /home/student/m09/backup.log 2>&1" \
  'grep -Eq "^\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+(/home/student|\\\$HOME)/m09/backup\.sh" <<< "$CRON"'
check "Вывод и ошибки идут в backup.log" ">> /home/student/m09/backup.log 2>&1" \
  'grep "backup.sh" <<< "$CRON" | grep -q ">> *[^ ]*m09/backup.log *2>&1"'
check "cron уже запускал бэкап (backup.log не пустой)" "подожди 1–2 минуты после crontab -e" \
  'grep -q "Бэкап создан" "$D/backup.log"'

section "Квиз"
ask "Какой флаг tar означает «распаковать»?" "c — create, t — list, а распаковать — e(x)tract" '-x|x' cs
ask "Как в cron записать «каждый день в 03:00»?" "минута час день месяц день_недели" '0 3 \* \* \*'
ask "Какой командой посмотреть своё расписание cron?" "crontab + флаг" 'crontab -l'
ask "Какой командой прочитать app.log.gz, не распаковывая его?" "z + cat" 'zcat|zcat app\.log\.gz|gunzip -c app\.log\.gz|gzip -dc app\.log\.gz|zless app\.log\.gz|zless'

summary
