#!/usr/bin/env bash

PARAM=$1

SERVER="devopsint2@192.168.2.51"

DATE="$(date +'%d_%m_%Y_%H_%M')"
BACKUP_FOLDER="/home/kostiantyn/backup"

# Apache2 conf file credentials
CONF="/etc/apache2/apache2.conf"
FILENAME=`basename $CONF .conf`
BACKUP_FILE="$FILENAME"_"$DATE.conf"
FULL_PATH_BACKUP_FILE="$BACKUP_FOLDER/$BACKUP_FILE"

find $BACKUP_FOLDER -name "$FILENAME*" -type f -amin +6 -delete
rsync -e ssh -a --delete $SERVER:$CONF $FULL_PATH_BACKUP_FILE

# Wordpress credentials
WP_CONTENT="/var/www/html/"
WEEKLY_BACKUP="weekly_wp-content_$DATE.tar.gz"
DALY_BACKUP="wp-content_$DATE.tar.gz"

if [ "$PARAM" == "dd" ]; then
#Daly differencial Backup

    find $BACKUP_FOLDER -name "wp-content*" -type f -mmin +6 -delete

    ssh $SERVER "cd $WP_CONTENT && tar cvzf $DALY_BACKUP wp-content; echo $?"

    rsync -ab --delete -e ssh $SERVER:$WP_CONTENT$DALY_BACKUP "$BACKUP_FOLDER/"

    ssh $SERVER "cd $WP_CONTENT && rm $DALY_BACKUP"; echo "rm ok"

elif [ "$PARAM" == "di" ]; then
#Daly incremental Backup

    OLD_WP=$( basename `find $BACKUP_FOLDER -name "wp-content*"`)

    ssh $SERVER "cd $WP_CONTENT && tar cvzf $DALY_BACKUP wp-content; echo $?"

    rsync -av --delete -e ssh $SERVER:$WP_CONTENT$DALY_BACKUP "$BACKUP_FOLDER/$OLD_WP"

    ssh $SERVER "cd $WP_CONTENT && rm $DALY_BACKUP"; echo "rm ok"

    mv $BACKUP_FOLDER/$OLD_WP $BACKUP_FOLDER/$DALY_BACKUP; echo "update ok"


elif [ "$PARAM" == "w" ]; then
# Weekly backup

    if [[ ! `find $BACKUP_FOLDER -name 'weekly_wp-content*'` ]]; then
        ssh $SERVER "cd $WP_CONTENT && tar cvzf $WEEKLY_BACKUP wp-content; echo $?"
        rsync -ab -e ssh $SERVER:$WP_CONTENT$WEEKLY_BACKUP  "$BACKUP_FOLDER"
        ssh $SERVER "cd $WP_CONTENT && rm $WEEKLY_BACKUP"; echo "rm ok"
    elif [[ `find $BACKUP_FOLDER -name 'weekly_wp-content*' -cmin +5` ]]; then
        find $BACKUP_FOLDER -name "weekly_wp-content*"  -mmin +6 -delete
        ssh $SERVER "cd $WP_CONTENT && tar cvzf $WEEKLY_BACKUP wp-content; echo $?"
        rsync -ab -e ssh $SERVER:$WP_CONTENT$WEEKLY_BACKUP  "$BACKUP_FOLDER"
        ssh $SERVER "cd $WP_CONTENT && rm $WEEKLY_BACKUP"; echo "rm ok"
    fi
else
    echo "Unknown parameter"
fi

# MySQL database credentials
DB_USER="wp_user"
DB_PASS="1111"
DB_NAME="wordpress"
DB_FILE="$DB_NAME"_"$DATE.sql"

find $BACKUP_FOLDER -name "$DB_NAME*" -type f -mmin +6 -delete
ssh $SERVER mysqldump -u$DB_USER -p$DB_PASS $DB_NAME | gzip > "$BACKUP_FOLDER/$DB_FILE.gz"


