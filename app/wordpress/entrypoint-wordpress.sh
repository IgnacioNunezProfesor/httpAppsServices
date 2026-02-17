#!/bin/bash
set -e

echo "Esperando a que MySQL esté disponible..."
until mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent; do
    sleep 2
done

cd /var/www/html

# Si no existe wp-config.php, lo generamos
if [ ! -f wp-config.php ]; then
    echo "Generando wp-config.php..."
    wp config create \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASS" \
        --dbhost="$DB_CONTAINER_NAME" \
        --skip-check \
        --allow-root
fi

# Instalación desatendida
if ! wp core is-installed --allow-root; then
    echo "Instalando WordPress de forma desatendida..."

    wp core install \
        --url="$HTTP_NAME" \
        --title="$APP_NAME" \
        --admin_user="$APP_WP_ADMIN_USER" \
        --admin_password="$APP_WP_ADMIN_PASS" \
        --admin_email="$APP_WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
fi

echo "WordPress listo. Arrancando Apache..."
exec "$@"
