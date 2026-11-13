*This activity has been created as part of the 42 curriculum by ahamzall.*

# Inception

## Description

Inception is a system administration and Docker project developed as part of the 42 curriculum.

The goal of the project is to build and configure a small web infrastructure using Docker and Docker Compose inside a Virtual Machine.

The infrastructure is composed of three independent services:

* **NGINX** — acts as the only external entry point to the infrastructure and handles HTTPS connections using TLS.
* **WordPress + PHP-FPM** — runs the WordPress application and processes PHP requests.
* **MariaDB** — stores the WordPress database and user data.

Each service runs inside its own Docker container and is built using a custom Dockerfile based on Debian.

The containers communicate through a dedicated Docker bridge network.

Only NGINX exposes a port to the host machine. Port `443` is used for HTTPS traffic. WordPress and MariaDB remain accessible only inside the Docker network.

Persistent data is stored outside the containers so that WordPress files and database data remain available even when containers are stopped, removed, or rebuilt.

The website is available locally through:

```text
https://ahamzall.42.fr
```

---

## Project Architecture

The infrastructure follows the following structure:

```text
                     HOST / VIRTUAL MACHINE
                              |
                         HTTPS :443
                              |
                              v
                      +---------------+
                      |     NGINX     |
                      | TLS 1.2 / 1.3 |
                      +---------------+
                              |
                     FastCGI :9000
                              |
                              v
                  +---------------------+
                  | WordPress + PHP-FPM |
                  +---------------------+
                              |
                       MySQL :3306
                              |
                              v
                      +---------------+
                      |    MariaDB    |
                      +---------------+
```

The containers communicate through a custom Docker bridge network:

```text
inception-net
```

The persistent storage is divided into two Docker volumes:

```text
wordpress_data -> /home/ahamzall/data/wordpress
mariadb_data   -> /home/ahamzall/data/mariadb
```

Inside the containers they are mounted at:

```text
WordPress -> /var/www/html
MariaDB   -> /var/lib/mysql
```

---

## Main Design Choices

### NGINX

NGINX is the only service directly accessible from outside the Docker network.

It:

* listens on port `443`;
* handles HTTPS;
* supports TLS 1.2 and TLS 1.3;
* serves static WordPress files;
* forwards PHP requests to PHP-FPM through FastCGI.

NGINX runs in the foreground using:

```bash
nginx -g 'daemon off;'
```

This allows NGINX to remain the main process of its container.

---

### WordPress and PHP-FPM

WordPress is served using PHP-FPM.

NGINX cannot execute PHP itself, so PHP requests are forwarded to the WordPress container on:

```text
wordpress:9000
```

PHP-FPM runs in the foreground and acts as the main process of the WordPress container.

WordPress is automatically installed during the first startup if no existing installation is found.

Two WordPress users are created:

* one administrator;
* one regular author user.

The administrator username does not contain `admin` or `administrator`.

---

### MariaDB

MariaDB runs in its own container and stores the WordPress database.

The database is initialized automatically during the first startup.

WordPress connects to MariaDB using the Docker service name:

```text
mariadb:3306
```

MariaDB is not exposed directly to the host.

Its data is persisted through a Docker volume.

---

### Docker Secrets

Sensitive information such as passwords is not stored directly in the Dockerfiles or passed through normal environment variables.

The project uses Docker Compose secrets.

Secret files are stored locally inside:

```text
secrets/
```

Examples include:

```text
db_password.txt
db_root_password.txt
wp_admin_password.txt
wp_user_password.txt
```

These real secret files are excluded from Git.

Docker makes the required secrets available inside the corresponding containers through:

```text
/run/secrets/
```

The WordPress container creates a restricted runtime copy of the database password that can be read by the `www-data` user running PHP-FPM.

Non-sensitive configuration such as database names, usernames, domains, and email addresses is stored in:

```text
srcs/.env
```

The `.env` file is also excluded from Git because environment-specific configuration should remain local.

---

# Technical Comparisons

## Virtual Machines vs Docker

### Virtual Machines

A Virtual Machine emulates an entire computer and runs its own operating system and kernel.

Advantages:

* strong isolation;
* complete operating system environment;
* can run an operating system different from the host.

Disadvantages:

* requires more disk space;
* requires more memory;
* slower to start;
* every VM contains a complete operating system.

### Docker

Docker containers isolate applications while sharing the host operating system kernel.

Advantages:

* lightweight;
* fast startup;
* lower resource usage;
* easy reproducibility;
* simple service separation.

Disadvantages:

* containers share the host kernel;
* isolation is different from a complete VM.

### Choice in Inception

The Inception infrastructure runs inside a Virtual Machine as required by the project.

Docker is then used inside the VM to isolate NGINX, WordPress, and MariaDB into separate services.

The VM provides isolation from the physical host, while Docker provides lightweight isolation between the project services.

---

## Secrets vs Environment Variables

### Environment Variables

Environment variables are convenient for passing configuration to containers.

For example:

```text
MYSQL_DATABASE
MYSQL_USER
DOMAIN_NAME
```

They are appropriate for non-sensitive configuration.

However, passwords stored as environment variables may be visible through container configuration, debugging tools, process inspection, or commands such as:

```bash
env
```

### Docker Secrets

Docker secrets are stored as files and mounted only into containers that require them.

For example:

```text
/run/secrets/db_password
```

Advantages:

* passwords are not exposed as normal environment variables;
* each container receives only the secrets it needs;
* secrets can have restricted filesystem permissions;
* sensitive data is separated from normal configuration.

### Choice in Inception

This project uses:

* environment variables for non-sensitive configuration;
* Docker secrets for passwords and sensitive credentials.

This provides clearer separation between configuration and confidential information.

---

## Docker Network vs Host Network

### Host Network

When a container uses the host network directly, it shares the host's networking namespace.

This reduces network isolation and may expose container services directly through the host.

It can also create port conflicts between applications.

### Docker Network

A Docker bridge network creates an isolated network specifically for the containers.

Containers can communicate using their service names.

For example:

```text
nginx -> wordpress:9000
wordpress -> mariadb:3306
```

Docker provides internal DNS resolution so containers do not need fixed IP addresses.

### Choice in Inception

The project uses a custom bridge network:

```text
inception-net
```

Only NGINX publishes a port to the host.

WordPress port `9000` and MariaDB port `3306` remain internal to Docker.

This provides better service isolation and follows the principle that only services that need external access should expose host ports.

---

## Docker Volumes vs Bind Mounts

### Docker Volumes

Docker volumes are storage resources managed through Docker.

Advantages:

* independent from the container lifecycle;
* easy to attach to containers;
* persistent after container removal;
* managed through Docker.

### Bind Mounts

Bind mounts directly map a host filesystem path into a container.

For example:

```text
/home/user/data -> /var/lib/mysql
```

They provide direct control over where data exists on the host, but create tighter coupling between the container and the host filesystem structure.

### Choice in Inception

The services reference named Docker volumes:

```text
wordpress_data
mariadb_data
```

The local Docker volume driver is configured so the persistent data is stored under:

```text
/home/ahamzall/data/wordpress
/home/ahamzall/data/mariadb
```

This allows the services to use named volumes while ensuring that persistent project data exists at the required host locations.

---

# Instructions

## Requirements

The project must be executed inside a Virtual Machine with Docker installed.

Required host tools include:

```text
Docker
Docker Compose
Make
```

Check them with:

```bash
docker --version
docker compose version
make --version
```

---

## Domain Configuration

The domain used by the project is:

```text
ahamzall.42.fr
```

Find the IP address of the Virtual Machine:

```bash
hostname -I
```

Then configure `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Add the VM IP followed by the domain.

Example:

```text
10.0.2.15 ahamzall.42.fr
```

Verify:

```bash
getent hosts ahamzall.42.fr
```

---

## Persistent Data Directories

Create the required directories:

```bash
mkdir -p /home/ahamzall/data/wordpress
mkdir -p /home/ahamzall/data/mariadb
```

---

## Environment Configuration

Create:

```text
srcs/.env
```

Example structure:

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

Do not place passwords directly in this file.

---

## Secrets Configuration

Create the secrets directory:

```bash
mkdir -p secrets
```

The following secret files are required:

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

Restrict their permissions:

```bash
chmod 600 secrets/*.txt
```

Real secret files must never be committed to Git.

---

## Build and Start

From the repository root:

```bash
make
```

The Makefile creates the persistent data directories and starts the infrastructure using Docker Compose.

Check the containers:

```bash
make ps
```

The expected services are:

```text
mariadb
wordpress
nginx
```

Only NGINX should expose host port `443`.

---

## Access the Website

Open:

```text
https://ahamzall.42.fr
```

Because the project uses a self-signed TLS certificate, the browser may display a certificate warning.

The WordPress administration panel is available at:

```text
https://ahamzall.42.fr/wp-admin
```

---

## Stop the Infrastructure

Stop and remove the containers while preserving persistent data:

```bash
make down
```

Start the project again with:

```bash
make
```

---

## Clean the Project

The `fclean` target removes the Docker infrastructure, images, volumes, and persistent project data.

```bash
make fclean
```

This command is destructive and should only be used when a completely fresh installation is required.

---

# Testing

Check all running containers:

```bash
make ps
```

Test HTTPS:

```bash
curl -kI https://ahamzall.42.fr
```

Expected result:

```text
HTTP/1.1 200 OK
```

Check the website title:

```bash
curl -ks https://ahamzall.42.fr | grep -m1 '<title>'
```

Expected:

```html
<title>Inception</title>
```

Check host ports:

```bash
sudo ss -ltnp | grep -E ':(443|9000|3306)\b'
```

Only port `443` should be exposed on the host.

Check WordPress users:

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

Check that passwords are not present as normal environment variables:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
exec wordpress env | grep -i password
```

and:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
exec mariadb env | grep -i password
```

These commands should return no password variables.

---

# Persistence

WordPress and MariaDB data survive container recreation.

To test this:

```bash
make down
```

Check that the host data still exists:

```bash
ls /home/ahamzall/data/wordpress
ls /home/ahamzall/data/mariadb
```

Start the infrastructure again:

```bash
make
```

WordPress should continue using the previously created website and database instead of reinstalling everything.

---
# Project Structure

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

The real files inside `secrets/` and the `srcs/.env` file contain local or sensitive configuration and are excluded from Git.

```

The actual secret files and `.env` configuration are excluded from version control.

---

# Resources

The following resources were useful for understanding and implementing the project:

* Docker Documentation
  https://docs.docker.com/

* Docker Compose Documentation
  https://docs.docker.com/compose/

* Docker Networking Documentation
  https://docs.docker.com/engine/network/

* Docker Storage and Volumes Documentation
  https://docs.docker.com/engine/storage/volumes/

* Docker Compose Secrets Documentation
  https://docs.docker.com/compose/how-tos/use-secrets/

* NGINX Documentation
  https://nginx.org/en/docs/

* PHP-FPM Documentation
  https://www.php.net/manual/en/install.fpm.php

* MariaDB Documentation
  https://mariadb.com/docs/

* WordPress Documentation
  https://wordpress.org/documentation/

* WP-CLI Documentation
  https://wp-cli.org/

## Use of AI

AI was used as a learning and development support tool during this activity.

It was used for:

* explaining Docker concepts such as images, containers, volumes, networks, and PID 1;
* explaining the communication between NGINX, PHP-FPM, WordPress, and MariaDB;
* helping understand Docker Compose configuration;
* explaining Docker secrets and their differences from environment variables;
* helping diagnose configuration, networking, permission, and database connection problems;
* reviewing shell commands and configuration files;
* helping create testing procedures for the completed infrastructure;
* helping structure and draft this README.

AI-generated suggestions were reviewed, tested, and adapted to the project's requirements. The implementation was validated directly inside the Virtual Machine using Docker, command-line tools, service logs, and connectivity tests.
