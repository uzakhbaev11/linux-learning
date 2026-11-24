#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m01"

title "Проверка модуля 1: Терминал"
[ -d "$D" ] || { fail "Папка ~/m01 не найдена" "сначала выполни: lab setup 1"; summary; }

section "Задание 1"
check "~/m01/me.txt содержит имя пользователя" "whoami > ~/m01/me.txt" \
  'grep -qx "$(whoami)" "$D/me.txt"'
check "~/m01/system.txt содержит информацию о системе" "uname -a > ~/m01/system.txt" \
  'grep -q "Linux" "$D/system.txt"'

section "Задание 2"
check "Секретное слово найдено (~/m01/code.txt)" "скрытые папки видно через ls -a" \
  'grep -qiw "penguin" "$D/code.txt"'

section "Задание 3"
check "Список файлов /etc сохранён (~/m01/etc-list.txt)" "cd /etc, затем ls > ~/m01/etc-list.txt" \
  'grep -qx "passwd" "$D/etc-list.txt" && grep -qx "hostname" "$D/etc-list.txt"'

section "Задание 6"
check "История команд сохранена (~/m01/history.txt, минимум 10 команд)" "history > ~/m01/history.txt" \
  '[ "$(wc -l < "$D/history.txt")" -ge 10 ]'

section "Квиз (заодно проверяет задания 4 и 5)"
ask "Какая команда показывает, в какой папке ты сейчас находишься?" "print working directory" 'pwd'
ask "Какой флаг ls показывает скрытые файлы?" "смотри man ls, all" '-a|a|--all|-la|-al|-A' cs
ask "С какого символа начинается имя скрытого файла?" "посмотри на .bashrc" '\.|точка|точки'
ask "Какой флаг ls сортирует по размеру? (регистр важен!)" "man ls, затем /size" '-S|S|-lS|-lhS|-lSh' cs
ask "Какая команда возвращает в ПРЕДЫДУЩУЮ папку?" "cd и один символ" 'cd -'
ask "Какие клавиши прерывают выполняющуюся команду? (напиши текстом, НЕ нажимай их 🙂)" "Ctrl + ..." 'ctrl\+c|ctrl-c|ctrl c|\^c|control\+c'

summary
