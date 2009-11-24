#!/bin/bash
BACKUP_DEST=/home/USERNAME/backups
DATE=`date "+%y%m%d"`
DB_BACK=$BACKUP_DEST/$DATE-db.sql.gz
/usr/bin/mysqldump --password=MYSQL_USER_PW -u USERNAME -KQ --add-drop-table USERNAME | gzip > $DB_BACK