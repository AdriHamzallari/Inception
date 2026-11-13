# Inception — Developer Documentation

## Overview

This document explains how to configure, build, launch, inspect, and maintain the Inception infrastructure from a development perspective.

The stack contains three custom Docker services:

```text
NGINX
WordPress + PHP-FPM
MariaDB
```

Each service is built using its own Dockerfile.

The services communicate through a custom Docker bridge network called:

```text
inception-net
```

Only NGINX publishes a host port:

```text
443
```

WordPress and MariaDB remain internal to the Docker network.

---

# Project Structure

The expected repository structure is:

```text
Inception/
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── Makefile
├── .gitignore
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── init-db.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── certs/
        │   │   ├── nginx.crt
        │   │   └── nginx.key
        │   └── conf/
        │       └── nginx.conf
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   ├── wp-config.php
            │   └── www.conf
            └── tools/
                └── init-wordpress.sh
```

---

# Prerequisites

The project must be executed inside a Virtual Machine.

The VM requires:

* Docker;
* Docker Compose;
* GNU Make;
* standard Linux command-line tools.

Verify the installed tools:

```bash
docker --version
docker compose version
make --version
```

On a Debian-based environment, Make can be installed with:

```bash
sudo apt update
sudo apt install -y make
```

If Docker Compose is missing:

```bash
sudo apt install -y docker-compose
```

Docker must also be installed and the current user must have permission to communicate with the Docker daemon.

---

# Domain Configuration

The project domain is:

```text
ahamzall.42.fr
```

Determine the VM IPv4 address:

```bash
hostname -I
```

Add the VM address to:

```text
/etc/hosts
```

For example:

```text
10.0.2.15 ahamzall.42.fr
```

Edit the file with:

```bash
sudo nano /etc/hosts
```

Verify resolution:

```bash
getent hosts ahamzall.42.fr
```

The command should resolve the domain to the VM IP address.

---

# Persistent Storage Directories

The project stores persistent data under:

```text
/home/ahamzall/data
```

Create the required directories:

```bash
mkdir -p /home/ahamzall/data/wordpress
mkdir -p /home/ahamzall/data/mariadb
```

Verify:

```bash
ls -ld /home/ahamzall/data/*
```

---

# Environment Configuration

Create:

```text
srcs/.env
```

The environment file contains non-sensitive configuration.

Example:

```env
DOMAIN_NAME=ahamzall.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

WP_TITLE=Inception

WP_ADMIN_USER=ahamzall
WP_ADMIN_EMAIL=ahamzall@42.fr

WP_USER=user42
WP_USER_EMAIL=user42@42.fr
```

Passwords must not be stored in this file.

The file is excluded from Git.

---

# Secrets Configuration

Create:

```bash
mkdir -p secrets
```

The required secret files are:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Passwords can be generated using:

```bash
openssl rand -hex 16 > secrets/db_password.txt
openssl rand -hex 16 > secrets/db_root_password.txt
openssl rand -hex 16 > secrets/wp_admin_password.txt
openssl rand -hex 16 > secrets/wp_user_password.txt
```

Restrict access:

```bash
chmod 600 secrets/*.txt
```

The secret files are mounted into the required containers through Docker Compose.

Inside the containers, Compose provides them through:

```text
/run/secrets/
```

MariaDB receives:

```text
/run/secrets/db_password
/run/secrets/db_root_password
```

WordPress receives:

```text
/run/secrets/db_password
/run/secrets/wp_admin_password
/run/secrets/wp_user_password
```

The WordPress initialization script creates a restricted runtime copy of the database password for PHP-FPM:

```text
/run/wordpress/db_password
```

This allows the `www-data` PHP-FPM worker to read the database credential without exposing it as a normal environment variable.

---

# Git Configuration

Sensitive configuration must not be committed.

The root `.gitignore` should exclude at least:

```gitignore
srcs/.env
secrets/
```

Verify:

```bash
git check-ignore -v srcs/.env
git check-ignore -v secrets/db_password.txt
git check-ignore -v secrets/db_root_password.txt
git check-ignore -v secrets/wp_admin_password.txt
git check-ignore -v secrets/wp_user_password.txt
```

Before committing, inspect:

```bash
git status
```

No real password or `.env` file should be staged.

---

# Validate Docker Compose Configuration

Before building, validate the Compose file:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
config
```

This verifies:

* Compose syntax;
* environment-variable substitution;
* secret paths;
* network configuration;
* volume configuration;
* service definitions.

---

# Build and Launch

From the repository root:

```bash
cd ~/Inception
make
```

The Makefile executes Docker Compose and builds the three custom images.

The expected images are:

```text
inception-nginx:1.0
inception-wordpress:1.0
inception-mariadb:1.0
```

The infrastructure contains:

```text
mariadb
wordpress
nginx
```

Check the services:

```bash
make ps
```

All containers should report:

```text
Up
```

---

# Docker Compose Launch Command

The Makefile internally uses Docker Compose with:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
up -d --build
```

The `-d` option starts the containers in detached mode.

The `--build` option rebuilds images when necessary.

---

# Makefile Commands

## Build and Start

```bash
make
```

Creates storage directories, builds images, and starts the infrastructure.

---

## Start Existing Containers

```bash
make start
```

Starts previously stopped containers.

---

## Stop Containers

```bash
make stop
```

Stops containers without removing them.

---

## Start Infrastructure Without Rebuilding

```bash
make up
```

Runs Docker Compose using the existing images.

---

## Remove Containers and Network

```bash
make down
```

Removes the containers and Compose network while preserving persistent data.

---

## View Status

```bash
make ps
```

---

## View Logs

```bash
make logs
```

---

## Full Rebuild

```bash
make re
```

This performs the configured full cleanup followed by a complete rebuild.

Because the project's `fclean` target removes persistent data, this operation should only be used when a completely fresh installation is intended.

---

## Full Cleanup

```bash
make fclean
```

This is destructive.

It removes:

* containers;
* Compose volumes;
* project Docker images;
* persistent WordPress data;
* persistent MariaDB data.

---

# Managing Containers

List running project containers:

```bash
docker ps
```

Or:

```bash
make ps
```

Inspect a container:

```bash
docker inspect wordpress
```

Open a shell inside WordPress:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
exec wordpress sh
```

Open a shell inside MariaDB:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
exec mariadb sh
```

Open a shell inside NGINX:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
exec nginx sh
```

---

# Managing Logs

View all logs:

```bash
make logs
```

View WordPress logs:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
logs wordpress
```

View MariaDB logs:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
logs mariadb
```

View NGINX logs:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
logs nginx
```

---

# Network

The project uses a dedicated bridge network:

```text
inception-net
```

List Docker networks:

```bash
docker network ls
```

Inspect the project network:

```bash
docker network inspect inception-net
```

Docker internal DNS allows services to communicate using service names.

NGINX communicates with WordPress through:

```text
wordpress:9000
```

WordPress communicates with MariaDB through:

```text
mariadb:3306
```

No fixed container IP addresses are required.

---

# Volumes

The project defines two named Docker volumes:

```text
wordpress_data
mariadb_data
```

List them:

```bash
docker volume ls
```

Inspect the WordPress volume:

```bash
docker volume inspect wordpress_data
```

Inspect the MariaDB volume:

```bash
docker volume inspect mariadb_data
```

The volume configuration stores data at:

```text
/home/ahamzall/data/wordpress
/home/ahamzall/data/mariadb
```

Inside the containers:

```text
wordpress_data -> /var/www/html
mariadb_data   -> /var/lib/mysql
```

---

# Data Persistence

Container filesystems are temporary.

Important application data therefore lives in volumes rather than only inside container writable layers.

WordPress data is stored in:

```text
/home/ahamzall/data/wordpress
```

MariaDB data is stored in:

```text
/home/ahamzall/data/mariadb
```

To test persistence:

```bash
make down
```

Verify that data remains:

```bash
ls /home/ahamzall/data/wordpress
ls /home/ahamzall/data/mariadb
```

Then restart:

```bash
make
```

The same WordPress installation and database should be restored.

WordPress should not reinstall itself when persistent data already exists.

---

# Service Verification

## HTTPS

```bash
curl -kI https://ahamzall.42.fr
```

Expected:

```text
HTTP/1.1 200 OK
```

---

## Website Content

```bash
curl -ks https://ahamzall.42.fr | grep -m1 '<title>'
```

Expected:

```html
<title>Inception</title>
```

---

## Published Ports

```bash
sudo ss -ltnp | grep -E ':(443|9000|3306)\b'
```

Only host port `443` should be published.

Ports `9000` and `3306` remain internal to Docker.

---

## Docker DNS

From NGINX:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
exec nginx getent hosts wordpress
```

From WordPress:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
exec wordpress getent hosts mariadb
```

Both service names should resolve to Docker-network addresses.

---

## Database Connectivity

Test MariaDB authentication from WordPress:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
exec wordpress sh -c \
'mariadb -h mariadb -u "$MYSQL_USER" -p"$(cat /run/secrets/db_password)" "$MYSQL_DATABASE" -e "SELECT 1;"'
```

A successful result proves that WordPress can reach and authenticate with MariaDB.

---

## WordPress Users

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
exec wordpress \
wp user list \
--fields=ID,user_login,roles \
--path=/var/www/html \
--allow-root
```

The installation should contain the configured administrator and additional user.

---

# Process Management

Each container runs its main service as its primary foreground process.

Examples:

```text
NGINX     -> nginx -g 'daemon off;'
WordPress -> php-fpm8.2 -F
MariaDB   -> mariadbd --user=mysql
```

This allows Docker to correctly track the health and lifecycle of each service.

The initialization scripts use `exec` when launching the final service so that the service replaces the shell process.

---

# Startup Sequence

The expected logical startup flow is:

```text
Docker Compose
      |
      v
MariaDB
      |
      v
WordPress waits for MariaDB
      |
      v
WordPress initialization
      |
      v
PHP-FPM
      |
      v
NGINX
```

`depends_on` controls service startup order, but it does not guarantee that MariaDB is ready to accept connections.

For this reason, the WordPress initialization script contains its own MariaDB readiness check before performing WordPress operations.

---

# Rebuilding After Configuration Changes

If a Dockerfile, startup script, or copied configuration file changes, rebuild with:

```bash
make
```

or explicitly:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
up -d --build
```

To force a specific service to be recreated, for example WordPress:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
up -d --build --force-recreate wordpress
```

Persistent volume data remains unless the volumes or host data directories are explicitly deleted.

---

# Important Development Notes

Do not store passwords directly in:

* Dockerfiles;
* `docker-compose.yml`;
* source code;
* regular environment variables.

Do not expose ports `3306` or `9000` on the host.

Do not use `make fclean` unless all existing WordPress and database data may be destroyed.

Do not manually change secret passwords after MariaDB has already been initialized unless the corresponding database credentials are also updated.

If a new secret password is generated while an old persistent MariaDB database remains, WordPress authentication may fail because the password stored by MariaDB will differ from the new secret.
