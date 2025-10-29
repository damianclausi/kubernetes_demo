# Dockerfile
FROM php:fpm-alpine
RUN mkdir -p /var/www/html
COPY --chown=nobody src/ /var/www/html/
WORKDIR /var/www/html
CMD ["php", "-S", "0.0.0.0:80", "-t", "/var/www/html/"]