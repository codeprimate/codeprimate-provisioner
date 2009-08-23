#!/bin/bash

printf "Server Provisioner\n===================\n"

if [ "$1" ]; then
	SERVER = $!
else
	read -p "? Host Name or Address: " SERVER
	read -p "? App username: " USERNAME
fi
if [ ! "$SERVER" ] ; then
	printf "What server??? You fail.\n"
	exit 1
fi
if [ ! "$USERNAME" ] ; then
	printf "What user??? You fail.\n"
	exit 1
fi


# Regenerate Bundle
printf " * Initializing...\n"
PROVISIONER_PATH=`dirname $0`
PROVISIONER_BUNDLE=/tmp/$SERVER/bundle.tgz
PROVISIONER_BUNDLE_TMP=/tmp/$SERVER
cd $PROVISIONER_PATH
if [ ! -e "$PROVISIONER_PATH/bundle" ] ; then
	printf "!!! COULD NOT FIND BUNDLE FILES!!!"
	exit 1
fi
if [ -e "$PROVISIONER_BUNDLE" ] ; then
	rm $PROVISIONER_BUNDLE
fi
if [ -e "$PROVISIONER_BUNDLE_TMP" ] ; then
	rm -rf $PROVISIONER_BUNDLE_TMP
fi
mkdir -p $PROVISIONER_BUNDLE_TMP
cp -r $PROVISIONER_PATH/bundle $PROVISIONER_BUNDLE_TMP
SERVER_CONF=$PROVISIONER_BUNDLE_TMP/bundle/bundle-conf.txt
if [ -e "$SERVER_CONF" ] ; then
	rm $SERVER_CONF
fi
touch $SERVER_CONF
printf "user: %s\nhost: %s" $USERNAME $SERVER >> $SERVER_CONF
cd $PROVISIONER_BUNDLE_TMP
tar czf $PROVISIONER_BUNDLE bundle/

printf " * Copying public key to server...\n"
if [ -e ~/.ssh/id_dsa.pub  -o -e ~/.ssh/id_rda.pub ] ; then
	ssh root@$SERVER "mkdir ~/.ssh; mkdir bundle; echo "`cat ~/.ssh/id_dsa.pub ~/.ssh/id_rsa.pub`" >> ~/.ssh/authorized_keys2"
fi

printf " * Copying Server Setup Bundle...\n"
scp -q $PROVISIONER_BUNDLE root@$SERVER:/root/bundle.tgz

printf " * Extract and run Server Setup Bundle..."
ssh root@$SERVER "tar xzf bundle.tgz; cd bundle; chmod u+x ./installer.sh; ./installer.sh"

printf "Finished!!!\n\n"
printf "Result log\n------------------------\n\n"
ssh root@$SERVER "cat /root/bundle/log.txt"
printf "\n\n--------------------------------\nEND."


# Cleanup
rm -rf $PROVISIONER_BUNDLE
rm -rf $PROVISIONER_BUNDLE_TMP

exit 0

