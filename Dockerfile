FROM phusion/baseimage

RUN curl -s https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh | bash

RUN set -ex && \
      apt-get update \
      && apt-get -y upgrade \
      && apt-get update --fix-missing

RUN set -ex && \
      apt-get install -y \
      php7.0 \
      php7.0-bcmath \
      php7.0-cli \
      php7.0-common \
      php7.0-fpm \
      php7.0-gd \
      php7.0-gmp \
      php7.0-intl \
      php7.0-json \
      php7.0-mbstring \
      php7.0-mcrypt \
      php7.0-mysqlnd \
      php7.0-opcache \
      php7.0-pdo \
      php7.0-xml \
      php7.0-phalcon

RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN service php7.0-fpm start

ENV SOPS_SHA 6b1d245c59c46b0f7c1f5b9fa789e0236bdcb44b0602ca1a7cadb6d0aac64c3c

ADD https://github.com/mozilla/sops/releases/download/3.0.5/sops_3.0.4_amd64.deb /tmp/sops.deb

RUN set -ex && \
      # Verify downloaded sops.deb SHA
      echo "$SOPS_SHA /tmp/sops.deb" | sha256sum -c - && \
      # Install sops from downloaded .deb file
      dpkg -i /tmp/sops.deb && \
      # Remove tmp install files
      rm /tmp/sops.deb && \
      apt-get install -y \
      nodejs \
      npm \
      git \
      mysql-client \
      nginx-full \
      supervisor

RUN apt-get clean
RUN apt-get autoclean

RUN sed -e 's/;clear_env = no/clear_env = no/' -i /etc/php/7.0/fpm/pool.d/www.conf

COPY build/.bashrc /root/.bashrc
COPY build/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY build/nginx.conf /etc/nginx/sites-enabled/default
COPY build/php.ini /etc/php/7.0/fpm/php.ini
COPY *.sh /
COPY .env.* /

ADD db /db/
ADD app /var/www/app/
ADD public /var/www/public/

EXPOSE 80 443

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]