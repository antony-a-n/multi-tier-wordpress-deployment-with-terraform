#!/bin/bash
db_root_password=qwertyuiop@123
db_name=wp_db
db_user=dbuser
db_password=wp123
sudo yum update all -y
sudo yum install mariadb-server -y
sudo systemctl restart mariadb.service
sudo systemctl enable mariadb.service
mysql -u root <<EOF

UPDATE mysql.user SET Password=PASSWORD('$db_root_password') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

mysql -e  "CREATE DATABASE $db_name" -u root -p$db_root_password
mysql -e  "CREATE USER '$db_user'@'%' IDENTIFIED BY '$db_password'" -u root -p$db_root_password
mysql -e  "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%'" -u root -p$db_root_password
mysql -e  "FLUSH PRIVILEGES" -u root -p$db_root_password
sudo systemctl restart mariadb.service
