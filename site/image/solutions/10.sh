# Решение модуля 10 (то, что сделал бы ученик). Каждая строка выполняется в терминале student.
cd ~/m10 && ping -c 3 localhost > ping.txt
httpd -p 8080 -h ~/m10/site && sleep 1
cd ~/m10 && curl -s localhost:8080/ > page.html && curl -sI localhost:8080/ > headers.txt
cd ~/m10 && { curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/; curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/admin.html; } > codes.txt
curl -s localhost:8080/cgi-bin/health > ~/m10/health.json
ss -tlnp | grep -o ':4815 ' | tr -d ': ' > ~/m10/port.txt
echo student | sudo -S sh -c 'grep -q shop.local /etc/hosts || echo "127.0.0.1 shop.local" >> /etc/hosts'
curl -s http://shop.local:8080/ > ~/m10/shop.html
httpd -p 127.0.0.1:9090 -h ~/m10/admin
