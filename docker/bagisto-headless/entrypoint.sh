#!/bin/bash

set -e

APP_DIR="/var/www/bagisto"

log() {
    echo "[bagisto-entrypoint] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

cd "$APP_DIR"

log "Starting Bagisto application container..."

# --------------------------------------------------------------------------
# Runtime environment
# --------------------------------------------------------------------------

DB_HOST="${DB_HOST:-mysql}"
DB_PORT="${DB_PORT:-3306}"
DB_DATABASE="${DB_DATABASE:-bagisto}"
DB_USERNAME="${DB_USERNAME:-bagisto}"
DB_PASSWORD="${DB_PASSWORD:-bagisto}"

APP_URL="${APP_URL:-http://localhost:8082}"

log "Database host: ${DB_HOST}:${DB_PORT}"
log "Database name: ${DB_DATABASE}"

# --------------------------------------------------------------------------
# Update runtime database configuration
# --------------------------------------------------------------------------

sed -i "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" .env
sed -i "s/^DB_PORT=.*/DB_PORT=${DB_PORT}/" .env
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" .env
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env
sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" .env

if [ -n "${APP_KEY}" ]; then
    sed -i "s|^APP_KEY=.*|APP_KEY=${APP_KEY}|" .env
fi

# --------------------------------------------------------------------------
# Wait for MySQL
# --------------------------------------------------------------------------

log "Waiting for MySQL at ${DB_HOST}:${DB_PORT}..."

for i in $(seq 1 60); do

    if php -r "
        try {
            new PDO(
                'mysql:host=${DB_HOST};port=${DB_PORT};dbname=${DB_DATABASE}',
                '${DB_USERNAME}',
                '${DB_PASSWORD}'
            );
            exit(0);
        } catch (Exception \$e) {
            exit(1);
        }
    " 2>/dev/null; then

        log "MySQL connection successful."
        break
    fi

    if [ "$i" -eq 60 ]; then
        log "ERROR: MySQL was not reachable after 60 seconds."
        exit 1
    fi

    sleep 1
done

# --------------------------------------------------------------------------
# Clear Laravel cached configuration
# --------------------------------------------------------------------------

log "Clearing Laravel caches..."

php artisan optimize:clear --no-interaction || true

# --------------------------------------------------------------------------
# Rebuild Laravel configuration
# --------------------------------------------------------------------------

log "Caching Laravel configuration..."

php artisan config:cache --no-interaction || true

# --------------------------------------------------------------------------
# Permissions
# --------------------------------------------------------------------------

chown -R www-data:www-data \
    storage \
    bootstrap/cache

chmod -R 775 \
    storage \
    bootstrap/cache

log "Bagisto application initialization complete."

# --------------------------------------------------------------------------
# Start Supervisor
# --------------------------------------------------------------------------

exec "$@"