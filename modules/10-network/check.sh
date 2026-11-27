#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m10"

title "Проверка модуля 10: Сеть"
[ -d "$D/site" ] || { fail "~/m10/site не найдена" "сначала выполни: lab setup 10"; summary; }

section "Задание 1"
check "ping.txt — 3 пакета отправлено и получено" "ping -c 3 localhost > ~/m10/ping.txt" \
  'grep -Eq "3 packets transmitted, 3 (packets )?received" "$D/ping.txt"'

section "Задание 2"
check "Веб-сервер отвечает на localhost:8080" "httpd -p 8080 -h ~/m10/site" \
  'curl -s -m 5 localhost:8080/ | diff -q - "$D/site/index.html"'
check "page.html — страница, скачанная через curl" "curl -s localhost:8080/ > ~/m10/page.html (или curl -o)" \
  'diff -q "$D/site/index.html" "$D/page.html"'
check "headers.txt — заголовки ответа" "curl -I" \
  'grep -q "^HTTP/1.[01] 200" "$D/headers.txt" && grep -qi "^content-type:" "$D/headers.txt"'

section "Задание 3"
check "codes.txt — коды ответа 200 и 404" "curl -s -o /dev/null -w \"%{http_code}\\n\" ..." \
  '[ "$(tr -d "\r" < "$D/codes.txt" | sed "/^$/d")" = "$(printf "200\n404")" ]'

section "Задание 4"
check "health.json — ответ API со статусом ok" "curl -s localhost:8080/cgi-bin/health > ~/m10/health.json" \
  'grep -Eq "\"status\": *\"ok\"" "$D/health.json"'

section "Задание 5"
check "port.txt — порт таинственного сервиса" "ss -tlnp — ищи httpd, который ты не запускал" \
  '[ "$(tr -d "[:space:]" < "$D/port.txt")" = "4815" ]'

section "Задание 6"
check "Имя shop.local указывает на 127.0.0.1" "sudo nano /etc/hosts — строка: 127.0.0.1 shop.local" \
  'getent hosts shop.local | grep -q "^127\.0\.0\.1"'
check "shop.html — страница, полученная по имени shop.local" "curl -s http://shop.local:8080/ > ~/m10/shop.html" \
  'diff -q "$D/site/index.html" "$D/shop.html"'

section "Задание 7"
check "Админка слушает только 127.0.0.1:9090" "httpd -p 127.0.0.1:9090 -h ~/m10/admin" \
  'ss -tln | grep -q "127\.0\.0\.1:9090 "'

section "Квиз"
ask "Какое секретное слово отдаёт таинственный сервис? (задание 5)" "curl localhost:ПОРТ" 'nebula|secret=nebula'
ask "Какой стандартный порт у HTTPS?" "HTTP — 80, а HTTPS…" '443'
ask "Какой командой посмотреть, какие порты слушают программы на сервере? (с флагами)" "ss + флаги t, l, n, p" 'ss -tlnp|ss -tulpn|ss -tunlp|ss -ltnp|ss -lntp|sudo ss -tlnp|sudo ss -tulpn'
ask "Что означает код ответа 404? (по-английски, два слова)" "Not …" 'not found'
ask "База данных слушает 127.0.0.1:5432. Можно подключиться к ней с другого компьютера? (да/нет)" "127.0.0.1 — это «только я сам»" 'нет|no'

summary
