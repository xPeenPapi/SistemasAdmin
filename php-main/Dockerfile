# Usa la imagen oficial de PHP con Apache
FROM php:8.1-apache

# Instala extensiones necesarias
RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql

# Copia el código al contenedor
COPY . /var/www/html

# Da permisos al directorio de trabajo
RUN chown -R www-data:www-data /var/www/html

# Habilita el módulo de reescritura en Apache
RUN a2enmod rewrite

# Exponer el puerto 80
EXPOSE 80
