#!/usr/bin/env bash

SERVER="devopsint2@192.168.2.51"
BACKUP_FOLDER="/home/kostiantyn/backup"

CONF="/etc/apache2/apache2.conf"

# Mysql credentials
DB_USER="wp_user"
DB_PASS="1111"
DB_NAME="wordpress"
DB_FILE="$DB_NAME"_"$DATE.sql"

# Wordpress credentials
WP_CONTENT="/var/www/html"

echo "Do you want to start restore DATA? yes(y)/no(n) \c"
read choice

case "$choice" in

    y)
        cd $BACKUP_FOLDER/
        mkdir temp_restore
        echo "Step 1) Restore Apache conf file. Type 'y' to restore data or no to cancel this step:"
            read choice

            case "$choice" in
                y)
                    echo "Enter date for restore apache conf. in format 'day_month_year' :"
                    for ((i=0; i<3; i++)) ; do

                        read date

                        FILE="apache2_$date.conf"

                        if [ -f "$FILE" ]; then
                            echo "$FILE ok"

                            mv $FILE temp_restore

                            echo "move to temp dir ok"
                            break
                        fi

                        if [ ! -f "$FILE" ]; then
                            echo "$FILE does not exist"
                            echo "try again"
                        fi

                        if [[ "$i" == 2 && ! -f "$FILE" ]]; then
                            exit
                        fi
                    done
                    ;;
                n)
                    echo "step 1 canceled"
                    ;;
            esac
        echo "Step 2) Restore MySQL Data. Type 'y' to restore data or no to cancel this step:"
            read choice

            case "$choice" in
                y)
                    echo "Enter date for restore mysql data in format 'day_month_year' :"
                    for ((i=0; i<3; i++)) ; do
                        read date

                        MYSQL_DATA="wordpress_$date.sql.gz"

                        if [ -f "$MYSQL_DATA" ]; then
                            echo "$MYSQL_DATA ok"

                            mv $MYSQL_DATA temp_restore

                            echo "move to temp dir ok"
                            break
                        fi

                        if [ ! -f "$MYSQL_DATA" ]; then
                            echo "$MYSQL_DATA does not exist"
                            echo "try again"
                        fi

                        if [[ "$i" == 2 && ! -f "$MYSQL_DATA" ]]; then
                            exit
                        fi
                    done
                    ;;
                n)
                    echo "step 1 canceled"
                    ;;
            esac

        echo "Step 3) Restore Wordpress Content Data. Type 'y' to restore data or no to cancel this step::"
            read choice

            case "$choice" in
                y)
                    echo "Enter date for restore wp-content data in format 'day_month_year':"
                    for ((i=0; i<3; i++)) ; do
                        read date

                        CONTENT=$(basename `find . -name "*_wp-content_$date.tar.gz"`)

                        if [ -f "$CONTENT" ]; then
                            echo "$CONTENT ok"

                            mv $CONTENT temp_restore
                            #echo "starting to restore WP-Content data"

                            #cat $BACKUP_FOLDER/$CONTENT | ssh $SERVER "tar xzf - -C /home/devopsint2/backup"

                            echo "move to temp dir ok"
                            break
                        fi

                        if [ ! -f "$CONTENT" ]; then
                            echo "$CONTENT does not exist"
                            echo "try again"
                        fi

                        if [[ "$i" == 2 && ! -f "$CONTENT" ]]; then
                            exit
                        fi
                        done
                        ;;
                n)
                    echo "step canceled"
                    ;;
            esac
            ;;

    n)
        echo "canceled"
        exit
        ;;
    *)
        echo "$choice is not a valid choice"
        exit
        ;;
esac

echo "Preparing data to restoring"

cd temp_restore


    APACHE=$(basename `find $BACKUP_FOLDER/temp_restore -name "apache2*.conf"`)
    if [ -f "$APACHE" ]; then
        echo "$APACHE ok"

        echo "starting to restore Apache conf file"
        sudo rsync -rltvz -e "ssh" $BACKUP_FOLDER/temp_restore/$APACHE $SERVER:$CONF

        echo "Restoring OK"
        fi
        if [ ! -f "$APACHE" ]; then
        echo "APACHE will not restore"
        fi

    MySQL=$(basename `find $BACKUP_FOLDER/temp_restore -name "wordpress*.sql.gz"`)
    if [ -f "$MySQL" ]; then
        echo "$MySQL ok"

        echo "starting to restore MySQL Data"
        zcat $BACKUP_FOLDER/temp_restore/$MySQL |ssh $SERVER mysql -u$DB_USER -p$DB_PASS $DB_NAME

        echo "Restoring OK"
        fi
    if [ ! -f "$MySQL" ]; then
        echo "MySQL will not restore"
        fi
    WP=$(basename `find $BACKUP_FOLDER/temp_restore -name "*_wp-content*.tar.gz"`)

        if [ -f "$WP" ]; then
            echo "$WP ok"

            echo "starting to restore WP-Content data"

            cat $BACKUP_FOLDER/temp_restore/$WP | ssh $SERVER "tar xzf - -C $WP_CONTENT"

            echo "Restoring OK"
        fi
        if [ ! -f "$WP" ]; then
        echo "WP will not restore"
        fi

        rm -rf "$BACKUP_FOLDER/temp_restore/"