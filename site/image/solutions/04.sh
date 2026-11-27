# Решение модуля 4 (то, что сделал бы ученик). Каждая строка выполняется в терминале student.
cd ~/m04 && wc -l < access.log > total.txt && grep " 404 " access.log | wc -l > count_404.txt; cd
cd ~/m04 && cut -d' ' -f1 access.log | sort | uniq -c | sort -nr | head -n 3 > top_ips.txt; cd
cd ~/m04 && awk '{print $7}' access.log | sort -u > paths.txt && awk '{print $6}' access.log | tr -d '"' | sort -u > methods.txt; cd
cd ~/m04 && bash deploy.sh > deploy.out 2> deploy.err && bash deploy.sh > all.log 2>&1 && bash deploy.sh 2>/dev/null; cd
cd ~/m04 && echo "2026-11-27 deploy v1.3 done" >> history.log && grep " 500 " access.log | tee errors500.txt | wc -l; cd
