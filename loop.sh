#!/bin/bash

set -x

echo "sleeping $BACKUP_FIRSTDELAY seconds before first backup"
sleep $BACKUP_FIRSTDELAY

while true ; do
    # truncate the errorsfile. So if it is empty then everything is ok
    # (BTW. truncate always touches the modification time of the file.)
    truncate --size=0 /var/dbdumps/errorslastrun.log


    if [ -z "$MYSQL_CONNECTION_PARAMS" ] ; then
        MYSQL_CONNECTION_PARAMS="--host=$MYSQL_HOST --user=$MYSQL_USER --password=$MYSQL_ENV_MYSQL_ROOT_PASSWORD"
    fi
    ./backup-all-mysql.sh "$@" $MYSQL_CONNECTION_PARAMS


    # TODO: sleep BACKUP_INTERVAL minus duration of last dump
    echo "sleeping $BACKUP_INTERVAL seconds"
    sleep $BACKUP_INTERVAL
done
