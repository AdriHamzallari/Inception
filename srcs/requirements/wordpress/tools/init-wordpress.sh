#!/bin/sh

set -e

: "${MYSQL_HOST:?MYSQL_HOST is required}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${WP_TITLE:?WP_TITLE is required}"

: "${WP_ADMIN_USER:?WP_ADMIN_USER is required}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is required}"

: "${WP_USER:?WP_USER is required}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is required}"

DB_PASSWORD_FILE="/run/secrets/db_password"
WP_ADMIN_PASSWORD_FILE="/run/secrets/wp_admin_password"
WP_USER_PASSWORD_FILE="/run/secrets/wp_user_password"

for secret in \
    "$DB_PASSWORD_FILE" \
    "$WP_ADMIN_PASSWORD_FILE" \
    "$WP_USER_PASSWORD_FILE"
do
    if [ ! -f "$secret" ]; then
        echo "Required secret missing: $secret"
        exit 1
    fi
done

MYSQL_PASSWORD="$(cat "$DB_PASSWORD_FILE")"
WP_ADMIN_PASSWORD="$(cat "$WP_ADMIN_PASSWORD_FILE")"
WP_USER_PASSWORD="$(cat "$WP_USER_PASSWORD_FILE")"

mkdir -p /run/wordpress

cp "$DB_PASSWORD_FILE" /run/wordpress/db_password

chown root:www-data /run/wordpress/db_password
chmod 640 /run/wordpress/db_password

if [ ! -f /var/www/html/wp-settings.php ]; then
    echo "Copying WordPress files..."

    cp -a /usr/src/wordpress/. /var/www/html/
fi

cp /usr/src/wordpress/wp-config.php /var/www/html/wp-config.php

echo "Waiting for MariaDB..."

attempts=0

until mariadb-admin \
    -h "$MYSQL_HOST" \
    -u "$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    ping --silent
do
    attempts=$((attempts + 1))

    if [ "$attempts" -ge 60 ]; then
        echo "MariaDB did not become ready."
        exit 1
    fi

    sleep 1
done

echo "MariaDB is ready."

if ! wp core is-installed \
    --path=/var/www/html \
    --allow-root
then
    echo "Installing WordPress..."

    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
fi

if ! wp user get "$WP_USER" \
    --path=/var/www/html \
    --allow-root \
    >/dev/null 2>&1
then
    echo "Creating second WordPress user..."

    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --path=/var/www/html \
        --allow-root
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F