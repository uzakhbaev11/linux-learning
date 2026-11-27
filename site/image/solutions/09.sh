# Решение модуля 9 (то, что сделал бы ученик). Каждая строка выполняется в терминале student.
cd ~/m09 && tar -czf myapp.tar.gz --exclude=node_modules -C ~/m09 myapp && tar -tzf myapp.tar.gz > contents.txt && mkdir restore && tar -xzf myapp.tar.gz -C restore; cd
cd ~/m09 && gzip old.log && zcat old.log.gz | grep -c ERROR > old_errors.txt; cd
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'B="$HOME/m09/backups"' 'mkdir -p "$B"' 'f="$B/myapp_$(date +%F_%H-%M-%S).tar.gz"' 'tar -czf "$f" --exclude=node_modules -C "$HOME/m09" myapp' 'ls -t "$B"/myapp_*.tar.gz | tail -n +4 | xargs -r rm --' 'echo "Бэкап создан: $f"' > ~/m09/backup.sh && chmod +x ~/m09/backup.sh && ~/m09/backup.sh
echo '* * * * * /home/student/m09/backup.sh >> /home/student/m09/backup.log 2>&1' | crontab -
# ждём, пока cron запустит бэкап хотя бы раз
for i in $(seq 1 130); do grep -q "Бэкап создан" ~/m09/backup.log 2>/dev/null && break; sleep 1; done
