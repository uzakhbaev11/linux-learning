# Решение модуля 5 (то, что сделал бы ученик). Каждая строка выполняется в терминале student.
cd ~/m05 && grep "^student:" /etc/passwd > me.txt; cd
cd ~/m05/app && chmod 600 .env && chmod 755 deploy.sh && ./deploy.sh > ~/m05/deploy.out && chmod 644 config.yml && chmod 700 logs; cd
cd ~/m05 && chmod 600 payment.key && echo student | sudo -S chown root:root payment.key; cd
echo student | sudo -S groupadd devs 2>/dev/null; echo student | sudo -S usermod -aG devs student
echo student | sudo -S chgrp devs ~/m05/shared && chmod 770 ~/m05/shared
