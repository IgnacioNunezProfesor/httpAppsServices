#!/bin/bash
set -e

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting WordPress entrypoint script..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Script PID: $$"
#
# Debug: Print environment variables
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== DOCKER ENVIRONMENT VARIABLES DEBUG ====="

# Variables to check (from provided config)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_IMAGE_NAME=${HTTP_IMAGE_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_CONTAINER_NAME=${HTTP_CONTAINER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_DOCKERFILE_PATH=${HTTP_DOCKERFILE_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] BUILD_HTTP_APK_REQ=${BUILD_HTTP_APK_REQ:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_NAME=${HTTP_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_PORT=${HTTP_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_LOCAL_ROOT_PATH=${HTTP_LOCAL_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_SERVER_ROOT_PATH=${HTTP_SERVER_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_LOCAL_INFO_PATH=${HTTP_LOCAL_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_SERVER_INFO_PATH=${HTTP_SERVER_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_ALIAS_INFO_PATH=${HTTP_ALIAS_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_LOCAL_LOG_PATH=${HTTP_LOCAL_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_SERVER_LOG_PATH=${HTTP_SERVER_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_IP=${HTTP_IP:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_CONTAINER_NAME=${DB_CONTAINER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_DOCKERFILE_PATH=${DB_DOCKERFILE_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_IMAGE_NAME=${DB_IMAGE_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_SERVER_ID=${DB_SERVER_ID:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_SERVER_PORT=${DB_SERVER_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_LOCAL_PORT=${DB_LOCAL_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_SERVER_DATA_DIR=${DB_SERVER_DATA_DIR:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_LOCAL_DATA_DIR=${DB_LOCAL_DATA_DIR:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_SERVER_LOG=${DB_SERVER_LOG:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_LOCAL_LOG_PATH=${DB_LOCAL_LOG_PATH:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_NAME=${DB_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_USER=${DB_USER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_PASS=${DB_PASS:-NOT SET (Set for security)}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_IP=${DB_IP:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_DRIVER=${NETWORK_DRIVER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_NAME=${NETWORK_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_SUBNET=${NETWORK_SUBNET:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_SUBNET_GATEWAY=${NETWORK_SUBNET_GATEWAY:-NOT SET}"

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