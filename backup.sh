#!/usr/bin/env bash

SERVER="devopsint2@192.168.2.51"
DATE="$(date +'%d_%m_%Y_%H_%M_%S')"
BACKUP_FOLDER="/home/kostiantyn/backup"

# Apache2 conf file credentials
CONF="/etc/apache2/apache2.conf"
FILENAME=`basename $CONF .conf`
BACKUP_FILE="$FILENAME'_'$DATE.conf"
FULL_PATH_BACKUP_FILE="$BACKUP_FOLDER/$BACKUP_FILE"

find $BACKUP_FOLDER -name "$FILENAME*" -type f -amin +5 -delete
rsync -e ssh -a --delete $SERVER:$CONF $FULL_PATH_BACKUP_FILE

# Wordpress credentials
WP_CONTENT="/var/www/html/wp-content"
WEEKLY_BACKUP="$BACKUP_FOLDER/weekly_wp-content_$DATE.tar.gz"
DALY_BACKUP="$BACKUP_FOLDER/daly_wp-content_$DATE.tar.gz"

find $BACKUP_FOLDER -name "daly_wp-content*" -type f -mmin +5 -delete
ssh $SERVER "tar cvzf - $WP_CONTENT" | cat > $DALY_BACKUP

if [[ ! `find $BACKUP_FOLDER -name 'weekly_wp-content*'` ]]; then
  ssh $SERVER "tar cvzf - $WP_CONTENT" | cat > $WEEKLY_BACKUP
elif [[ `find $BACKUP_FOLDER -name 'weekly_wp-content*' -cmin +5` ]]; then
  find $BACKUP_FOLDER -name "weekly_wp-content*" -type f -delete
  ssh $SERVER "tar cvzf - $WP_CONTENT" | cat > $WEEKLY_BACKUP
fi

# MySQL database credentials
DB_USER="wp_user"
DB_PASS="1111"
DB_NAME="wordpress"
DB_FILE="$DB_NAME'_'$DATE.sql"

find $BACKUP_FOLDER -name "$DB_NAME*" -type f -mmin +5 -delete
ssh $SERVER mysqldump -u$DB_USER -p$DB_PASS $DB_NAME | gzip > "$BACKUP_FOLDER/$DB_FILE.gz"


