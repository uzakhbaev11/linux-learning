#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m01"
prepare_dir "$D"

mkdir -p "$D"/house/{kitchen,bedroom,bathroom,.attic}
echo "Холодильник пуст. Сходи в магазин." > "$D/house/kitchen/fridge.txt"
echo "Здесь ничего нет. Ищи лучше." > "$D/house/bathroom/mirror.txt"
touch "$D"/house/bedroom/{bed,lamp,.diary}
echo "Ты нашёл тайную комнату! Секретное слово: penguin" > "$D/house/.attic/note.txt"

echo "✅ Модуль 1 подготовлен: $D"
echo "Задания: lab tasks 1"
