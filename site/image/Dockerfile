# Linux для браузера: Alpine (32-бит x86), запускается в эмуляторе v86.
# Собирается из корня linux-learning:  site/image/build.sh
FROM docker.io/i386/alpine:3.21.0

ENV KERNEL=virt

# Система и загрузка (по образцу v86/tools/docker/alpine)
RUN apk add --no-cache openrc alpine-base agetty alpine-conf linux-$KERNEL linux-firmware-none

# Инструменты курса: GNU-версии вместо урезанных busybox, чтобы всё вело себя как в Ubuntu
RUN apk add --no-cache \
      bash bash-completion coreutils findutils grep sed gawk diffutils util-linux \
      less nano vim tree file procps-ng htop sudo shadow ncurses \
      mandoc man-pages docs

# Модули 06–11: процессы, архивы, cron, сеть, SSH
#   psmisc (pstree, killall), iproute2 (ss, ip), curl, busybox-extras (httpd — учебный веб-сервер),
#   openssh (сервер и клиент), cronie (cron как в Ubuntu), GNU tar и gzip
RUN apk add --no-cache psmisc iproute2 curl busybox-extras openssh cronie tar gzip \
 && ssh-keygen -A \
 && printf 'auto lo\niface lo inet loopback\n' > /etc/network/interfaces \
 && printf '#!/bin/sh\n# docker export оставляет /etc/hosts пустым — восстанавливаем при загрузке\n[ -s /etc/hosts ] || printf "127.0.0.1\\tlocalhost linux-lab\\n::1\\tlocalhost\\n" > /etc/hosts\n' > /etc/local.d/hosts.start \
 && chmod +x /etc/local.d/hosts.start

# Модуль 07: свой репозиторий пакетов внутри Linux — в браузере нет интернета,
# а научиться ставить программы (sudo apk add jq) хочется. Индекс подписан своим ключом.
RUN apk update -q && apk upgrade -q && apk add -q abuild \
 && mkdir -p /srv/repo/x86 && cd /srv/repo/x86 \
 && apk fetch -q jq oniguruma figlet \
 && apk index -q -o APKINDEX.tar.gz *.apk \
 && abuild-keygen -a -n -q 2>/dev/null && abuild-sign -q -k /root/.abuild/*.rsa APKINDEX.tar.gz \
 && cp /root/.abuild/*.rsa.pub /etc/apk/keys/ \
 && apk del -q abuild && rm -rf /root/.abuild /var/cache/apk/* \
 && echo /srv/repo > /etc/apk/repositories

# Модуль 11: «сервер» для SSH — пользователь deploy (пароль: deploy) на этом же компьютере
RUN adduser -D -s /bin/bash deploy && echo 'deploy:deploy' | chpasswd

# Пользователь student (пароль: student), автологин на последовательной консоли
RUN adduser -D -s /bin/bash student \
 && echo 'student:student' | chpasswd \
 && echo 'student ALL=(ALL) ALL' > /etc/sudoers.d/student \
 && sed -i 's/getty 38400 tty1/agetty --autologin student tty1 linux/' /etc/inittab \
 && echo 'ttyS0::respawn:/sbin/agetty --autologin student -s ttyS0 115200 xterm-256color' >> /etc/inittab \
 && setup-hostname linux-lab \
  && echo 'hostname="linux-lab"' > /etc/conf.d/hostname && : > /etc/motd

# Второй порт ttyS1 — скрытый помощник сайта (запуск проверок), см. image/lab-agent
COPY site/image/lab-agent /usr/local/bin/lab-agent
RUN chmod +x /usr/local/bin/lab-agent \
 && echo 'ttyS1::respawn:/bin/su -l student -s /bin/bash -c /usr/local/bin/lab-agent' >> /etc/inittab

COPY --chown=student:student site/image/bashrc /home/student/.bashrc
RUN printf '[ -f ~/.bashrc ] && . ~/.bashrc\n' > /home/student/.bash_profile \
 && chown student:student /home/student/.bash_profile

# Курс НЕ кладём в образ: сайт присылает скрипты в /course при запуске (через lab-agent).
# Так новые модули не требуют пересборки Linux, и сохранения учеников не сбрасываются.
RUN mkdir /course && chown student:student /course \
 && printf '#!/bin/sh\n[ -f /course/lab/lab ] || { echo "Курс ещё загружается, подожди пару секунд и повтори."; exit 1; }\nexec bash /course/lab/lab "$@"\n' > /usr/local/bin/lab \
 && chmod +x /usr/local/bin/lab

# Службы (https://wiki.alpinelinux.org/wiki/Alpine_Linux_in_a_chroot)
RUN for i in devfs dmesg mdev hwdrivers; do rc-update add $i sysinit; done \
 && for i in hwclock modules sysctl hostname syslog bootmisc; do rc-update add $i boot; done \
 && rc-update add networking boot && rc-update add local boot \
 && for i in sshd cronie; do rc-update add $i default; done \
 && rc-update add killprocs shutdown

# initramfs с модулями 9p — корневая файловая система подгружается по сети из файлов сайта
RUN mkinitfs -F "base virtio 9p" $(cat /usr/share/kernel/$KERNEL/kernel.release)
