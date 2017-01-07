#!/bin/sh

APP_DIR=/usr/share/nginx/app

chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR
chmod -R 775 $APP_DIR/storage
service php7.0-fpm start
nginx
