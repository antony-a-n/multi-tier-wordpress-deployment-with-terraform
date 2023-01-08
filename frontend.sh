#!/bin/bash
sudo yum update all -y
sudo yum install httpd -y
amazon-linux-extras install php7.4
sudo systemctl restart httpd
sudo systemctl enable httpd
cd /var/www/html
sudo chown -R apache:apache /var/www/html/*
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
cp -rf wordpress/* /var/www/html/
mv wp-config-sample.php wp-config.php
sed -i "s/database_name_here/${db_name}/;s/username_here/${db_user}/;s/password_here/${db_password}/;s/localhost/${domain}/" wp-config.php
sudo systemctl stop httpd
sudo systemctl restart httpd   
