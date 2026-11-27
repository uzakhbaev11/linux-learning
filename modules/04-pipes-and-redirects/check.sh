#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m04"
L="$D/access.log"

title "Проверка модуля 4: Пайпы и перенаправления"
[ -f "$L" ] || { fail "~/m04/access.log не найден" "сначала выполни: lab setup 4"; summary; }

# число из файла без пробелов
num() { tr -d '[:space:]' < "$1"; }
# вывод uniq -c без лишних пробелов: «150 1.2.3.4»
norm() { awk '{print $1, $2}'; }

section "Задание 1"
check "total.txt — количество строк" "wc -l печатает и имя файла — подай файл через <" \
  '[ "$(num "$D/total.txt")" = "$(wc -l < "$L")" ]'
check "count_404.txt — количество 404" "найди строки со статусом 404 и передай их по пайпу в wc -l" \
  '[ "$(num "$D/count_404.txt")" = "$(awk "\$9 == 404" "$L" | wc -l)" ]'

section "Задание 2"
check "top_ips.txt — три самых активных IP" "вырезать IP → sort → uniq -c → sort по числам наоборот → первые 3" \
  'diff -q <(norm < "$D/top_ips.txt") <(cut -d" " -f1 "$L" | sort | uniq -c | sort -nr | head -n 3 | norm)'

section "Задание 3"
check "paths.txt — уникальные пути" "7-е поле через awk или cut, затем сортировка без повторов" \
  'diff -q "$D/paths.txt" <(awk "{print \$7}" "$L" | sort -u)'
check "methods.txt — методы без кавычек" "6-е поле, убрать кавычки через tr -d, без повторов" \
  'diff -q <(sort "$D/methods.txt") <(printf "GET\nPOST\n")'

section "Задание 4"
check "deploy.out — только обычный вывод" "> — для stdout, 2> — для stderr, в одной команде" \
  '[ "$(grep -c "^Шаг" "$D/deploy.out")" = 3 ] && ! grep -qE "warning|ERROR" "$D/deploy.out"'
check "deploy.err — только ошибки" "поток ошибок — номер 2" \
  '[ "$(wc -l < "$D/deploy.err")" = 2 ] && grep -q "ERROR" "$D/deploy.err" && ! grep -q "^Шаг" "$D/deploy.err"'
check "all.log — оба потока в одном файле" "сначала > в файл, потом поток 2 туда же, куда 1" \
  'grep -q "^Шаг 3" "$D/all.log" && grep -q "ERROR" "$D/all.log" && [ "$(wc -l < "$D/all.log")" = 5 ]'

section "Задание 5"
check "history.log — новая строка в конце, старые на месте" ">> дописывает, > затирает (восстановить: lab setup 4)" \
  '[ "$(head -n 3 "$D/history.log")" = "$(printf "2026-11-20 deploy v1.0 done\n2026-11-24 deploy v1.1 done\n2026-11-26 deploy v1.2 done")" ] && [ "$(tail -n 1 "$D/history.log")" = "2026-11-27 deploy v1.3 done" ]'

section "Задание 6"
check "errors500.txt — строки со статусом 500" "найти строки 500 → tee в файл → wc -l" \
  'diff -q "$D/errors500.txt" <(awk "\$9 == 500" "$L")'

section "Квиз"
ask "Какой номер у потока ошибок (stderr)?" "0 — stdin, 1 — stdout, ..." '2'
ask "Какой оператор ДОПИСЫВАЕТ в конец файла, а не затирает его?" "два символа" '>>'
ask "Как выбросить ошибки команды в «чёрную дыру»? (напиши кусок команды после неё)" "2> и специальный файл в /dev" '2> ?/dev/null'
ask "Какая команда с флагом считает повторы одинаковых соседних строк?" "uniq ..." 'uniq -c'
ask "Какие флаги sort сортируют по числам от большего к меньшему? (например -x)" "number + reverse" '-nr|-rn|-n -r|-r -n' cs

summary
