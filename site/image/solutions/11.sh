# Решение модуля 11 (то, что сделал бы ученик). Каждая строка выполняется в терминале student.
# ssh-copy-id просит пароль deploy, а sshpass нет — в тесте кладём ключ на «сервер» через sudo.
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q </dev/null; chmod 700 ~/.ssh
echo student | sudo -S sh -c 'mkdir -p ~deploy/.ssh && cat /home/student/.ssh/id_ed25519.pub >> ~deploy/.ssh/authorized_keys && chown -R deploy:deploy ~deploy/.ssh && chmod 700 ~deploy/.ssh && chmod 600 ~deploy/.ssh/authorized_keys'
printf 'Host server\n  HostName localhost\n  User deploy\n' >> ~/.ssh/config && chmod 600 ~/.ssh/config
ssh -o StrictHostKeyChecking=accept-new server whoami > ~/m11/remote_user.txt
ssh server df -h > ~/m11/remote_disk.txt
scp ~/m11/release.txt server:~/
echo student | sudo -S sed -i -E 's/^#?PasswordAuthentication .*/PasswordAuthentication no/; s/^#?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
echo student | sudo -S rc-service sshd restart; sleep 2
