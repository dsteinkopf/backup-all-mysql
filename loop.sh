#!/bin/bash

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env(){
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env 'MYSQL_ENV_MYSQL_ROOT_PASSWORD'

echo "sleeping $BACKUP_FIRSTDELAY seconds before first backup"
sleep $BACKUP_FIRSTDELAY

while true ; do
    # truncate the errorsfile. So if it is empty then everything is ok
    # (BTW. truncate always touches the modification time of the file.)
    truncate --size=0 /var/dbdumps/errorslastrun.log


    if [ -z "$MYSQL_CONNECTION_PARAMS" ] ; then
        MYSQL_CONNECTION_PARAMS="--host=$MYSQL_HOST --user=$MYSQL_USER --password=$MYSQL_ENV_MYSQL_ROOT_PASSWORD"
    fi
    echo "start backup"
    ./backup-all-mysql.sh "$@" $MYSQL_CONNECTION_PARAMS


    # TODO: sleep BACKUP_INTERVAL minus duration of last dump
    echo "sleeping $BACKUP_INTERVAL seconds"
    sleep $BACKUP_INTERVAL
done
