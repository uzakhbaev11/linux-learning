# SKIP: нужен systemd — проверяется в Ubuntu с systemd, не в браузере
# Решение модуля 12 (для ручной проверки в ВМ Ubuntu: строки ниже по очереди).
systemctl list-units --type=service --state=running --no-legend | wc -l > ~/m12/running.txt
sed -i "s|User=???|User=$(whoami)|; s|ExecStart=/usr/bin/python3 ???|ExecStart=/usr/bin/python3 $HOME/m12/app/server.py|; s|Restart=???|Restart=on-failure|; s|WantedBy=???|WantedBy=multi-user.target|" ~/m12/myapp.service
sudo cp ~/m12/myapp.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now myapp && sleep 2
curl -s localhost:8000/crash; sleep 4
journalctl -u myapp --no-pager > ~/m12/myapp.log
sed -i 's/^APP_MESSAGE=.*/APP_MESSAGE=deployed/' ~/m12/app/.env && sudo systemctl restart myapp && sleep 2
