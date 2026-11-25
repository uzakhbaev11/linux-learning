#!/usr/bin/env bash
# Общие функции для setup.sh и check.sh
#
# Режим для сайта: LAB_MACHINE=1 — вместо цветного текста печатаются строки
#   @@SECTION<TAB>название
#   @@PASS<TAB>описание
#   @@FAIL<TAB>описание<TAB>подсказка
#   @@QUIZ<TAB>вопрос<TAB>подсказка<TAB>регулярка<TAB>cs|
#   @@SUMMARY<TAB>пройдено<TAB>всего
# Сайт рисует по ним результаты, а квиз проводит в своём интерфейсе.

GREEN=$'\e[32m'; RED=$'\e[31m'; YELLOW=$'\e[33m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
PASSED=0; FAILED=0; SKIP_QUIZ=0
[ "${1:-}" = "-q" ] && SKIP_QUIZ=1
# Внутренние переменные начинаются с _LAB_, чтобы check.sh модулей их не затёрли
_LAB_M="${LAB_MACHINE:-}"
_LAB_T=$'\t'

title()   { [ -n "$_LAB_M" ] && return; echo; echo "${BOLD}$1${RESET}"; }
section() { if [ -n "$_LAB_M" ]; then echo "@@SECTION$_LAB_T$1"; else echo; echo "${BOLD}— $1${RESET}"; fi; }
pass()    {
  PASSED=$((PASSED+1))
  if [ -n "$_LAB_M" ]; then echo "@@PASS$_LAB_T$1"; else echo "  ${GREEN}✔${RESET} $1"; fi
}
fail()    {
  FAILED=$((FAILED+1))
  if [ -n "$_LAB_M" ]; then echo "@@FAIL$_LAB_T$1$_LAB_T${2:-}"; return; fi
  echo "  ${RED}✘${RESET} $1"
  [ -n "${2:-}" ] && echo "    ${YELLOW}↳ подсказка:${RESET} $2"
}

# check "что проверяем" "подсказка" 'bash-выражение'
check() {
  if eval "$3" >/dev/null 2>&1; then pass "$1"; else fail "$1" "$2"; fi
}

# ask "вопрос" "подсказка" 'регулярка правильных ответов' [cs]
# cs — учитывать регистр (для флагов вроде -S и -s)
ask() {
  local answer ok=1
  if [ -n "$_LAB_M" ]; then echo "@@QUIZ$_LAB_T$1$_LAB_T$2$_LAB_T$3$_LAB_T${4:-}"; return; fi
  [ "$SKIP_QUIZ" = 1 ] && return
  echo
  echo "  ${BOLD}?${RESET} $1"
  read -r -p "    > " answer
  answer="$(echo "$answer" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  [ "${4:-}" = "cs" ] || shopt -s nocasematch
  [[ "$answer" =~ ^($3)$ ]] || ok=0
  shopt -u nocasematch
  if [ "$ok" = 1 ]; then pass "Верно"; else fail "Неверно" "$2"; fi
}

summary() {
  local total=$((PASSED+FAILED))
  if [ -n "$_LAB_M" ]; then echo "@@SUMMARY$_LAB_T$PASSED$_LAB_T$total"; exit 0; fi
  echo
  [ "$SKIP_QUIZ" = 1 ] && echo "(квиз пропущен)"
  if [ "$FAILED" -eq 0 ]; then
    echo "${GREEN}${BOLD}Отлично! $PASSED/$total — модуль пройден 🎉${RESET}"
    echo "Отметь модуль в PROGRESS.md и добавь новые команды в свою шпаргалку."
  else
    echo "${YELLOW}${BOLD}Результат: $PASSED/$total. Исправь ошибки и запусти проверку снова.${RESET}"
    exit 1
  fi
}

# prepare_dir ~/m01 — создаёт чистую папку модуля (спрашивает, если уже есть)
prepare_dir() {
  if [ -e "$1" ]; then
    read -r -p "Папка $1 уже есть, она будет пересоздана (прогресс в ней пропадёт). Продолжить? [y/N] " a
    [[ "$a" =~ ^[yYдД]$ ]] || { echo "Отменено."; exit 0; }
    rm -rf "$1"
  fi
  mkdir -p "$1"
}
