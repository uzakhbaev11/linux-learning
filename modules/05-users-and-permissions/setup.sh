#!/usr/bin/env bash
source /course/lib/check-lib.sh
set -e
D="$HOME/m05"
prepare_dir "$D"

A="$D/app"
mkdir -p "$A/logs" "$D/shared"

cat > "$A/.env" <<'EOF'
DB_HOST=127.0.0.1
DB_USER=shop
DB_PASSWORD=Sup3r-Secret-2026
JWT_SECRET=7f3a9c1e5b
EOF

cat > "$A/deploy.sh" <<'EOF'
#!/usr/bin/env bash
echo "Deploy OK: приложение обновлено"
EOF

cat > "$A/config.yml" <<'EOF'
server:
  port: 3000
log_level: info
EOF

echo "2026-11-26 10:00:00 [INFO] app started" > "$A/logs/app.log"
echo "мастер-ключ платёжной системы: pk_live_0000" > "$D/payment.key"

# Специально плохие права — их нужно исправить
chmod 644 "$A/.env"
chmod 644 "$A/deploy.sh"
chmod 666 "$A/config.yml"
chmod 755 "$D/shared"

echo "✅ Модуль 5 подготовлен: $D"
echo "Задания: lab tasks 5"
