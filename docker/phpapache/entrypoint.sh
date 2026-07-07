#!/bin/bash
set -e
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting PHP-Apache entrypoint script..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Script PID: $$"
#
# Debug: Print environment variables from dev.phpapache.env
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== ENVIRONMENT VARIABLES DEBUG ====="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_IMAGE_NAME=${HTTP_IMAGE_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_DOCKERFILE=${HTTP_DOCKERFILE:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_CONTAINER_NAME=${HTTP_CONTAINER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_SERVER_NAME=${HTTP_SERVER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_SERVER_PORT=${HTTP_SERVER_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_LOCAL_ROOT_PATH=${HTTP_LOCAL_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_SERVER_ROOT_PATH=${HTTP_SERVER_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_LOCAL_INFO_PATH=${HTTP_LOCAL_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_SERVER_INFO_PATH=${HTTP_SERVER_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_LOCAL_LOG_PATH=${HTTP_LOCAL_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_SERVER_LOG_PATH=${HTTP_SERVER_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HTTP_SERVER_IP=${HTTP_SERVER_IP:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_NAME=${NETWORK_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========================================"
#
# Create necessary directories
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Creating necessary directories..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: HTTP_SERVER_ROOT_PATH=${HTTP_SERVER_ROOT_PATH}"
mkdir -p "${HTTP_SERVER_ROOT_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Created ${HTTP_SERVER_ROOT_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to create ${HTTP_SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: HTTP_SERVER_LOG_PATH=${HTTP_SERVER_LOG_PATH}"
mkdir -p "${HTTP_SERVER_LOG_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Created ${HTTP_SERVER_LOG_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to create ${HTTP_SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: HTTP_SERVER_INFO_PATH=${HTTP_SERVER_INFO_PATH}"
mkdir -p "${HTTP_SERVER_INFO_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Created ${HTTP_SERVER_INFO_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to create ${HTTP_SERVER_INFO_PATH}"
#
# Set proper permissions for Apache
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Setting proper permissions for Apache..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing ownership of ${HTTP_SERVER_ROOT_PATH} to apache:apache"
chown -R apache:apache "${HTTP_SERVER_ROOT_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Ownership changed: ${HTTP_SERVER_ROOT_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to change ownership of ${HTTP_SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing ownership of ${HTTP_SERVER_LOG_PATH} to apache:apache"
chown -R apache:apache "${HTTP_SERVER_LOG_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Ownership changed: ${HTTP_SERVER_LOG_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to change ownership of ${HTTP_SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing ownership of ${HTTP_SERVER_INFO_PATH} to apache:apache"
chown -R apache:apache "${HTTP_SERVER_INFO_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Ownership changed: ${HTTP_SERVER_INFO_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to change ownership of ${HTTP_SERVER_INFO_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing permissions of ${HTTP_SERVER_ROOT_PATH} to 755"
chmod -R 755 "${HTTP_SERVER_ROOT_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Permissions set: ${HTTP_SERVER_ROOT_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to chmod ${HTTP_SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing permissions of ${HTTP_SERVER_LOG_PATH} to 755"
chmod -R 755 "${HTTP_SERVER_LOG_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Permissions set: ${HTTP_SERVER_LOG_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to chmod ${HTTP_SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing permissions of ${HTTP_SERVER_INFO_PATH} to 755"
chmod -R 755 "${HTTP_SERVER_INFO_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Permissions set: ${HTTP_SERVER_INFO_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to chmod ${HTTP_SERVER_INFO_PATH}"
#
# Start Apache in foreground
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting Apache in foreground mode..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: About to execute: httpd -D FOREGROUND"
exec httpd -D FOREGROUND