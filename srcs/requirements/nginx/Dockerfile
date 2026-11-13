FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    && rm -f /var/www/html/index.nginx-debian.html \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY certs/nginx.crt /etc/ssl/certs/nginx.crt

COPY certs/nginx.key /etc/ssl/private/nginx.key

CMD ["nginx", "-g", "daemon off;"]