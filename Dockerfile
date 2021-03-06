FROM php:7.0.5-fpm

MAINTAINER pax <paolo.garri@sport1.de>

RUN curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

#fix docker-php-ext-install bug
RUN sed -i 's/docker-php-\(ext-$ext.ini\)/\1/' /usr/local/bin/docker-php-ext-install

# Install memcache extension
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends unzip libssl-dev libpcre3 libpcre3-dev \
    && cd /tmp \
    && curl -sSL -o php7.zip https://github.com/websupport-sk/pecl-memcache/archive/php7.zip \
    && unzip php7 \
    && cd pecl-memcache-php7 \
    && /usr/local/bin/phpize \
    && ./configure --with-php-config=/usr/local/bin/php-config \
    && make \
    && make install \
    && echo "extension=memcache.so" > /usr/local/etc/php/conf.d/ext-memcache.ini \
    && rm -rf /tmp/pecl-memcache-php7 php7.zip \
    && apt-get install yarn


# Install other needed extensions
RUN apt-get update && apt-get install -y libfreetype6 libjpeg62-turbo libmcrypt4 libpng12-0 sendmail libicu-dev bzip2 mysql-client --no-install-recommends  && rm -rf /var/lib/apt/lists/*
RUN buildDeps=" \
		libfreetype6-dev \
		libjpeg-dev \
		libldap2-dev \
		libmcrypt-dev \
		libpng12-dev \
		zlib1g-dev \
		libxslt-dev \
	"; \
	set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --enable-gd-native-ttf --with-jpeg-dir=/usr/lib/x86_64-linux-gnu --with-png-dir=/usr/lib/x86_64-linux-gnu --with-freetype-dir=/usr/lib/x86_64-linux-gnu \
	&& docker-php-ext-install gd \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
	&& docker-php-ext-install ldap \
	&& docker-php-ext-install mbstring \
	&& docker-php-ext-install mcrypt \
	&& docker-php-ext-install mysqli \
	&& docker-php-ext-install pdo_mysql \
	&& docker-php-ext-install zip \
	&& docker-php-ext-install intl \
	&& docker-php-ext-install xsl \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& cd /usr/src/php \
	&& make clean

# Install nodejs & npm

RUN curl -sL https://deb.nodesource.com/setup_7.x | bash -
RUN apt-get install -y nodejs

# Install Composer for Symfony
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Install prestissimo
RUN php /usr/local/bin/composer global require hirak/prestissimo

# Install ffmpeg
RUN echo deb http://ftp.uk.debian.org/debian jessie-backports main >>/etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y ffmpeg

# Setup timezone to Europe/Berlin
RUN cat /usr/src/php/php.ini-production | sed 's/^;\(date.timezone.*\)/\1 \"Europe\/Berlin\"/' > /usr/local/etc/php/php.ini

# Disable cgi.fix_pathinfo in php.ini
RUN sed -i 's/;\(cgi\.fix_pathinfo=\)1/\10/' /usr/local/etc/php/php.ini

# No memory limit in php.ini
RUN sed -i 's/\(memory_limit \= \)[0-9]*[MmKkGg]*/\1-1/' /usr/local/etc/php/php.ini

# Change TZ

ENV TZ=Europe/Berlin
RUN echo $TZ | tee /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

WORKDIR /var/www
