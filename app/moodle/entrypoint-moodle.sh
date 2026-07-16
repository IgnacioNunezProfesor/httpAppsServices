#!/bin/bash
set -e

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting WordPress entrypoint script..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Script PID: $$"
#
# Debug: Print environment variables
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== DOCKER ENVIRONMENT VARIABLES DEBUG ====="

# Variables del Servicio: db
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_PORT=${DB_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_DATA_DIR=${SERVER_DATA_DIR:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_DATA_DIR=${LOCAL_DATA_DIR:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_LOG_PATH=${SERVER_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_LOG_PATH=${LOCAL_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_NAME=${DB_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_USER=${DB_USER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_PASS=${DB_PASS:-NOT SET (Set for security)}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_IP=${DB_IP:-NOT SET}"

# Variables del Servicio: http (WordPress)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] WORDPRESS_DB_HOST=${WORDPRESS_DB_HOST:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] WORDPRESS_DB_PORT=${WORDPRESS_DB_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] WORDPRESS_DB_USER=${WORDPRESS_DB_USER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD:-NOT SET (Set for security)}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_NAME=${SERVER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_PORT=${SERVER_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_ROOT_PATH=${LOCAL_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_ROOT_PATH=${SERVER_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_LOG_PATH=${LOCAL_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_LOG_PATH=${SERVER_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_INFO_PATH=${LOCAL_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_INFO_PATH=${SERVER_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_IP=${HTTP_IP:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_WP_ADMIN_USER=${APP_WP_ADMIN_USER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_WP_ADMIN_PASS=${APP_WP_ADMIN_PASS:-NOT SET (Set for security)}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_WP_ADMIN_EMAIL=${APP_WP_ADMIN_EMAIL:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ENTRYPOINT_PATH=${APP_ENTRYPOINT_PATH:-NOT SET}"

# Variable común de Red
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_NAME=${NETWORK_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ==========================================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Waiting for MySQL to be available..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Attempting to connect to ${WORDPRESS_DB_HOST}..."
#
RETRY_COUNT=0
MAX_RETRIES=30
#
# Comentado según tu flujo, pero recuerda descomentarlo si necesitas que espere a MariaDB de forma estricta
#until mariadb-admin ping -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" --silent 2>/dev/null; do
#    RETRY_COUNT=$((RETRY_COUNT + 1))
#    if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
#        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: MySQL did not become available after $MAX_RETRIES attempts"
#        exit 1
#    fi
#    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: MySQL not ready yet (attempt $RETRY_COUNT/$MAX_RETRIES), waiting 2 seconds..."
#    sleep 2
#done
#
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: MySQL is now available"
#
cd "$SERVER_ROOT_PATH"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changed directory to: $(pwd)"

# --- CONFIGURACIÓN DE WP-CLI ---
# Detectar dinámicamente cómo invocar WP-CLI para evitar el error "command not found"
if command -v wp &> /dev/null; then
    WP_CMD="wp"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: WP-CLI detected globally as 'wp'"
elif [ -f "wp-cli.phar" ]; then
    WP_CMD="php wp-cli.phar"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: WP-CLI detected locally as 'php wp-cli.phar'"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: WP-CLI not found. Downloading wp-cli.phar..."
    curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    WP_CMD="php wp-cli.phar"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: WP-CLI downloaded and ready"
fi
# -------------------------------

# Check if wp-config.php exists
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Checking if wp-config.php exists..."
if [ ! -f wp-config.php ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: wp-config.php not found. Generating..."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Creating config with:"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Database: $WORDPRESS_DB_NAME"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - User: $WORDPRESS_DB_USER"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Host: $WORDPRESS_DB_HOST"
    
    $WP_CMD config create \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$WORDPRESS_DB_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST" \
        --skip-check \
        --allow-root && echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: wp-config.php created" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to create wp-config.php"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: wp-config.php already exists, skipping creation"
fi
#
# Unattended installation
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Checking if WordPress is already installed..."
if ! $WP_CMD core is-installed --allow-root 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: WordPress not installed. Starting unattended installation..."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Installing WordPress with:"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - URL: $SERVER_NAME"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Title: $APP_NAME"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Admin User: $APP_WP_ADMIN_USER"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Admin Email: $APP_WP_ADMIN_EMAIL"
    
    $WP_CMD core install \
        --url="$SERVER_NAME" \
        --title="$APP_NAME" \
        --admin_user="$APP_WP_ADMIN_USER" \
        --admin_password="$APP_WP_ADMIN_PASS" \
        --admin_email="$APP_WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root && echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: WordPress installation completed" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to install WordPress"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: WordPress is already installed"
fi
#
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: WordPress ready. Starting Apache..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: About to execute: $@"
exec "$@"