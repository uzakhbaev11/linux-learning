#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m02"

title "Проверка модуля 2: Файловая система"
[ -d "$D" ] || { fail "Папка ~/m02 не найдена" "сначала выполни: lab setup 2"; summary; }

section "Задание 2 + 6: структура проекта"
A="$D/myapp"
check "Папки src, tests, config созданы" "mkdir -p ~/m02/myapp/{src,tests,docs,config}" \
  '[ -d "$A/src" ] && [ -d "$A/tests" ] && [ -d "$A/config" ]'
check "Файлы README.md и src/main.py созданы" "touch" \
  '[ -f "$A/README.md" ] && [ -f "$A/src/main.py" ]'
check "Бэкап ~/m02/myapp-backup сделан" "копирование папки требует флага -r" \
  '[ -f "$D/myapp-backup/src/main.py" ]'
check "docs переименована в documentation" "переименование — это mv" \
  '[ -d "$A/documentation" ] && [ ! -e "$A/docs" ]'

section "Задание 3: загрузки"
DL="$D/downloads"
check "images: 4 jpg + 2 png" "mv *.jpg *.png images/" \
  '[ "$(ls "$DL/images" | grep -cE "\.(jpg|png)$")" -eq 6 ]'
check "documents: 2 pdf + 2 txt" "mv *.pdf *.txt documents/" \
  '[ "$(ls "$DL/documents" | grep -cE "\.(pdf|txt)$")" -eq 4 ]'
check "music: 3 mp3" "mv *.mp3 music/" \
  '[ "$(ls "$DL/music" | grep -c "\.mp3$")" -eq 3 ]'
check "Все .tmp удалены" "rm *.tmp" \
  '[ -z "$(find "$DL" -name "*.tmp")" ]'
check "В корне downloads не осталось файлов" "там должны быть только папки" \
  '[ -z "$(find "$DL" -maxdepth 1 -type f)" ]'

section "Задание 4: сокровище"
T="$D/maze/west/cave/room2/treasure.txt"
check "Сокровище скопировано в ~/m02/found/" "find ~/m02/maze -name treasure.txt" \
  'cmp -s "$T" "$D/found/treasure.txt"'
check "Оригинал остался на месте (скопировано, а не перемещено)" "нужен cp, а не mv. Восстановить: lab setup 2" \
  '[ -f "$T" ]'

section "Задание 5: большой файл"
check "Абсолютный путь большого файла в ~/m02/big.txt" "find ~/m02/maze -size +1M, затем realpath" \
  '[ "$(head -1 "$D/big.txt" | tr -d "[:space:]")" = "$D/maze/east/river/room3/data.bin" ]'

section "Задание 7: уборка"
check "Папка trash удалена" "rm -r ~/m02/trash" '[ ! -e "$D/trash" ]'

section "Квиз"
ask "В какой папке хранятся настройки (конфиги) системы и программ?" "сокращение от et cetera" '/etc|etc|/etc/'
ask "В какой папке искать логи?" "/var/..." '/var/log|var/log|/var/log/'
ask "Какой флаг нужен cp и rm, чтобы работать с папками?" "recursive" '-r|r|-R|-rf|-fr'
ask "Как в Linux переименовать файл? (название команды)" "move" 'mv'
ask "Какой флаг find ищет только папки? (полностью: -флаг значение)" "-type ?" '-type d|type d'

summary
