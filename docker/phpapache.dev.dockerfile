FROM alpine:latest

ARG BUILD_HTTP_APK_REQ=""  # if not defined, default to empty string

RUN apk update && apk upgrade && \
    apk --no-cache add apache2 apache2-utils apache2-proxy php php-apache2 \
    curl composer ${BUILD_HTTP_APK_REQ}

COPY ./docker/phpapache/apache/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/phpapache/apache/conf.d/*.conf /etc/apache2/conf.d/
COPY ./docker/phpapache/php/php.ini /etc/php85/
COPY ./docker/phpapache/php/conf.d/*.ini /etc/php85/conf.d/

# Script de entrada para expandir variables
COPY ./docker/phpapache/entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]