create database USERNAME;
grant all privileges on USERNAME.* to 'USERNAME'@'localhost' identified by 'PASSWORD';
flush privileges;
