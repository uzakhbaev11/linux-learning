#!/usr/bin/env bash
source /course/lib/check-lib.sh "$@"
D="$HOME/m12"
U=/etc/systemd/system/myapp.service

title "Проверка модуля 12: systemd и логи"
if [ ! -d /run/systemd/system ]; then
  fail "Модуль 12 выполняется в виртуальной машине Ubuntu (здесь нет systemd)" \
    "см. раздел «Подготовка» в теории, затем в ВМ: lab setup 12 и lab check 12"
  summary
fi
[ -d "$D/app" ] || { fail "~/m12 не найден" "сначала выполни: lab setup 12"; summary; }

prop() { systemctl show -p "$1" --value myapp 2>/dev/null; }

section "Задание 1"
check "running.txt — число запущенных сервисов" "systemctl list-units --type=service --state=running --no-legend | wc -l" \
  'n=$(tr -d "[:space:]" < "$D/running.txt"); r=$(systemctl list-units --type=service --state=running --no-legend | wc -l); [ "$n" -ge $((r-5)) ] && [ "$n" -le $((r+5)) ]'

section "Задание 2"
check "Unit-файл /etc/systemd/system/myapp.service на месте, без ???" "sudo cp ~/m12/myapp.service /etc/systemd/system/" \
  '[ -f "$U" ] && ! grep -q "???" "$U"'
check "Сервис работает не от root" "User=имя_пользователя (whoami) в секции [Service]" \
  'u=$(prop User); [ -n "$u" ] && [ "$u" != root ]'
check "myapp запущен (active)" "sudo systemctl daemon-reload, потом sudo systemctl start myapp; ошибки: systemctl status myapp" \
  'systemctl is-active --quiet myapp'
check "Приложение отвечает на /health" "curl localhost:8000/health" \
  'curl -fsS --max-time 5 localhost:8000/health | grep -q "\"status\": \"ok\""'

section "Задание 3"
check "Автозапуск включён (enabled)" "sudo systemctl enable myapp" \
  '[ "$(systemctl is-enabled myapp 2>/dev/null)" = enabled ]'

section "Задание 4"
check "Restart= настроен" "Restart=on-failure или Restart=always" \
  'r=$(prop Restart); [ "$r" = on-failure ] || [ "$r" = always ]'
check "systemd поднимал упавшее приложение" "curl localhost:8000/crash, подожди пару секунд" \
  'journalctl -u myapp --no-pager 2>/dev/null | grep -q "Scheduled restart job"'

section "Задание 5"
check "myapp.log — журнал сервиса с сообщением о падении" "journalctl -u myapp --no-pager > ~/m12/myapp.log" \
  'grep -q "FATAL" "$D/myapp.log" && grep -q "myapp started" "$D/myapp.log"'

section "Задание 6"
check "APP_MESSAGE изменён и приложение перезапущено" "поменяй APP_MESSAGE в .env и sudo systemctl restart myapp" \
  'grep -q "^APP_MESSAGE=" "$D/app/.env" && ! grep -qx "APP_MESSAGE=hello" "$D/app/.env" && curl -fsS --max-time 5 localhost:8000/health | grep -qF "\"message\": \"$(sed -n "s/^APP_MESSAGE=//p" "$D/app/.env")\""'

section "Квиз"
ask "Какую команду нужно выполнить после изменения unit-файла, чтобы systemd его перечитал?" "sudo systemctl ..." '(sudo )?systemctl daemon-reload'
ask "Чем отличается enable от start? Какая команда включает АВТОЗАПУСК при загрузке: enable или start?" "одна — «сейчас», другая — «при загрузке»" 'enable'
ask "Каким флагом journalctl следит за логом в реальном времени (как tail -f)?" "та же буква, что у tail" '-f|--follow'
ask "Какая команда покажет логи сервиса myapp? (команда целиком)" "journalctl -u ..." '(sudo )?journalctl -u myapp( .*)?|(sudo )?journalctl --unit[= ]myapp( .*)?'
ask "В какой секции unit-файла пишут WantedBy=multi-user.target? (только название)" "[...] — последняя секция" '\[?install\]?'

summary
