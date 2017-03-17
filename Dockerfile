FROM ubuntu

MAINTAINER Dirk Steinkopf "https://github.com/dsteinkopf"

# Update
RUN apt-get update && \
	apt-get -y dist-upgrade && \
	apt-get -y autoremove && \
	apt-get clean && \
	apt-get install -y \
		mysql-client \
		bzip2

RUN mkdir /var/dbdumps
VOLUME /var/dbdumps

ADD loop.sh /loop.sh
RUN chmod 0755 /loop.sh

ENV BACKUP_INTERVAL= \
    BACKUP_FIRSTDELAY= \
    MYSQLDUMP_ADD_OPTS= \
    MYSQL_CONNECTION_PARAMS=

ADD backup-all-mysql.sh /backup-all-mysql.sh
RUN chmod 0755 /backup-all-mysql.sh

ADD backup-all-mysql.conf /etc/backup-all-mysql.conf

ENTRYPOINT ["/loop.sh"]
