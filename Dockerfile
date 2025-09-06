# Start from official WordPress with Apache + PHP 8.3
FROM wordpress:6.6-php8.3-apache

# Install useful tools (git, zip, unzip) and PHP extensions
RUN apt-get update && apt-get install -y \
    less \
    vim \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Enable recommended PHP extensions
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

# Install WP-CLI
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Set working directory
WORKDIR /var/www/html

# Optional: copy in custom php.ini (uncomment if you want this)
# COPY ./php.ini /usr/local/etc/php/

# Healthcheck (optional, good demo point)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
