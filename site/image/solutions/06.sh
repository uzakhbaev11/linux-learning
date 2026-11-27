# Решение модуля 6 (то, что сделал бы ученик). Каждая строка выполняется в терминале student.
pgrep -f stuck-worker > ~/m06/worker.pid
kill $(cat ~/m06/worker.pid); sleep 2
kill -9 $(pgrep -f hung-job); sleep 1
echo httpd > ~/m06/port_owner.txt && ss -tlnp | grep ":5000 " | grep -o "pid=[0-9]*" | cut -d= -f2 > ~/m06/port_pid.txt
cd ~/m06 && (nohup bash report.sh &); cd
sleep 11
