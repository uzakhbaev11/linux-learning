# Модуль 12. systemd и логи

> ⏱ ~2–3 занятия по часу. **Этот модуль выполняется в настоящей виртуальной машине Ubuntu**, а не в браузере.

Ты написал бэкенд и запустил его командой `python3 server.py`. Работает! Но:
- закрыл терминал — приложение умерло;
- сервер перезагрузился — приложение не поднялось;
- приложение упало ночью — никто не перезапустил;
- где смотреть, что оно писало перед падением?

Все эти задачи решает **systemd** — главный процесс Linux (PID 1), который запускает и сторожит все службы.
На Ubuntu, Debian, CentOS и почти любом VPS сервисы управляются именно им.

## Подготовка: виртуальная машина Ubuntu

В браузерном Linux нет systemd, поэтому нужен настоящий Linux. Проще всего взять **Multipass**:
это бесплатная программа от создателей Ubuntu, которая за минуту поднимает виртуальную машину на Mac.

В терминале **Mac**:
```bash
brew install --cask multipass        # один раз
multipass launch 24.04 --name lab    # создать ВМ с Ubuntu 24.04 (~1–2 минуты)
multipass shell lab                  # войти в неё
```

Уже **внутри ВМ** установи команду `lab`:
```bash
curl -fsSL https://raw.githubusercontent.com/uzakhbaev11/linux-learning/main/lab/install-vm.sh | bash
lab setup 12
```

Дальше всё как обычно: задания на сайте, проверка — `lab check 12` в ВМ.

```bash
multipass stop lab      # выключить ВМ (файлы сохранятся)
multipass start lab     # включить снова
multipass list          # список ВМ
```

> 💡 Это та же ВМ, что пригодится в итоговом проекте. Пароль для `sudo` в Multipass не нужен.

## Сервис и unit-файл

**Сервис (service)** — программа, которой управляет systemd. Описывается **unit-файлом**:

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My backend app
After=network.target              # запускать после того, как поднялась сеть

[Service]
User=ubuntu                       # от какого пользователя (НЕ root!)
WorkingDirectory=/home/ubuntu/app
EnvironmentFile=/home/ubuntu/app/.env   # переменные окружения из файла
ExecStart=/usr/bin/python3 /home/ubuntu/app/server.py   # ПОЛНЫЙ путь к программе
Restart=on-failure                # упало с ошибкой → перезапустить
RestartSec=2                      # через 2 секунды

[Install]
WantedBy=multi-user.target        # «запускать при обычной загрузке системы»
```

Свои unit-файлы кладут в `/etc/systemd/system/`. Системные живут в `/lib/systemd/system/` — их не трогаем.

`Restart=`: `no` (по умолчанию), `on-failure` (только при ошибке), `always` (всегда, даже после нормального выхода).

## systemctl: пульт управления

```bash
sudo systemctl daemon-reload        # перечитать unit-файлы (ПОСЛЕ КАЖДОГО изменения!)
sudo systemctl start myapp          # запустить сейчас
sudo systemctl stop myapp           # остановить
sudo systemctl restart myapp        # перезапустить (например, после изменения .env)
systemctl status myapp              # состояние, PID, последние строки лога
sudo systemctl enable myapp         # включить АВТОЗАПУСК при загрузке
sudo systemctl enable --now myapp   # включить автозапуск и сразу запустить
sudo systemctl disable myapp        # выключить автозапуск
systemctl is-active myapp           # active / inactive / failed
systemctl is-enabled myapp          # enabled / disabled
systemctl list-units --type=service --state=running   # что сейчас работает
systemctl --failed                  # что упало
```

⚠️ Главная путаница новичков: **`start` ≠ `enable`**.
`start` — запустить прямо сейчас. `enable` — запускать при каждой загрузке. Обычно нужны оба.

### Читаем `systemctl status`
```
● myapp.service - My backend app
     Loaded: loaded (/etc/systemd/system/myapp.service; enabled)   ← файл найден, автозапуск включён
     Active: active (running) since Fri 2026-11-27 10:00:00 UTC    ← работает
   Main PID: 1234 (python3)
     Memory: 9.8M
Nov 27 10:00:00 lab python3[1234]: myapp started on port 8000     ← последние строки лога
```
`Active: failed` — смотри логи, причина почти всегда там.

## Логи: journalctl

systemd собирает всё, что сервис печатает в stdout и stderr, в **журнал (journal)**.
Не нужно настраивать файлы логов — просто пиши в консоль.

```bash
journalctl -u myapp                 # все логи сервиса (листается как less)
journalctl -u myapp -f              # следить в реальном времени (как tail -f)
journalctl -u myapp -n 50           # последние 50 строк
journalctl -u myapp --since "10 min ago"
journalctl -u myapp --since today
journalctl -u myapp -p err          # только ошибки
journalctl -u myapp --no-pager      # вывести без листалки (для > и |)
journalctl -b                       # всё с момента последней загрузки
journalctl -xe                      # последние события с пояснениями
```

Чтобы смотреть журнал без `sudo`, пользователь должен быть в группе `adm` или `systemd-journal`
(в Multipass пользователь `ubuntu` уже там).

## 💼 В реальной работе

Типичный деплой бэкенда на VPS выглядит так:
1. Код приезжает на сервер (`git pull` или CI).
2. Unit-файл `myapp.service` с `Restart=on-failure` и `User=` отдельного пользователя.
3. `sudo systemctl enable --now myapp`. Приложение работает и переживает перезагрузку.
4. Перед приложением стоит Nginx (принимает 80/443 и передаёт на порт приложения).
5. Что-то сломалось → `systemctl status myapp` → `journalctl -u myapp -n 100`.

Ночью приложение упало из-за ошибки? systemd поднимет его через 2 секунды, а в `journalctl` останется
след: что случилось и когда. Утром ты читаешь лог, а не узнаёшь о падении от пользователей.

Docker и Kubernetes решают ту же задачу (перезапуск, логи) похожими идеями: `restart: always`
в docker-compose — это прямой родственник `Restart=always`.

---

👉 Задания: `lab tasks 12`
