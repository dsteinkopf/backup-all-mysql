#!/bin/bash

if [[ ! -v BACKUP_INTERVAL ]] ; then
  BACKUP_INTERVAL=$((3600*24))   # default 24 hours
fi
if [[ ! -v BACKUP_FIRSTDELAY ]] ; then
  BACKUP_FIRSTDELAY=0   # default: immediately
fi


set -x

echo "sleeping $BACKUP_FIRSTDELAY seconds before first backup"
sleep $BACKUP_FIRSTDELAY

while true ; do
    # truncate the errorsfile. So if it is empty then everything is ok
    cat /dev/null > /var/dbdumps/errorslastrun.log


    if [ $# -eq 0 ] ; then
        if [ -z "$MYSQL_CONNECTION_PARAMS" ] ; then
            MYSQL_CONNECTION_PARAMS="--host=mysql --user=root --password=$MYSQL_ENV_MYSQL_ROOT_PASSWORD"
        fi
        ./backup-all-mysql.sh $MYSQL_CONNECTION_PARAMS
    else
        ./backup-all-mysql.sh "$@"
    fi

    # TODO: sleep BACKUP_INTERVAL minus duration of last dump
    echo "sleeping $BACKUP_INTERVAL seconds"
    sleep $BACKUP_INTERVAL
done
