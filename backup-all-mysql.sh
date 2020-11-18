#!/bin/bash
#
# in /root/.my.cnf muss stehen:
#
#   [mysqldump]
#   password = ********
#
# ODER: die connection-Parameter werden übergeben (beachte das fehlende "=" bei subdir):
#
#   backup-all-mysql.sh --subdir myhost --host=myhost --user=root --password=abcdef 

#
# Effizient importieren kann man dann mit
#
# echo "CREATE DATABASE neuedb; " | mysql &&\
#     ( echo "SET AUTOCOMMIT=0;SET UNIQUE_CHECKS=0;" ;\
#         cat altedb.sql ;\
#         echo "SET UNIQUE_CHECKS=1; COMMIT;" \
#     ) | mysql neuedb
#
# Oder so ähnlich. (vgl. http://dev.mysql.com/doc/refman/4.1/en/innodb-tuning.html)
#

#set -x


DBDUMPSDIR=/var/dbdumps
ERRORFILELASTRUN=$DBDUMPSDIR/errorslastrun.log
TMPFILE=$DBDUMPSDIR/.dump.$$
ERRORFILE=/tmp/mysql_backup_error.$$


function aterror() {
    rm -f "$TMPFILE"
    echo >>$ERRORFILELASTRUN "$(date): $0 aborted."
}
trap aterror EXIT # unset below on normal script end


# falsch!
#MYSQLOPTS="--skip-opt --quick --add-locks --all --lock-tables"
# das abschalten von opt bewirkt, das _keine_ create-options - und
# damit keine informationen
# ueber den Charset vorhanden sind.
# Weil die Reihenfolge in der optionen ein/ausgeschalten werden relevant ist
# muessen wir
# 1. mit --skip-opt zunaechst _alles_ abschalten
# 2. alles bis aus --extended-insert (fuer zeilenweiseinserts) wieder einschalten
#  somit ergibt sich:

MYSQLOPTS=" --skip-opt --add-drop-table --add-locks --create-options --set-charset --disable-keys --quick --default-character-set=utf8 --routines --hex-blob --column-statistics=0"
if [ ! -z "$MYSQL_CONNECTION_PARAMS" ] ; then
    MYSQLOPTS="$MYSQLOPTS $MYSQLDUMP_ADD_OPTS"
fi


if [ -e /etc/backup-all-mysql.conf ] ; then
    . /etc/backup-all-mysql.conf
fi


# 2007-02-09 mku@wor.net: rausgenommen da im fehlerfall weitergemacht werden soll
# set -e


if [ _$1 = _--total ]; then
    TOTAL=1
    shift
else
    TOTAL=0
fi

if [ _$1 = _--subdir ]; then
    DBDUMPSDIR="$DBDUMPSDIR/$2"
    shift
    shift
fi

if [ _$1 = _--skip-tables ]; then
    SKIP_TABLES="$2"
    shift
    shift
else
    SKIP_TABLES=""
fi

MYSQL_CONNECTION_PARAMS="$@"

if [ ! -d $DBDUMPSDIR ]; then
    mkdir -p $DBDUMPSDIR
    chmod 700 $DBDUMPSDIR
    chown root.root $DBDUMPSDIR
fi


# Backup all MySQL databases, each in one file
dbs=$(echo "show databases;" | mysql --raw --skip-column-names $MYSQL_CONNECTION_PARAMS 2>$ERRORFILE | grep -vi '_schema$') || error=true
if [ ! -z "$error" ] ; then
    cat $ERRORFILE | tee --append $ERRORFILELASTRUN
    exit 1
fi
for db in $dbs
do
    if [ ! -z "$SKIP_TABLES" ] ; then
        tables=$(echo "show tables" \
                | mysql --raw --skip-column-names $MYSQL_CONNECTION_PARAMS $db 2>$ERRORFILE \
                | egrep -v "$SKIP_TABLES"\
                ) || error=true
        if [ ! -z "$error" ] ; then
            cat $ERRORFILE | tee --append $ERRORFILELASTRUN
            exit 1
        fi
    else
        tables=""
    fi

    DESTFILE=$DBDUMPSDIR/mysqldump_$db.sql.bz2
    DESTFILE_TMP=$DESTFILE.tmp

    #the database named "mysql" can't be locked
    #mysqldump: Got error: 1556: You can't use locks with log tables when using LOCK TABLES
    CURRENT_OPTS="$MYSQLOPTS"
    if [ "$db" != "mysql" ] ; then
        CURRENT_OPTS="--lock-tables $CURRENT_OPTS";
    fi 


    if [ "$tables" = "" ] ; then
        echo "start backup of $db" 
    else
        echo "start backup of $db.$tables" 
    fi

    if [ ${USE_PIPE_TO_BZ:-1} = "1" ] ; then
        set -o pipefail
        ( echo "SET NAMES 'utf8';" ; \
            /usr/bin/mysqldump $MYSQL_CONNECTION_PARAMS $CURRENT_OPTS $db $tables 2>$ERRORFILE \
        ) | nice lbzip2 --stdout > $DESTFILE_TMP && mv $DESTFILE_TMP $DESTFILE \
        || cat $ERRORFILE | tee --append $ERRORFILELASTRUN
    else
        # Don't use pipe to bzip if mysqldump must be fast (locks!)
        echo "SET NAMES 'utf8';" > $TMPFILE
        /usr/bin/mysqldump $MYSQL_CONNECTION_PARAMS $CURRENT_OPTS $db $tables 2>$ERRORFILE 1>>$TMPFILE  || \
            cat $ERRORFILE | tee --append $ERRORFILELASTRUN
        nice lbzip2 --stdout < $TMPFILE > $DESTFILE_TMP && mv $DESTFILE_TMP $DESTFILE
    fi
done

if [ $TOTAL -eq 1 ]; then
    # backup all databases for total recovery
    # Don't use pipe to bzip - mysqldump must be fast (locks!)

    DESTFILE=$DBDUMPSDIR/mysqldump_all_databases.sql.bz2
    DESTFILE_TMP=$DESTFILE.tmp

    echo "start backup of all databases" 
    echo "SET NAMES 'utf8';" > $TMPFILE
    CURRENT_OPTS="$MYSQLOPTS --lock-tables";
    /usr/bin/mysqldump $MYSQL_CONNECTION_PARAMS $CURRENT_OPTS --all-databases  2>$ERRORFILE >>$TMPFILE || \
        cat $ERRORFILE | tee --append $ERRORFILELASTRUN
        #cat $ERRORFILE  | mail -s "Error from $0: DB backup of ALL failed" $ERROREMAILTO
    cat $TMPFILE | bzip2 --stdout > $DESTFILE_TMP && mv $DESTFILE_TMP $DESTFILE
fi

rm -f $TMPFILE
rm $ERRORFILE

# make the backup readable only by root
/bin/chmod 600 $DBDUMPSDIR/mysqldump*sql.bz2

trap - EXIT # no trap on normal script end
trap

