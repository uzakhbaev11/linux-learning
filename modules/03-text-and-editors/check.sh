#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m03"
L="$D/app.log"

title "Проверка модуля 3: Текст и редакторы"
[ -f "$L" ] || { fail "~/m03/app.log не найден" "сначала выполни: lab setup 3"; summary; }

section "Задание 1"
check "first10.txt — первые 10 строк" "head -n 10" \
  'diff -q <(head -n 10 "$L") "$D/first10.txt"'
check "last3.txt — последние 3 строки" "tail -n 3" \
  'diff -q <(tail -n 3 "$L") "$D/last3.txt"'

section "Задание 2"
check "errors_count.txt — количество ERROR" "grep -c" \
  '[ "$(tr -d "[:space:]" < "$D/errors_count.txt")" = "$(grep -c ERROR "$L")" ]'
check "errors.txt — строки ERROR с номерами" "grep -n" \
  'diff -q <(grep -n ERROR "$L") "$D/errors.txt"'
check "user1337.txt — строки пользователя 1337" "grep \"user_id=1337\" — без номеров строк" \
  'diff -q <(grep "user_id=1337" "$L") "$D/user1337.txt"'
check "not_info.txt — строки без INFO" "grep -v — без номеров строк" \
  'diff -q <(grep -v INFO "$L") "$D/not_info.txt"'

section "Задание 3"
C="$D/config.ini"
check "port=3000" "nano ~/m03/config.ini" 'grep -qx "port=3000" "$C" && ! grep -q "port=8080" "$C"'
check "debug=false" "nano ~/m03/config.ini" 'grep -qx "debug=false" "$C"'
check "Остальные настройки не сломаны" "host, name, user должны остаться. Восстановить: lab setup 3" \
  'grep -qx "host=127.0.0.1" "$C" && grep -qx "name=shop" "$C" && grep -qx "user=admin" "$C"'

section "Задание 4"
check "vim.txt содержит строку 'I can exit vim'" "i → текст → Esc → :wq" \
  'grep -qx "I can exit vim" "$D/vim.txt"'

section "Задание 5"
check "Генератор запускался, в live.log есть секретное слово" "bash ~/m03/generator.sh &  и подожди ~25 секунд" \
  'grep -q "SECRET=" "$D/live.log"'

section "Квиз"
ask "Какое секретное слово появилось в live.log? (задание 5)" "запусти generator.sh и tail -f" 'orbita|secret=orbita'
ask "Как выйти из vim БЕЗ сохранения?" "двоеточие, q и восклицательный знак" ':q!'
ask "Какие клавиши сохраняют файл в nano? (напиши текстом)" "Ctrl + буква (Write Out)" 'ctrl\+o|ctrl-o|ctrl o|\^o'
ask "Какой флаг grep игнорирует регистр?" "ignore case" '-i'
ask "Какой командой следить за логом в реальном времени? (команда с флагом)" "tail ..." 'tail -f|tail -f .*|tail -F'

summary
