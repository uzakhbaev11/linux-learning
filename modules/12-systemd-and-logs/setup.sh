#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e

if [ ! -d /run/systemd/system ]; then
  echo "⚠️  Здесь нет systemd. Модуль 12 выполняется в виртуальной машине Ubuntu."
  echo "   Как её подготовить — в теории модуля, раздел «Подготовка»."
  exit 1
fi

D="$HOME/m12"
prepare_dir "$D"
mkdir -p "$D/app"

# Учебный бэкенд: маленький HTTP-сервер на Python (python3 есть в Ubuntu из коробки)
cat > "$D/app/server.py" <<'EOF'
#!/usr/bin/env python3
"""Учебный бэкенд для модуля 12.
GET /health — проверка, что сервис жив (JSON)
GET /crash  — имитация падения: процесс завершается с ошибкой
"""
import json, os, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("PORT", "8000"))
MESSAGE = os.environ.get("APP_MESSAGE", "hello")

def log(text):
    print(text, flush=True)          # всё, что пишется в stdout, systemd отправляет в журнал

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = json.dumps({"status": "ok", "message": MESSAGE}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(body + b"\n")
        elif self.path == "/crash":
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b"crashing...\n")
            log("FATAL: crash requested via /crash, exiting with code 1")
            os._exit(1)
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, fmt, *args):
        log("request: " + fmt % args)

if __name__ == "__main__":
    log(f"myapp started on port {PORT} as user {os.environ.get('USER') or os.getuid()}")
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
EOF
chmod 755 "$D/app/server.py"

# Настройки приложения: systemd прочитает их через EnvironmentFile
cat > "$D/app/.env" <<'EOF'
PORT=8000
APP_MESSAGE=hello
EOF
chmod 600 "$D/app/.env"

# Заготовка unit-файла: ??? нужно заменить
cat > "$D/myapp.service" <<EOF
[Unit]
Description=My backend app (module 12)
After=network.target

[Service]
User=???
WorkingDirectory=$D/app
EnvironmentFile=$D/app/.env
ExecStart=/usr/bin/python3 ???
Restart=???
RestartSec=2

[Install]
WantedBy=???
EOF

echo "✅ Модуль 12 подготовлен: $D"
echo "Задания: lab tasks 12"
