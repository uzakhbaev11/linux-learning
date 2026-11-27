# Решение модуля 7 (то, что сделал бы ученик). Каждая строка выполняется в терминале student.
cd ~/m07 && apk info --who-owns /usr/bin/htop > owner.txt; cd
echo student | sudo -S apk update && echo student | sudo -S apk add jq
cd ~/m07 && jq -r .version config.json > version.txt && jq -r .db.port config.json > db_port.txt; cd
mkdir -p ~/bin && printf '#!/usr/bin/env bash\necho "Hello from bin"\n' > ~/bin/hello && chmod +x ~/bin/hello
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc && echo "alias ll='ls -la'" >> ~/.bashrc
cd ~/m07 && printf 'APP_PORT=3000\nDB_PASSWORD=supersecret\n' > .env && chmod 600 .env; cd
