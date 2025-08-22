FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
        libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip mysqli pdo pdo_mysql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY opencart/upload/ /var/www/html/

RUN if [ -f /var/www/html/config-dist.php ]; then \
        mv /var/www/html/config-dist.php /var/www/html/config.php; \
    else \
        touch /var/www/html/config.php; \
    fi && \
    if [ -f /var/www/html/admin/config-dist.php ]; then \
        mv /var/www/html/admin/config-dist.php /var/www/html/admin/config.php; \
    else \
        mkdir -p /var/www/html/admin && touch /var/www/html/admin/config.php; \
    fi

RUN mkdir -p /var/www/storage/{cache,logs,download,upload,session,backup,marketplace,vendor} \
    && chown -R www-data:www-data /var/www/storage \
    && chmod -R 755 /var/www/storage \
    \
    && chown -R www-data:www-data /var/www/html \
    && chmod 0666 /var/www/html/config.php /var/www/html/admin/config.php \
    && chmod -R 0755 /var/www/html \
    \
    && mkdir -p /var/www/html/system/storage/{logs,cache,download,upload} \
    && chmod -R 0777 /var/www/html/system/storage/{logs,cache,download,upload}


EXPOSE 80

CMD ["apache2-foreground"]