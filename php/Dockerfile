FROM php:8.5-fpm

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN apt-get update && apt-get install -y --no-install-recommends git unzip msmtp-mta default-mysql-client \
 && rm -rf /var/lib/apt/lists/* \
 && install-php-extensions bcmath gd intl pdo_mysql soap sockets xsl zip ftp opcache

COPY php.ini /usr/local/etc/php/conf.d/zz-magento.ini
RUN printf 'account default\nhost mailpit\nport 1025\nfrom magento@localhost\n' > /etc/msmtprc \
 && mkdir -p /var/www/.composer && chown -R www-data:www-data /var/www

USER www-data
