#!/bin/bash
set -e
#
# Create necessary directories
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Creating necessary directories..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: SERVER_ROOT_PATH=${SERVER_ROOT_PATH}"
mkdir -p "${SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Directory created: ${SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: SERVER_LOG_PATH=${SERVER_LOG_PATH}"
mkdir -p "${SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Directory created: ${SERVER_LOG_PATH}"
#
# Set proper permissions for Apache
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Setting proper permissions for Apache..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing ownership of ${SERVER_ROOT_PATH} to apache:apache"
chown -R apache:apache "${SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Ownership changed: ${SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing ownership of ${SERVER_LOG_PATH} to apache:apache"
chown -R apache:apache "${SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Ownership changed: ${SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing permissions of ${SERVER_ROOT_PATH} to 755"
chmod -R 755 "${SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Permissions set: ${SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing permissions of ${SERVER_LOG_PATH} to 755"
chmod -R 755 "${SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Permissions set: ${SERVER_LOG_PATH}"
#
# Start Apache in foreground
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting Apache in foreground mode..."
httpd -D FOREGROUND