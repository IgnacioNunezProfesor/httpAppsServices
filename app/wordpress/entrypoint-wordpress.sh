#!/bin/bash
set -e
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting WordPress entrypoint script..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Script PID: $$"
#
# Debug: Print environment variables
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== WORDPRESS ENVIRONMENT VARIABLES DEBUG ====="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_NAME=${HTTP_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_PORT=${HTTP_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_SERVER_ROOT_PATH=${HTTP_SERVER_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_CONTAINER_NAME=${DB_CONTAINER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_NAME=${DB_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_USER=${DB_USER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_PASS=${DB_PASS:-NOT SET (Set for security)}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] WORDPRESS_DB_HOST=${WORDPRESS_DB_HOST:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_NAME=${APP_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_WP_ADMIN_USER=${APP_WP_ADMIN_USER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_WP_ADMIN_EMAIL=${APP_WP_ADMIN_EMAIL:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ==========================================="
#
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Waiting for MySQL to be available..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Attempting to connect to ${WORDPRESS_DB_HOST}..."
#
RETRY_COUNT=0
MAX_RETRIES=30
#
until mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: MySQL did not become available after $MAX_RETRIES attempts"
        exit 1
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: MySQL not ready yet (attempt $RETRY_COUNT/$MAX_RETRIES), waiting 2 seconds..."
    sleep 2
done
#
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: MySQL is now available"
#
cd /var/www/html
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changed directory to: $(pwd)"
#
# Check if wp-config.php exists
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Checking if wp-config.php exists..."
if [ ! -f wp-config.php ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: wp-config.php not found. Generating..."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Creating config with:"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Database: $DB_NAME"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - User: $DB_USER"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Host: $DB_CONTAINER_NAME"
    wp config create \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASS" \
        --dbhost="$DB_CONTAINER_NAME" \
        --skip-check \
        --allow-root && echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: wp-config.php created" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to create wp-config.php"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: wp-config.php already exists, skipping creation"
fi
#
# Unattended installation
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Checking if WordPress is already installed..."
if ! wp core is-installed --allow-root 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: WordPress not installed. Starting unattended installation..."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Installing WordPress with:"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - URL: $HTTP_NAME"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Title: $APP_NAME"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Admin User: $APP_WP_ADMIN_USER"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - Admin Email: $APP_WP_ADMIN_EMAIL"
    wp core install \
        --url="$HTTP_NAME" \
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
