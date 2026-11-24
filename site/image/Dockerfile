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

# Курс: те же скрипты, что и в Docker-лаборатории
COPY lab/lab /course/lab/lab
COPY lib /course/lib
COPY modules /course/modules
RUN chmod -R a+rX /course && chmod +x /course/lab/lab && ln -s /course/lab/lab /usr/local/bin/lab

# Службы (https://wiki.alpinelinux.org/wiki/Alpine_Linux_in_a_chroot)
RUN for i in devfs dmesg mdev hwdrivers; do rc-update add $i sysinit; done \
 && for i in hwclock modules sysctl hostname syslog bootmisc; do rc-update add $i boot; done \
 && rc-update add killprocs shutdown

# initramfs с модулями 9p — корневая файловая система подгружается по сети из файлов сайта
RUN mkinitfs -F "base virtio 9p" $(cat /usr/share/kernel/$KERNEL/kernel.release)
