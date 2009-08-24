#!/bin/bash
# Installer for Ubuntu 9.04

BUNDLE_PATH=/root/bundle
LOG_PATH=$BUNDLE_PATH/log.txt

INSTALL_PACKAGES="pwgen build-essential ruby1.8 ruby1.8-dev ri1.8 rdoc1.8 irb1.8 libreadline-ruby1.8 libruby1.8 libopenssl-ruby mysql-server mysql-client libmysqlclient15-dev libmagickcore-dev libmagickwand-dev apache2 postfix git-core subversion apache2-prefork-dev libapr1-dev libaprutil1-dev"
INSTALL_GEMS="rmagick mysql mongrel rails passenger liquid"

USERNAME=`cat $BUNDLE_PATH/bundle-conf.txt | grep user | awk '{print $2}'`
HOSTNAME=`cat $BUNDLE_PATH/bundle-conf.txt | grep host | awk '{print $2}'`

# Misc Setup
function misc_setup {
	printf "\n=== Setting up..."
	hostname  "$HOSTNAME"
	locale-gen en_US.UTF-8
	/usr/sbin/update-locale LANG=en_US.UTF-8
}

function install_software {
	printf "\n=== Updating and installing software...\n"
	apt-get update
	apt-get upgrade -y
	apt-get install -y `echo $INSTALL_PACKAGES`

	ln -sf /usr/bin/ruby1.8 /usr/local/bin/ruby
	ln -sf /usr/bin/rdoc1.8 /usr/local/bin/rdoc
	ln -sf /usr/bin/ri1.8 /usr/local/bin/ri
	ln -sf /usr/bin/irb1.8 /usr/local/bin/irb
}

function mysql_setup {
	printf "\n=== Configuring MySQL and Application Database...\n"
	MYSQL_ROOT_PW="`pwgen 10 1`"
	MYSQL_USER_PW="`pwgen 10 1`"
	sed -e "s/USERNAME/$USERNAME/g" -e "s/PASSWORD/$MYSQL_USER_PW/g" $BUNDLE_PATH/mysql.sql > $BUNDLE_PATH/mysql_setup.sql
	mysql -u root < $BUNDLE_PATH/mysql_setup.sql
	mysqladmin -u root password "$MYSQL_ROOT_PW"
	cat $BUNDLE_PATH/database.yml | sed -e "s/USERNAME/$USERNAME/g" -e "s/PASSWORD/$MYSQL_USER_PW/g" > /home/$USERNAME/site/production/shared/database.yml
	printf "\nMySQL Root Password: %s\nMySQL %s password: %s" "$MYSQL_ROOT_PW" "$USERNAME" "$MYSQL_USER_PW" >> $LOG_PATH
}

function rubygems_setup {
printf "\n===  Installing rubygems...\n"
	cd "$BUNDLE_PATH/rubygems"
	ruby setup.rb
	ln -sf /usr/bin/gem1.8 /usr/local/bin/gem
	gem source -a "http://gems.github.com/"
	gem update --system
	for gemname in "`echo $INSTALL_GEMS`"; do gem install $gemname --no-rdoc --no-ri;  done
}

function create_application_user {
	printf "\n=== Create Application User => $USERNAME\n"
	# adduser $USERNAME --disabled-password --home /home/$USERNAME --shell /bin/bash
	useradd -m -p xxxx -s /bin/bash -g www-data $USERNAME
	mkdir -p /home/$USERNAME/site/production/shared
	mkdir -p /home/$USERNAME/.ssh
	cat /root/.ssh/authorized_keys2 > /home/$USERNAME/.ssh/authorized_keys2
	chown -R $USERNAME /home/$USERNAME
	su $USERNAME -c "ssh-keygen -q -P '' -t rsa -f /home/$USERNAME/.ssh/id_rsa"
	chown -R "$USERNAME:www-data" /home/$USERNAME
	chmod go-rwX /home/$USERNAME/.ssh
	printf "\n\n=== %s Public Key:\n%s\n\n" $USERNAME `cat /home/$USERNAME/.ssh/id_rsa.pub` >> $LOG_PATH
}

function apache_setup {
	printf "\n===  Setting Up Apache...\n"
	PASSENGER_VERSION="`gem list | grep passenger | sed  -n 's/.*(\([0-9]\{1,2\}.[0-9]\{1,2\}\.[0-9]\{1,2\}\)).*/\1/p'`"
	cat $BUNDLE_PATH/passenger.conf | sed "s/PASSENGER_VERSION/$PASSENGER_VERSION/" > /etc/apache2/mods-available/passenger.conf
	ln -sf /etc/apache2/mods-available/passenger.conf /etc/apache2/mods-enabled/passenger.conf
	cat $BUNDLE_PATH/vhost | sed -e "s/USERNAME/$USERNAME/" -e "s/HOSTNAME/$HOSTNAME/" > /etc/apache2/sites-available/$USERNAME.vhost
	ln -sf /etc/apache2/sites-available/$USERNAME.vhost /etc/apache2/sites-enabled/$USERNAME.vhost

	APACHE_SERVERNAME="ServerName $HOSTNAME"
	APACHE_CONF="/etc/apache2/apache2.conf"
	if [ ! "`grep "$APACHE_SERVERNAME" $APACHE_CONF`" ] ; then
		echo $APACHE_SERVERNAME >> $APACHE_CONF
	fi

	passenger-install-apache2-module -a
	/etc/init.d/apache2 restart
}


misc_setup
install_software
rubygems_setup
create_application_user
mysql_setup
apache_setup