# Multi-stage build for minimal image size
FROM php:8.3-fpm-alpine AS base

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-install pdo pdo_mysql zip gd

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Builder stage
FROM base AS builder

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY . .
RUN composer dump-autoload --optimize --no-dev

# Production stage
FROM php:8.3-fpm-alpine

# Install only runtime dependencies
RUN apk add --no-cache \
    libpng \
    libzip \
    && docker-php-ext-install pdo pdo_mysql zip gd opcache

# Create non-root user
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

WORKDIR /var/www/html

# Copy application from builder
COPY --from=builder --chown=appuser:appuser /var/www/html /var/www/html

# Set proper permissions
RUN chown -R appuser:appuser /var/www/html/storage /var/www/html/bootstrap/cache

# Switch to non-root user
USER appuser

EXPOSE 9000

CMD ["php-fpm"]
