#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m10"

prepare_dir "$D"
# Останавливаем учебные веб-серверы из прошлых запусков: их папки только что пересозданы
pkill -u "$(id -u)" -x httpd 2>/dev/null || true
sleep 0.5

# Сайт интернет-магазина
mkdir -p "$D/site/cgi-bin" "$D/admin"
cat > "$D/site/index.html" <<'HTML'
<!doctype html>
<html>
  <head><title>Shop</title></head>
  <body>
    <h1>Shop: лучшие товары для бэкендеров</h1>
    <p>Кружка «It works on my machine» — 2500 ₸</p>
  </body>
</html>
HTML

# Маленький «API»: GET /cgi-bin/health — так бэкенды сообщают, что они живы
cat > "$D/site/cgi-bin/health" <<'SH'
#!/bin/bash
echo "Content-Type: application/json"
echo
echo "{\"status\": \"ok\", \"service\": \"shop-api\", \"version\": \"1.4.2\"}"
SH
chmod +x "$D/site/cgi-bin/health"

echo "<h1>Админка магазина</h1>" > "$D/admin/index.html"

# Таинственный сервис: кто-то запустил его на сервере и забыл. Порт надо найти самому.
mkdir -p "$HOME/.mystery-service"
echo "SECRET=nebula — ты нашёл забытый сервис!" > "$HOME/.mystery-service/index.html"
httpd -p 4815 -h "$HOME/.mystery-service"

echo "✅ Модуль 10 подготовлен: $D"
echo "Задания: lab tasks 10"
