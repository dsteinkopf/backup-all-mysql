#!/bin/bash

if [[ ! -v BACKUP_INTERVAL ]] ; then
  BACKUP_INTERVAL=$((3600*24))   # default 24 hours
fi


while true ; do
	# truncate the errorsfile. So if it is empty then everything is ok
	cat /dev/null > /var/dbdumps/errorslastrun.log

	./backup-all-mysql.sh "$@"

	# TODO: sleep BACKUP_INTERVAL minus duration of last dump
	echo "sleeping $BACKUP_INTERVAL seconds"
	sleep $BACKUP_INTERVAL
done
