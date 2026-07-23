FROM alpine:latest

ARG BUILD_HTTP_APK_REQ=""

# Update and install Apache, PHP 8.4 and extensions
RUN apk update && apk upgrade && \
    apk --no-cache add \
    apache2 \
    apache2-utils \
    apache2-proxy \
    php \
    php-apache2 \   
    composer \
    curl \
    dos2unix \
    ${BUILD_HTTP_APK_REQ}

# Detectar binario real de PHP y crear symlink seguro
RUN PHP_BIN="$(ls -1 /usr/bin/php* | grep -E 'php[0-9]+' | head -n 1)" && \
    if [ -n "$PHP_BIN" ]; then \
        echo "Detected PHP binary: $PHP_BIN"; \
        rm -f /usr/bin/php; \
        ln -s "$PHP_BIN" /usr/bin/php; \
    else \
        echo "ERROR: No PHP binary found"; \
        exit 1; \
    fi


# Copy Apache configuration
COPY ./docker/phpapache/apache/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/phpapache/apache/conf.d/*.conf /etc/apache2/conf.d/

# Copy PHP configuration (use php84 directory)
COPY ./docker/phpapache/php/php.ini /etc/php84/php.ini
COPY ./docker/phpapache/php/conf.d/*.ini /etc/php84/conf.d/

# Enable Apache modules required for PHP
RUN sed -i 's|^#\(LoadModule.*mod_rewrite\)|\1|' /etc/apache2/httpd.conf && \
    sed -i 's|^#\(LoadModule.*mod_proxy\)|\1|' /etc/apache2/httpd.conf && \
    sed -i 's|^#\(LoadModule.*mod_proxy_http\)|\1|' /etc/apache2/httpd.conf

# Copy and prepare entrypoint script
COPY ./docker/phpapache/entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
