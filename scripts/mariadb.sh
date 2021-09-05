#!/bin/sh

apt-get -y install mariadb-server

if [ -z "${MYSQL_ROOT_PASSWORD}" ]; then
  MYSQL_ROOT_PASSWORD="password123"
fi

SECURE_MYSQL=$(expect -c "

set timeout 10
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none): \"
send \"n\r\"
expect \"Set root password? \[Y/n\] \"
send \"y\r\"
expect \"New password: \"
send \"${MYSQL_ROOT_PASSWORD}\r\"
expect \"Re-enter new password: \"
send \"${MYSQL_ROOT_PASSWORD}\r\"
expect \"Remove anonymous users? \[Y/n\] \"
send \"y\r\"
expect \"Disallow root login remotely? \[Y/n\] \"
send \"y\r\"
expect \"Remove test database and access to it? \[Y/n\] \"
send \"y\r\"
expect \"Reload privilege tables now? \[Y/n\] \"
send \"y\r\"
expect eof
")

echo $SECURE_MYSQL

mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE ejbca CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ejbca.* TO 'ejbca'@'localhost' IDENTIFIED BY '${EJBCA_MYSQL_PASSWORD}';"
mysql -u ejbca -p${EJBCA_MYSQL_PASSWORD} ejbca < /tmp/database-config/create-tables-ejbca-mysql.sql
mysql -u ejbca -p${EJBCA_MYSQL_PASSWORD} ejbca < /tmp/database-config/create-index-ejbca.sql
