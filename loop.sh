#!/bin/bash

set -x

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

file_env 'MYSQL_PASSWORD'
file_env 'MYSQLDUMP_ADD_OPTS'
file_env 'MYSQL_CONNECTION_PARAMS'
file_env 'MYSQL_HOST'
file_env 'MYSQL_USER'

if [ -z "$MYSQL_PASSWORD" ] ; then
    MYSQL_PASSWORD="$MYSQL_ENV_MYSQL_ROOT_PASSWORD"
fi


echo "sleeping $BACKUP_FIRSTDELAY seconds before first backup"
sleep $BACKUP_FIRSTDELAY

while true ; do
    # truncate the errorsfile. So if it is empty then everything is ok
    # (BTW. truncate always touches the modification time of the file.)
    truncate --size=0 /var/dbdumps/errorslastrun.log


    if [ -z "$MYSQL_CONNECTION_PARAMS" ] ; then
        echo << EOF > /tmp/my.cnf
[client]
user = $MYSQL_USER
password = $MYSQL_PASSWORD
host = $MYSQL_HOST
EOF
        cat /tmp/my.cnf

        MYSQL_CONNECTION_PARAMS="--defaults-extra-file=/tmp/my.cnf"
    fi
    echo "start backup"
    ./backup-all-mysql.sh "$@" $MYSQL_CONNECTION_PARAMS


    # TODO: sleep BACKUP_INTERVAL minus duration of last dump
    echo "sleeping $BACKUP_INTERVAL seconds"
    sleep $BACKUP_INTERVAL
done
