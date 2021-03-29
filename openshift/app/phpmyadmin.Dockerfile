FROM phpmyadmin/phpmyadmin

COPY ./openshift/app/configs/phpmyadmin-config.inc.php /var/www/html/config.inc.php

RUN chown -R www-data:www-data /var/www/html/config.inc.php
