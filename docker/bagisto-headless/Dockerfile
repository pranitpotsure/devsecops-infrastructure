# =============================================================================
# Bagisto Application Image
# Bagisto 2.4.7
#
# Contains:
#   - Ubuntu 24.04
#   - PHP 8.3
#   - PHP-FPM
#   - Nginx
#   - Supervisor
#   - Bagisto application
#
# Does NOT contain:
#   - MySQL
#   - Redis
#   - Elasticsearch
#
# Database is provided externally through:
#   DB_HOST=mysql
# =============================================================================

FROM ubuntu:24.04

ARG PHP_VERSION=8.3

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# -----------------------------------------------------------------------------
# System packages
# -----------------------------------------------------------------------------

RUN apt-get update && apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        git \
        gnupg \
        nano \
        software-properties-common \
        unzip \
        nginx \
        supervisor \
    && add-apt-repository ppa:ondrej/php -y \
    && apt-get update \
    && apt-get install -y \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-calendar \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-exif \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-gmp \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-sockets \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
    && rm -rf /var/lib/apt/lists/*


# -----------------------------------------------------------------------------
# Composer
# -----------------------------------------------------------------------------

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer


# -----------------------------------------------------------------------------
# Application
# -----------------------------------------------------------------------------

WORKDIR /var/www/bagisto

COPY bagisto/ /var/www/bagisto/


# -----------------------------------------------------------------------------
# PHP dependencies
# -----------------------------------------------------------------------------

RUN composer install \
        --no-dev \
        --no-interaction \
        --prefer-dist \
        --optimize-autoloader \
        --no-scripts \
    && composer dump-autoload \
        --optimize \
        --no-dev \
    && rm -rf /root/.composer/cache


# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------

RUN cp .env.example .env \
    && sed -i 's/^APP_DEBUG=.*/APP_DEBUG=false/' .env \
    && sed -i 's/^APP_URL=.*/APP_URL=http:\/\/localhost:8082/' .env \
    && sed -i 's/^DB_HOST=.*/DB_HOST=mysql/' .env \
    && sed -i 's/^DB_PORT=.*/DB_PORT=3306/' .env \
    && sed -i 's/^DB_DATABASE=.*/DB_DATABASE=bagisto/' .env \
    && sed -i 's/^DB_USERNAME=.*/DB_USERNAME=bagisto/' .env \
    && sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=bagisto/' .env


# -----------------------------------------------------------------------------
# PHP configuration
# -----------------------------------------------------------------------------

COPY bagisto/docker/production/shared/php.ini \
    /etc/php/${PHP_VERSION}/fpm/conf.d/99-production.ini

COPY bagisto/docker/production/shared/php.ini \
    /etc/php/${PHP_VERSION}/cli/conf.d/99-production.ini


# -----------------------------------------------------------------------------
# PHP-FPM configuration
# -----------------------------------------------------------------------------

COPY bagisto/docker/production/nginx/config/php-fpm.conf \
    /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf


# -----------------------------------------------------------------------------
# Nginx configuration
# -----------------------------------------------------------------------------

RUN rm -f /etc/nginx/sites-enabled/default \
           /etc/nginx/sites-available/default

COPY bagisto/docker/production/nginx/config/nginx.conf \
    /etc/nginx/conf.d/bagisto.conf


# -----------------------------------------------------------------------------
# Supervisor configuration
# -----------------------------------------------------------------------------

COPY infrastructure/docker/bagisto-headless/supervisord.conf \
    /etc/supervisor/conf.d/bagisto.conf


# -----------------------------------------------------------------------------
# Entrypoint
# -----------------------------------------------------------------------------

COPY infrastructure/docker/bagisto-headless/entrypoint.sh \
    /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh


# -----------------------------------------------------------------------------
# Runtime directories and permissions
# -----------------------------------------------------------------------------

RUN mkdir -p \
        /var/log/supervisor \
        /var/log/bagisto \
        /run/php \
    && chown -R www-data:www-data \
        /var/www/bagisto/storage \
        /var/www/bagisto/bootstrap/cache \
    && chmod -R 775 \
        /var/www/bagisto/storage \
        /var/www/bagisto/bootstrap/cache


# -----------------------------------------------------------------------------
# Nginx runs in foreground
# -----------------------------------------------------------------------------

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]