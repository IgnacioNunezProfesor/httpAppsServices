#!/bin/bash
# Create necessary directories
mkdir -p "${SERVER_ROOT_PATH}"
mkdir -p "${SERVER_LOG_PATH}"
mkdir -p "${SERVER_INFO_PATH}"
# Set proper permissions for Apache
chown -R apache:apache "${SERVER_ROOT_PATH}"
chown -R apache:apache "${SERVER_LOG_PATH}"
chown -R apache:apache "${SERVER_INFO_PATH}"
chmod -R 755 "${SERVER_ROOT_PATH}"
chmod -R 755 "${SERVER_LOG_PATH}"
chmod -R 755 "${SERVER_INFO_PATH}"
# Start Apache in foreground
httpd -D FOREGROUND