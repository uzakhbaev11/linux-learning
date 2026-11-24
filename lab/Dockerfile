# Учебный Linux: Ubuntu 24.04
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Almaty \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Docker-образ Ubuntu "урезан" (нет man-страниц). unminimize возвращает их обратно.
RUN apt-get update \
 && apt-get install -y unminimize \
 && yes | unminimize \
 && apt-get install -y \
      sudo man-db manpages less nano vim tree htop file \
      curl wget iputils-ping iproute2 dnsutils procps psmisc \
      bash-completion tzdata ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Удаляем стандартного пользователя ubuntu и создаём student (пароль: student)
RUN userdel -r ubuntu 2>/dev/null; \
    useradd -m -s /bin/bash student \
 && echo 'student:student' | chpasswd \
 && usermod -aG sudo student

# Команда `lab` — помощник курса (сам скрипт лежит в примонтированной папке /course)
RUN ln -s /course/lab/lab /usr/local/bin/lab

RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /home/student/.bashrc \
 && printf '\necho "🐧 Добро пожаловать в учебный Linux! Введи: lab help"\n' >> /home/student/.bashrc

WORKDIR /home/student
CMD ["sleep", "infinity"]
