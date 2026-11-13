FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.2-fpm \
    php8.2-cli \
    php8.2-mysql \
    php8.2-curl \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    mariadb-client \
    curl \
    ca-certificates \
    tar \
    && rm -rf /var/lib/apt/lists/*


RUN mkdir -p /usr/src/wordpress \
    && curl -L https://wordpress.org/latest.tar.gz \
        -o /tmp/wordpress.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /tmp \
    && cp -a /tmp/wordpress/. /usr/src/wordpress/ \
    && rm -rf /tmp/wordpress \
    && rm -f /tmp/wordpress.tar.gz


RUN curl -L \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp


COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY conf/wp-config.php /usr/src/wordpress/wp-config.php

COPY tools/init-wordpress.sh /usr/local/bin/init-wordpress.sh


RUN chmod +x /usr/local/bin/init-wordpress.sh \
    && mkdir -p /run/php /var/www/html \
    && chown -R www-data:www-data /var/www/html


CMD ["/usr/local/bin/init-wordpress.sh"]