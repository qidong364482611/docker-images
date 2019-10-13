FROM php:apache-buster

ARG BUILD_DATE
ARG VERSION
ARG REVISION

LABEL maintainer="Sandro Jäckel <sandro.jaeckel@gmail.com>" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.authors="Sandro Jäckel <sandro.jaeckel@gmail.com>" \
  org.opencontainers.image.url="https://github.com/SuperSandro2000/docker-images/tree/master/halcyon" \
  org.opencontainers.image.documentation="https://notabug.org/halcyon-suite/halcyon" \
  org.opencontainers.image.source="https://github.com/SuperSandro2000/docker-images" \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.revision=$REVISION \
  org.opencontainers.image.vendor="SuperSandro2000" \
  org.opencontainers.image.licenses="GPL-3.0" \
  org.opencontainers.image.title="Halcyon" \
  org.opencontainers.image.description="Halcyon is a webclient for Mastodon and Pleroma which aims to recreate the simple and beautiful user interface of Twitter while keeping all advantages of decentral networks in focus."

RUN usermod -aG tty www-data

COPY [ "files/ports.conf", "/etc/apache2/ports.conf" ]
COPY [ "files/entrypoint.sh", "/usr/local/bin/" ]

RUN export dev_apt="libicu-dev" \
  && apt-get update -q \
  && apt-get install -qy --no-install-recommends "$dev_apt" gettext gosu libicu63 \
  && docker-php-ext-install -j4 gettext intl \
  && a2enmod rewrite \
  && apt-get autoremove --purge -qy "$dev_apt" \
  && rm -rf /var/lib/apt/lists/*

RUN export dev_apt="git" \
  && apt-get update -q \
  && apt-get install -qy --no-install-recommends "$dev_apt" \
  && git clone --depth=1 https://notabug.org/halcyon-suite/halcyon.git /var/www/html/ \
  && bash -c 'chmod 755 /var/www/html/ -R' \
  && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
  && apt-get autoremove --purge -qy "$dev_apt" \
  && rm -rf /var/lib/apt/lists/*

EXPOSE 4430 8000
WORKDIR /var/www/html/
ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "apache2-foreground" ]