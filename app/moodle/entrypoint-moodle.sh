#!/bin/bash
set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /var/log/apache2/entrypoint-moodle.log
}

log "===== MOODLE UNATTENDED INSTALLER ====="
log "Starting entrypoint for ${APP_NAME:-Moodle}"
log "DEBUG: Script PID: $$"

# -----------------------------------------------------------------------------
# 1. VALIDAR VARIABLES DE ENTORNO
# -----------------------------------------------------------------------------
required_vars="
DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASS
SERVER_NAME
SERVER_PORT
SERVER_ROOT_PATH
SERVER_DATA_PATH
APP_ADMIN_USER
APP_ADMIN_PASS
APP_ADMIN_EMAIL
"

for var in $required_vars; do
    eval "value=\${$var}"
    if [ -z "$value" ]; then
        log "ERROR: Required environment variable '$var' is missing or empty."
        exit 1
    else
        log "INFO: Environment variable '$var' is set to '$value'."
    fi
done

log "All required environment variables are present."

# -----------------------------------------------------------------------------
# 2. CREAR DIRECTORIO moodledata
# -----------------------------------------------------------------------------
if [ ! -d "$SERVER_DATA_PATH" ]; then
    log "Creating Moodle data directory at ${SERVER_DATA_PATH}..."
    mkdir -p "$SERVER_DATA_PATH"
fi

log "Applying folder permissions..."

web_user="apache"
if ! id "$web_user" >/dev/null 2>&1; then
    web_user="www-data"
fi

chown -R ${web_user}:${web_user} "${SERVER_ROOT_PATH}"
chown -R ${web_user}:${web_user} "${SERVER_DATA_PATH}"

chmod -R 750 "${SERVER_ROOT_PATH}"
chmod -R 770 "${SERVER_DATA_PATH}"

log "Permissions successfully applied for user ${web_user}."

# -----------------------------------------------------------------------------
# 3. VALIDAR REQUISITOS CON COMPOSER
# -----------------------------------------------------------------------------
if [ -f "${SERVER_ROOT_PATH}/composer.json" ]; then
    if command -v composer >/dev/null 2>&1; then
        log "Checking Composer platform requirements..."
        (
            cd "${SERVER_ROOT_PATH}" || exit 1
            composer check-platform-reqs --no-interaction
        ) || {
            log "ERROR: Composer platform requirements check failed."
            exit 1
        }

        log "Installing Composer dependencies..."
        (
            cd "${SERVER_ROOT_PATH}" || exit 1
            composer install --no-interaction --prefer-dist --no-progress
        ) || {
            log "ERROR: Composer install failed."
            exit 1
        }

        log "Optimizing Composer autoload..."
        (
            cd "${SERVER_ROOT_PATH}" || exit 1
            composer dump-autoload --optimize
        )
    else
        log "WARNING: composer command not found. Skipping Composer checks."
    fi
else
    log "No composer.json found in ${SERVER_ROOT_PATH}. Skipping Composer tasks."
fi

# -----------------------------------------------------------------------------
# 4. INSTALACIÓN DESATENDIDA DE MOODLE
# -----------------------------------------------------------------------------
log "Checking/Installing Moodle with unattended CLI installer..."

if [ "${LOCAL_PORT}" = "80" ] || [ "${LOCAL_PORT}" = "443" ]; then
    wwwroot_url="http://${SERVER_NAME}"
else
    wwwroot_url="http://${SERVER_NAME}:${LOCAL_PORT}"
fi

log "INFO: Moodle wwwroot URL: ${wwwroot_url}"

log "Running Moodle CLI installer..."

php /var/www/php-info/php-info.php

set -- \
    php \
    "${SERVER_ROOT_PATH}/admin/cli/install.php" \
    --non-interactive \
    --agree-license \
    --chmod=0777 \
    --lang=es \
    --wwwroot="${wwwroot_url}" \
    --dataroot="${SERVER_DATA_PATH}" \
    --dbtype=mariadb \
    --dbhost="${DB_HOST}" \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASS}" \
    --dbport="${DB_PORT}" \
    --prefix=mdl_ \
    --fullname="${APP_NAME}" \
    --shortname="${APP_NAME}" \
    --summary="${APP_NAME} Moodle site" \
    --adminuser="${APP_ADMIN_USER}" \
    --adminpass="${APP_ADMIN_PASS}" \
    --adminemail="${APP_ADMIN_EMAIL}"

install_cmd_display=""
for arg in "$@"; do
    install_cmd_display="${install_cmd_display}${arg} "
done
log "Command: ${install_cmd_display}"

install_log="$(mktemp)"
if "$@" >"$install_log" 2>&1; then
    log "Moodle installation completed successfully."
else
    install_status=$?
    if grep -qiE "already installed|already exists|already configured|site already exists" "$install_log"; then
        log "Moodle is already installed. Continuing startup..."
        cat "$install_log" >&2
    else
        log "ERROR: Moodle installer failed. Showing errors:"
        cat "$install_log" >&2
        rm -f "$install_log"
        exit "$install_status"
    fi
fi
rm -f "$install_log"

# -----------------------------------------------------------------------------
# 5. PURGAR CACHES Y REGENERAR AUTOLOAD DE MOODLE
# -----------------------------------------------------------------------------
log "Purging Moodle caches..."
php "${SERVER_ROOT_PATH}/admin/cli/purge_caches.php" || log "WARNING: Cache purge failed."

# -----------------------------------------------------------------------------
# 6. RESETEAR OPCACHE (si existe)
# -----------------------------------------------------------------------------
if php -r "echo function_exists('opcache_reset');"; then
    log "Resetting OPcache..."
    php -r "opcache_reset();"
else
    log "OPcache not enabled or not available."
fi



# -----------------------------------------------------------------------------
# 8. ARRANCAR APACHE
# -----------------------------------------------------------------------------
log "Starting Apache web server..."

if command -v httpd >/dev/null 2>&1; then
    exec httpd -D FOREGROUND
elif command -v apache2-foreground >/dev/null 2>&1; then
    exec apache2-foreground
else
    exec apache2 -D FOREGROUND
fi
