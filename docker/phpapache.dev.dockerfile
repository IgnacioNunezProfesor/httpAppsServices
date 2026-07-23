FROM alpine:3.20

ARG BUILD_APK_REQ=""

# Update and install Apache, PHP 8.4 and extensions
RUN apk update && apk upgrade && \
    apk --no-cache add \
    apache2 \
    apache2-utils \
    apache2-proxy \
    php84 \
    php84-apache2 \   
    composer \
    curl \
    dos2unix \
    ${BUILD_HTTP_APK_REQ}

# Create symlink to make php command available (for compatibility)
RUN ln -s /usr/bin/php84 /usr/bin/php

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

# Verify PHP installation
RUN php -v && \
    php -m | grep -i mysqli && \
    echo "PHP 8.4 modules loaded successfully"

ENTRYPOINT ["sh", "/entrypoint.sh"]
