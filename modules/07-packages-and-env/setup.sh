#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m07"
prepare_dir "$D"

cat > "$D/config.json" <<'JSON'
{
  "app": "shop-api",
  "version": "2.4.1",
  "db": { "host": "db.internal", "port": 5432 },
  "features": ["payments", "search", "cart"]
}
JSON

cat > "$D/start.sh" <<'SH'
#!/usr/bin/env bash
# «Приложение»: берёт настройки из переменных окружения, как настоящий бэкенд
: "${APP_PORT:?не задана переменная APP_PORT (загрузи .env)}"
: "${DB_PASSWORD:?не задана переменная DB_PASSWORD (загрузи .env)}"
echo "shop-api запущен на порту $APP_PORT (пароль БД: ${#DB_PASSWORD} символов)"
SH
chmod +x "$D/start.sh"

echo "✅ Модуль 7 подготовлен: $D"
echo "Задания: lab tasks 7"
