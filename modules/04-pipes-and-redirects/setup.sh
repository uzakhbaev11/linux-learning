#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m04"
prepare_dir "$D"

# Лог веб-сервера в формате nginx (500 строк)
ips=(203.0.113.7 198.51.100.23 10.0.0.15 192.0.2.44 172.16.5.9 10.0.0.88)
paths=(/ /api/products /api/products/42 /api/cart /api/orders /login /static/app.js /static/style.css)
for i in $(seq 1 500); do
  r=$(( i * 37 % 100 ))
  if   (( r < 30 )); then ip=${ips[0]}
  elif (( r < 52 )); then ip=${ips[1]}
  elif (( r < 68 )); then ip=${ips[2]}
  elif (( r < 80 )); then ip=${ips[3]}
  elif (( r < 90 )); then ip=${ips[4]}
  else ip=${ips[5]}; fi
  s=$(( i * 13 % 50 ))
  path=${paths[$(( i * 7 % 8 ))]}
  method=GET
  if   (( s < 2 )); then status=404; path=$([ $((i % 2)) -eq 0 ] && echo /wp-login.php || echo /.env)
  elif (( s == 2 )); then status=500; path=/api/orders; method=POST
  elif [ "$path" = /api/orders ]; then status=201; method=POST
  elif [ "$path" = /login ] && (( i % 3 == 0 )); then status=302; method=POST
  else status=200; fi
  bytes=$(( (i * 97) % 5000 + 120 ))
  printf '%s - - [27/Nov/2026:10:%02d:%02d +0000] "%s %s HTTP/1.1" %s %s\n' \
    "$ip" $((i / 60 % 60)) $((i % 60)) "$method" "$path" "$status" "$bytes"
done > "$D/access.log"

# «Деплой», который пишет и в stdout, и в stderr
cat > "$D/deploy.sh" <<'EOF'
#!/usr/bin/env bash
echo "Шаг 1/3: скачиваю код"
echo "warning: используется устаревшая версия node" >&2
echo "Шаг 2/3: устанавливаю зависимости"
echo "ERROR: не найден файл .env" >&2
echo "Шаг 3/3: деплой завершён"
EOF

cat > "$D/history.log" <<'EOF'
2026-11-20 deploy v1.0 done
2026-11-24 deploy v1.1 done
2026-11-26 deploy v1.2 done
EOF

echo "✅ Модуль 4 подготовлен: $D"
echo "Задания: lab tasks 4"
