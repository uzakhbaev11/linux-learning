#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m08"

title "Проверка модуля 8: Bash-скрипты"
[ -d "$D" ] || { fail "Папка ~/m08 не найдена" "сначала выполни: lab setup 8"; summary; }
cd "$D" || exit 1

# Свой тестовый лог и список: скрипты должны работать не только на файлах из setup
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
printf '%s\n' "x [INFO] a" "x [ERROR] b" "x [INFO] c" "x [ERROR] d" "x [ERROR] e" > "$TMP/test.log"
printf '%s\n' /etc /etc/hosts "$HOME" > "$TMP/good.txt"

section "Задание 1: greet.sh"
check "greet.sh исполняемый и начинается с #!" "chmod +x greet.sh, первая строка #!/usr/bin/env bash" \
  '[ -x greet.sh ] && head -1 greet.sh | grep -q "^#!"'
check "./greet.sh Анна → Привет, Анна!" "echo \"Привет, \$1!\"" \
  '[ "$(./greet.sh Анна 2>/dev/null)" = "Привет, Анна!" ] && [ "$(./greet.sh DevOps 2>/dev/null)" = "Привет, DevOps!" ]'
check "Без аргумента — код возврата 1" "if [[ \$# -eq 0 ]]; then ...; exit 1; fi" \
  './greet.sh </dev/null >/dev/null 2>&1; [ $? -eq 1 ]'

section "Задание 2: log_summary.sh"
check "Подсчёт по app.log" "for lvl in INFO WARN ERROR; do echo \"\$lvl: \$(grep -c ...)\"; done" \
  '[ "$(./log_summary.sh app.log 2>/dev/null)" = "$(printf "INFO: 121\nWARN: 24\nERROR: 9")" ]'
check "Работает с другим логом (там нет WARN)" "путь к логу бери из \$1; grep -c без совпадений возвращает код 1 — не дай set -e остановить скрипт" \
  '[ "$(./log_summary.sh "$TMP/test.log" 2>/dev/null)" = "$(printf "INFO: 2\nWARN: 0\nERROR: 3")" ]'
check "Нет файла — «Файл не найден» и код 2" "if [[ ! -f \"\$1\" ]]; then ...; exit 2; fi" \
  'out="$(./log_summary.sh /nope.log 2>&1)"; [ $? -eq 2 ] && grep -q "Файл не найден: /nope.log" <<< "$out"'

section "Задание 3: healthcheck.sh"
check "Вывод для checklist.txt" "while read -r path; do ...; done < \"\$1\"" \
  '[ "$(./healthcheck.sh checklist.txt 2>/dev/null)" = "$(printf "OK /etc/passwd\nOK /etc/hosts\nOK /var/log\nMISSING /etc/myapp/config.yml\nOK /home/student\nMISSING /srv/myapp/.env\nПроблем: 2")" ]'
check "Есть проблемы — код возврата 1" "в конце: exit 1, если проблем больше 0" \
  './healthcheck.sh checklist.txt >/dev/null 2>&1; [ $? -eq 1 ]'
check "Всё на месте — «Проблем: 0» и код 0" "exit 0, если проблем нет" \
  './healthcheck.sh "$TMP/good.txt" 2>/dev/null | tail -1 | grep -qx "Проблем: 0" && ./healthcheck.sh "$TMP/good.txt" >/dev/null 2>&1'
check "Есть функция check_path" "check_path() { ... }" \
  'grep -Eq "^[[:space:]]*(function[[:space:]]+)?check_path[[:space:]]*(\(\))?[[:space:]]*\{?" healthcheck.sh'

section "Квиз"
ask "Какой код возврата означает успех?" "ноль или не ноль?" '0'
ask "В какой переменной хранится количество аргументов скрипта?" "доллар и решётка" '\$#'
ask "Какая переменная хранит код возврата последней команды?" "доллар и знак вопроса" '\$\?'
ask "Что выведет echo '\$HOME' (в одинарных кавычках)?" "в одинарных кавычках ничего не подставляется" '\$HOME'
ask "Какой флаг set останавливает скрипт на первой ошибке?" "e — exit" '-e|set -e' cs

summary
