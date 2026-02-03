FROM alpine:latest

ENV SERVER_NAME=${SERVER_NAME}
ENV SERVER_PORT=${SERVER_PORT}
ENV SERVER_ROOT_PATH=${SERVER_ROOT_PATH}
ENV SERVER_LOG_PATH=${SERVER_LOG_PATH}
ENV SERVER_INFO_PATH=${SERVER_INFO_PATH}

EXPOSE ${SERVER_PORT}

RUN apk update && apk upgrade && \
    apk --no-cache add apache2 apache2-utils apache2-proxy php php-apache2 \
    php-curl php-gd php-mbstring php-intl php-mysqli php-xml php-zip \
    php-ctype php-dom php-iconv php-simplexml php-openssl php-sodium php-tokenizer php-xdebug \
    php-xmlreader php-fileinfo php-xmlwriter phpunit php-pear curl composer

COPY ./docker/phpapache/apache/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/phpapache/apache/conf.d/*.conf /etc/apache2/conf.d/
COPY ./docker/phpapache/php/php.ini /etc/php84/
COPY ./docker/phpapache/php/conf.d/*.ini /etc/php84/conf.d/

# Script de entrada para expandir variables
COPY ./docker/phpapache/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]