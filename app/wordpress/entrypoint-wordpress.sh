#!/bin/bash
set -e

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting WordPress entrypoint script..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Script PID: $$"
#
# Debug: Print environment variables
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== DOCKER ENVIRONMENT VARIABLES DEBUG ====="

# Variables to check (from provided config)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] IMAGE_NAME=${IMAGE_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] CONTAINER_NAME=${CONTAINER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DOCKERFILE_PATH=${DOCKERFILE_PATH:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_NAME=${SERVER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_PORT=${SERVER_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_ROOT_PATH=${LOCAL_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_ROOT_PATH=${SERVER_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_INFO_PATH=${LOCAL_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_INFO_PATH=${SERVER_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALIAS_INFO_PATH=${ALIAS_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_LOG_PATH=${LOCAL_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_LOG_PATH=${SERVER_LOG_PATH:-NOT SET}"
#echo "[$(date '+%Y-%m-%d %H:%M:%S')] IP=${SERVER_IP:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_NAME=${DB_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_USER=${DB_USER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_PASS=${DB_PASS:-NOT SET (Set for security)}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_HOST=${DB_HOST:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_NAME=${APP_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_GITHUB_URL=${APP_GITHUB_URL:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_LOCAL_PATH=${APP_LOCAL_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_COMPOSE_PATH=${APP_COMPOSE_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ENTRYPOINT_LOCAL_PATH=${APP_ENTRYPOINT_LOCAL_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ENTRYPOINT_SERVER_PATH=${APP_ENTRYPOINT_SERVER_PATH:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ADMIN_USER=${APP_ADMIN_USER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ADMIN_PASS=${APP_ADMIN_PASS:-NOT SET (Set for security)}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ADMIN_EMAIL=${APP_ADMIN_EMAIL:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ==========================================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Waiting for MySQL to be available..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Attempting to connect to ${WORDPRESS_DB_HOST}..."
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
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

    if [ $? -ne 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to download wp-cli.phar"
        exit 1
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: wp-cli.phar downloaded successfully"
    fi
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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Database: $DB_NAME"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - User: $DB_USER"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Host: $DB_HOST"
    $WP_CMD config create \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASS" \
        --dbhost="$DB_HOST" \
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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Admin User: $APP_ADMIN_USER"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Admin Email: $APP_ADMIN_EMAIL"
    
    $WP_CMD core install \
        --url="$SERVER_NAME" \
        --title="$APP_NAME" \
        --admin_user="$APP_ADMIN_USER" \
        --admin_password="$APP_ADMIN_PASS" \
        --admin_email="$APP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root && echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: WordPress installation completed" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to install WordPress"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: WordPress is already installed"
fi
#
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: WordPress ready. Starting Apache..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: About to execute: $@"

exec "$@"