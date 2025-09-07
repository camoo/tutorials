# Start from official WordPress with Apache + PHP 8.3
FROM wordpress:6.6-php8.3-apache

ARG UID=1000
ARG GID=1000

# Create user/group matching host IDs
RUN groupadd -g "$GID" camoo \
 && useradd -m -u "$UID" -g "$GID" -c "Camoo User" camoo

# Install tools + PHP extensions
RUN apt-get update && apt-get install -y \
    procps \
    less \
    vim \
    git \
    unzip \
 && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-install mysqli \
 && docker-php-ext-enable mysqli

# Install Xdebug (disabled by default, enable with env vars)
RUN pecl install xdebug \
 && docker-php-ext-enable xdebug

# Enable Apache rewrite for WP permalinks
RUN a2enmod rewrite

# Install WP-CLI (latest)
RUN curl -o /usr/local/bin/wp -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp


# Redirect Apache logs to Docker logs (stdout/stderr) if not already done
# RUN ln -sf /dev/stdout /var/log/apache2/access.log \
# && ln -sf /dev/stderr /var/log/apache2/error.log

WORKDIR /var/www/html

USER camoo
