FROM php:7.2-apache
# TODO switch to buster once https://github.com/docker-library/php/issues/865 is resolved in a clean way (either in the PHP image or in PHP itself)

EXPOSE 8080
#EXPOSE 8080 80 444 22
#EXPOSE 3306

RUN rm -vfr /var/lib/apt/lists/*

##RUN chmod o+r /etc/resolv.conf

# install the PHP extensions we need
RUN apt-get update -y
RUN apt-get upgrade -y --fix-missing
RUN apt-get dist-upgrade -y
#RUN dpkg --configure -a
#RUN apt-get -f install
RUN apt-get install -y ssh-client
RUN apt autoremove -y

COPY .ssh/id_rsa /.ssh/id_rsa
# RUN ssh-keygen -R github.com
RUN eval `ssh-agent -s`
#RUN eval `ssh-agent`
###RUN cat /.ssh/id_rsa && chmod 600 /.ssh/id_rsa && eval "$(ssh-agent -s)"
#RUN ssh-add
#RUN ssh-add /.ssh/id_rsa

RUN set -eux; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get install -y \
		libfreetype6-dev \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
		libssl-dev \
		ca-certificates \
		libcurl4-openssl-dev \
		libgd-tools \
		libmcrypt-dev \
		zip \
		default-mysql-client \
		vim \
		wget \
		libbz2-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-configure gd \
		--with-freetype-dir=/usr \
		--with-jpeg-dir=/usr \
		--with-png-dir=/usr \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
		pdo_mysql \
		zip \
		bcmath \
		bz2 \
		exif \
		ftp \
		gd \
		gettext \
		mbstring \
		mysqli \
		opcache \
		shmop \
		sysvmsg \
		sysvsem \
		sysvshm \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'memory_limit=1024M'; \
		echo 'output_buffering=Off'; \
		echo 'upload_max_filesize=1G'; \
		echo 'post_max_size=1G'; \
		echo 'opcache.enable_cli=1'; \
		echo 'opcache.memory_consumption=1024'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=6000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /

RUN apt-get install -o Dpkg::Options::="--force-confold" -y -q --no-install-recommends && apt-get clean -y \
  ca-certificates \
	libcurl4-openssl-dev \
	libgd-tools \
	libmcrypt-dev \
	git \
	default-mysql-client \
	vim \
	wget \
	&& apt-get autoremove

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
	php composer-setup.php && \
	mv composer.phar /usr/local/bin/composer && \
	php -r "unlink('composer-setup.php');"

# RUN wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.4.2/drush.phar && \
#	chmod +x drush.phar && \
#	mv drush.phar /usr/local/bin/drush

# RUN rm -rf /var/www/html/*

# Don't copy .env to OpenShift - use Deployment Config > Environment instead
COPY .env ./.env

# COPY /app/config/sync/apache.conf /etc/apache2/sites-enabled/000-default.conf
COPY app/config/sync/apache2.conf /etc/apache2/apache2.conf
COPY app/config/sync/ports.conf /etc/apache2/ports.conf
COPY app/config/sync/web-root.htaccess /vendor/moodle/.htaccess

RUN chown -R www-data:www-data /vendor/moodle

RUN service apache2 restart

COPY composer.json ./composer.json

#RUN mkdir /www

#WORKDIR /www

ENV COMPOSER_MEMORY_LIMIT=-1
# RUN composer install --prefer-dist --optimize-autoloader --no-interaction --no-progress --no-dev
RUN composer install --optimize-autoloader --no-interaction

#RUN git clone -b MOODLE_{{Version3}}_STABLE git://git.moodle.org/moodle.git
COPY app/config/sync/moodle-config.php /vendor/moodle/moodle/config.php

# vim:set ft=dockerfile:
