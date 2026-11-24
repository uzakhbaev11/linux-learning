#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m02"
prepare_dir "$D"

# Загрузки вперемешку
mkdir -p "$D/downloads"
cd "$D/downloads"
for i in 1 2 3 4; do echo "jpg image $i" > "photo_$i.jpg"; done
for i in 1 2;     do echo "png image $i" > "screenshot_$i.png"; done
for y in 2024 2025; do echo "pdf report $y" > "report_$y.pdf"; done
echo "купить молоко" > todo.txt
echo "заметки по Linux" > notes.txt
for i in 1 2 3; do echo "mp3 song $i" > "song_$i.mp3"; done
for i in 1 2 3 4 5; do echo "temp" > "cache_$i.tmp"; done

# Лабиринт
for a in north south east west; do
  for b in forest cave river; do
    for c in 1 2 3; do
      mkdir -p "$D/maze/$a/$b/room$c"
      echo "Пусто. Ищи дальше." > "$D/maze/$a/$b/room$c/note.txt"
    done
  done
done
echo "🏆 Поздравляю! Ты нашёл сокровище. Код: linux-explorer" > "$D/maze/west/cave/room2/treasure.txt"
head -c 3000000 /dev/urandom > "$D/maze/east/river/room3/data.bin"

# Мусор
mkdir -p "$D"/trash/old/{logs,cache,junk}
touch "$D"/trash/old/logs/{a,b,c}.log "$D"/trash/old/cache/{1,2}.cache "$D"/trash/readme.txt

echo "✅ Модуль 2 подготовлен: $D"
echo "Задания: lab tasks 2"
