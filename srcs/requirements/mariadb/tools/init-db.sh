#!/bin/sh

set -e

mkdir -p /run/mysqld /var/lib/mysql

chown -R mysql:mysql \
    /run/mysqld \
    /var/lib/mysql

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"

DB_PASSWORD_FILE="/run/secrets/db_password"
DB_ROOT_PASSWORD_FILE="/run/secrets/db_root_password"

if [ ! -f "$DB_PASSWORD_FILE" ]; then
    echo "Database password secret is missing."
    exit 1
fi

if [ ! -f "$DB_ROOT_PASSWORD_FILE" ]; then
    echo "Database root password secret is missing."
    exit 1
fi

MYSQL_PASSWORD="$(cat "$DB_PASSWORD_FILE")"
MYSQL_ROOT_PASSWORD="$(cat "$DB_ROOT_PASSWORD_FILE")"


if [ ! -d "/var/lib/mysql/mysql" ]; then

    echo "Initializing MariaDB..."

    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-test-db

    mariadbd \
        --user=mysql \
        --skip-networking \
        --socket=/run/mysqld/mysqld.sock &

    pid=$!

    attempts=0

    until mariadb-admin \
        --socket=/run/mysqld/mysqld.sock \
        ping --silent
    do
        attempts=$((attempts + 1))

        if [ "$attempts" -ge 30 ]; then
            echo "MariaDB initialization failed."
            exit 1
        fi

        sleep 1
    done

    mariadb \
        --socket=/run/mysqld/mysqld.sock \
        -u root <<EOF

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES
ON \`${MYSQL_DATABASE}\`.*
TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost'
IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

FLUSH PRIVILEGES;

EOF

    mariadb-admin \
        --socket=/run/mysqld/mysqld.sock \
        -u root \
        -p"${MYSQL_ROOT_PASSWORD}" \
        shutdown

    wait "$pid"

fi

exec mariadbd --user=mysql