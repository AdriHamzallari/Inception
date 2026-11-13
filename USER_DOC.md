# Inception — User Documentation

## Overview

Inception provides a small web infrastructure composed of three Docker services:

* **NGINX** — provides HTTPS access to the website and is the only service exposed to the host.
* **WordPress + PHP-FPM** — provides the website and administration interface.
* **MariaDB** — stores WordPress data such as users, posts, settings, and configuration.

The services run in separate Docker containers and communicate through a private Docker network.

The website is available through:

```text
https://ahamzall.42.fr
```

The WordPress administration panel is available through:

```text
https://ahamzall.42.fr/wp-admin
```

---

## Services Provided

### NGINX

NGINX is the public entry point of the stack.

It:

* accepts HTTPS connections on port `443`;
* uses TLS 1.2 and TLS 1.3;
* serves static website files;
* forwards PHP requests to the WordPress container.

No other service is directly exposed to the host.

---

### WordPress

WordPress provides the website and its administration interface.

It runs together with PHP-FPM inside the WordPress container.

The project automatically creates:

* one WordPress administrator;
* one additional WordPress author user.

---

### MariaDB

MariaDB stores the WordPress database.

It is only accessible from inside the Docker network and is not exposed directly to the host machine.

Database data is stored persistently so that it survives container recreation.

---

# Starting the Activity

Open a terminal and go to the project root:

```bash
cd ~/Inception
```

Start the complete infrastructure with:

```bash
make
```

This command:

1. creates the required persistent-data directories;
2. builds the Docker images when required;
3. creates the Docker network and volumes;
4. starts MariaDB;
5. starts WordPress;
6. starts NGINX.

Check that all services are running:

```bash
make ps
```

The expected containers are:

```text
mariadb
wordpress
nginx
```

Their status should be `Up`.

Only NGINX should publish port `443`.

---

# Stopping the Activity

To stop and remove the containers while keeping all persistent website and database data:

```bash
make down
```

The containers are removed, but the WordPress and MariaDB data remain stored on the host.

The project can later be started again with:

```bash
make
```

---

# Accessing the Website

Open a web browser and visit:

```text
https://ahamzall.42.fr
```

A self-signed TLS certificate is used, so the browser may display a certificate warning.

After accepting the local certificate warning, the WordPress website should be displayed.

The website can also be tested from the terminal:

```bash
curl -kI https://ahamzall.42.fr
```

A working installation should return:

```text
HTTP/1.1 200 OK
```

---

# Accessing the Administration Panel

Open:

```text
https://ahamzall.42.fr/wp-admin
```

The administrator username is configured in:

```text
srcs/.env
```

using:

```text
WP_ADMIN_USER
```

The administrator password is stored separately in:

```text
secrets/wp_admin_password.txt
```

To view it locally:

```bash
cat ~/Inception/secrets/wp_admin_password.txt
```

The credentials must not be committed to Git or shared publicly.

---

# Credentials

Sensitive passwords are stored inside the local:

```text
secrets/
```

directory.

The project uses the following secret files:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Their purposes are:

| File                    | Purpose                                      |
| ----------------------- | -------------------------------------------- |
| `db_password.txt`       | Password used by WordPress to access MariaDB |
| `db_root_password.txt`  | MariaDB root password                        |
| `wp_admin_password.txt` | WordPress administrator password             |
| `wp_user_password.txt`  | Password of the additional WordPress user    |

These files must remain private.

Recommended permissions are:

```bash
chmod 600 secrets/*.txt
```

Non-sensitive configuration is stored in:

```text
srcs/.env
```

This includes information such as:

```text
DOMAIN_NAME
MYSQL_DATABASE
MYSQL_USER
WP_TITLE
WP_ADMIN_USER
WP_ADMIN_EMAIL
WP_USER
WP_USER_EMAIL
```

Passwords must not be stored as regular environment variables.

---

# Checking Service Status

## Check All Containers

Run:

```bash
make ps
```

All three containers should be running:

```text
mariadb
wordpress
nginx
```

---

## Check the Website

Run:

```bash
curl -kI https://ahamzall.42.fr
```

Expected result:

```text
HTTP/1.1 200 OK
```

Check the WordPress page title:

```bash
curl -ks https://ahamzall.42.fr | grep -m1 '<title>'
```

Expected result:

```html
<title>Inception</title>
```

---

## Check Container Logs

All service logs can be displayed with:

```bash
make logs
```

A specific service can also be inspected with Docker Compose.

For WordPress:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
logs wordpress
```

For MariaDB:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
logs mariadb
```

For NGINX:

```bash
docker compose \
-f srcs/docker-compose.yml \
--env-file srcs/.env \
logs nginx
```

---

# Checking WordPress Users

The configured WordPress users can be listed with:

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

A normal installation should contain:

* the configured administrator;
* the configured additional user.

---

# Checking Exposed Ports

Run:

```bash
sudo ss -ltnp | grep -E ':(443|9000|3306)\b'
```

Only port:

```text
443
```

should be published on the host.

WordPress port `9000` and MariaDB port `3306` are internal Docker-network ports.

---

# Persistent Data

Persistent data is stored on the host under:

```text
/home/ahamzall/data/wordpress
/home/ahamzall/data/mariadb
```

The WordPress directory contains website files.

The MariaDB directory contains the database files.

Stopping or recreating the containers does not normally remove this data.

For example:

```bash
make down
make
```

should restart the same WordPress installation instead of creating a new one.

---

# Full Cleanup

The project contains an `fclean` Makefile target:

```bash
make fclean
```

This removes the Docker infrastructure and persistent project data.

This command is destructive.

Do not use it when the existing WordPress website or database must be preserved.

Use:

```bash
make down
```

instead when the goal is only to stop the activity.
