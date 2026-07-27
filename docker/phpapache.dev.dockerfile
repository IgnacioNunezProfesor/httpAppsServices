FROM alpine:latest

ARG BUILD_HTTP_APK_REQ=""

# Update and install Apache, PHP 8.4 and extensions
RUN apk update && apk upgrade && apk --no-cache add apache2 apache2-utils apache2-proxy php php-apache2 curl dos2unix ${BUILD_HTTP_APK_REQ}

COPY ./docker/phpapache/apache/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/phpapache/apache/conf.d/*.conf /etc/apache2/conf.d/

# Copy PHP configuration files into temporary location
COPY ./docker/phpapache/php/php.ini /etc/php/php.ini
COPY ./docker/phpapache/php/conf.d/*.ini /etc/php/conf.d/

# Copy and prepare entrypoint script
COPY ./docker/phpapache/entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
