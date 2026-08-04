FROM alpine:3.21

ARG BUILD_HTTP_APK_REQ=""

# Update and install Apache, PHP 8.4 and extensions
RUN apk update && apk upgrade && apk --no-cache add apache2 apache2-utils apache2-proxy php php-apache2 curl dos2unix ${BUILD_HTTP_APK_REQ}

COPY ./docker/phpapache/apache/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/phpapache/apache/conf.d/*.conf /etc/apache2/conf.d/

# Copy PHP configuration files into temporary location
COPY ./docker/phpapache/php/php.ini /tmp/php.ini
COPY ./docker/phpapache/php/conf.d/*.ini /tmp/conf.d/

# Detectar carpeta real de configuración de PHP
RUN echo "Detecting PHP configuration directory: $(php --ini | grep 'Configuration File' | awk '{print $NF}')" && \
    PHP_INI_DIR="$(php --ini | grep 'Configuration File' | awk '{print $NF}')" && \
    echo "PHP config dir detected: $PHP_INI_DIR" && \
    mkdir -p "$PHP_INI_DIR/conf.d" && \
    echo "Copying PHP configuration files to $PHP_INI_DIR" && \
    mv -f /tmp/php.ini "$PHP_INI_DIR/php.ini" && \
    mv -f /tmp/conf.d/*.ini "$PHP_INI_DIR/conf.d/"

# Copy and prepare entrypoint script
COPY ./docker/phpapache/entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
