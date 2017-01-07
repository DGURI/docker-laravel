FROM ubuntu:16.04
MAINTAINER Donghyeon Hwang <dguri1997@gmail.com>

# upgrade the container
RUN apt-get update && \
    apt-get upgrade -y

RUN apt-get install -y curl wget git unzip software-properties-common

# set the locale
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale  && \
    locale-gen en_US.UTF-8  && \
    ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
    
# setup bash
COPY .bash_aliases /root

# add nginx && php7 in apt source list
RUN echo "deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/source.list && \
    echo "deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/source.list && \
    wget -q -O- http://nginx.org/keys/nginx_signing.key | apt-key add - && \
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php && \
    curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    curl -s https://packagecloud.io/gpg.key | apt-key add - && \
    echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list && \
    apt-get update -y

RUN apt-get install -y nginx 
RUN mkdir "/usr/share/nginx/app" && \
    rm -f /etc/nginx/sites-available/default && \
    chown -Rf www-data:www-data /usr/share/nginx/app && \
    chmod -Rf 755 /usr/share/nginx/app 
COPY etc/nginx/conf.d/default.conf /etc/nginx/conf.d/
RUN sed -i "s/user nginx/user www-data/" /etc/nginx/nginx.conf && \
    echo "daemon off;" >> /etc/nginx/nginx.conf
VOLUME ["/usr/share/nginx/app"]

RUN apt-get install -y php7.0-fpm php7.0-dev php7.0-pgsql php7.0-sqlite3 php7.0-gd \ 
    php-apcu php7.0-curl php7.0-imap php7.0-mysql php7.0-readline php-xdebug php-common \
    php7.0-mbstring php7.0-xml php7.0-zip
RUN sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/cli/php.ini && \
    sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/cli/php.ini && \
    sed -i "s/;date.timezone.*/date.timezone = Asia\/Seoul/" /etc/php/7.0/cli/php.ini && \
    sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini && \
    sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini && \
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.0/fpm/php.ini && \
    sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.0/fpm/php.ini && \
    sed -i "s/;date.timezone.*/date.timezone = Asia\/Seoul/" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf
COPY etc/nginx/fastcgi_params /etc/nginx/

# install composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    printf "\nPATH=\"~/.composer/vendor/bin:\$PATH\"\n" | tee -a ~/.bashrc

# install laravel envoy
RUN composer global require "laravel/envoy"

#install laravel installer
RUN composer global require "laravel/installer"

# install nodejs
RUN apt-get install -y nodejs build-essential

# install gulp
RUN /usr/bin/npm install -g gulp

# install bower
RUN /usr/bin/npm install -g bower

# install blackfire
RUN apt-get install -y blackfire-agent blackfire-php

# clean up our mess
RUN apt-get remove --purge -y software-properties-common && \
    apt-get autoremove -y && \
    apt-get clean && \
    apt-get autoclean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/man/?? && \
    rm -rf /usr/share/man/??_*

# expose ports
EXPOSE 80 443

# set container entrypoints
COPY scripts/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
