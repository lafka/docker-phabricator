#!/bin/bash

set -e

service mysql start
service ssh start
service apache2 start

if [ ! -f /var/lib/mysql/ibdata1 ]; then

	echo "init Mysql admin user"
	killall mysqld

	mysql_install_db

	mysqld_safe &
	sleep 10s

	echo "GRANT ALL ON *.* TO admin@'%' IDENTIFIED BY 'admin' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql
fi

cd /opt/
git clone git://github.com/facebook/libphutil.git|| ( cd libphutil; git pull; )
git clone git://github.com/facebook/arcanist.git|| ( cd arcanist; git pull; )
git clone git://github.com/facebook/phabricator.git|| ( cd phabricator; git pull; )

[ -e /opt/phabricator/conf/local/local.json ] && chmod 666 /opt/phabricator/conf/local/local.json

cd /opt/phabricator && ./bin/storage upgrade --force
cd /opt/phabricator && ./bin/phd restart

exec /bin/bash
