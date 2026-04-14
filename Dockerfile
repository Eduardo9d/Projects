FROM ubuntu:22.04

LABEL maintainer="eduardo9d@gmail.com"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apache2 \
    && rm -rf /var/lib/apt/lists/*

RUN echo "Melhor Site" > /var/www/html/index.html

EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]