
Regular backup an DB found in the mysql linked as "mysql" to the voloume `/var/dbdumps`.

### Setup

You have to:

* run the container `dsteinkopf/backup-all-mysql`
* create a link called `mysql` to you db to be backed up.
* Create a volume called `/var/dbdumps`.

### Environment

* Interval may be set via environment `BACKUP_INTERVAL` (in seconds).
* Use `BACKUP_FIRSTDELAY` to delay the very first backup to be done by n seconds. The idea behind this is to prevent existing backups to be overwritten in case of problems. So you can manually kill everything an try again within this delay.
* MYSQLDUMP_ADD_OPTS (default = ""): More options to be added to mysqldump.
* MYSQL_CONNECTION_PARAMS (default = ""): More mysql option to add to any mysql command (incl. mysqldump)
* MYSQL_HOST (default = "mysql"): Hostname (or IP) of mysql database.
* MYSQL_USER (default = "root"): Username to connect to mysql database.
* MYSQL_PASSWORD ( use MYSQL_ENV_MYSQL_ROOT_PASSWORD if available ): The password to connect to mysql .

**MYSQLDUMP_ADD_OPTS**, **MYSQL_CONNECTION_PARAMS**, **MYSQL_HOST**,  **MYSQL_USER** ,  **MYSQL_PASSWORD**, can be used with suffix `_FILE`, if stored in a file .
This is usefull for [docker secrets](https://docs.docker.com/engine/swarm/secrets/) (only available for swarm mode), or to hide sensitive data in general ( like **MYSQL_PASSWORD** ) . 

Example :
`MYSQL_PASSWORD_FILE=/run/secrets/mysql-root`
Will read the file `/run/secrets/mysql-root`, and copy the content in the env var `MYSQL_PASSWORD`

### Monitoring

For an easy monitoring of successful backup an error file `/var/dbdumps/errorslastrun.log` is created (in volume `/var/dbddumps`. This file contains errors if there were any - it is empty if everything was ok.

So to monitor correct backup you should

* check that `errorslastrun.log` is empty.
* chat that `errorslastrun.log` is touched (modification date changed) regularly (see env `BACKUP_INTERVAL`).

### Usage example

In docker-compose.yml:

```yml
mysql-backup:

  image: dsteinkopf/backup-all-mysql:latest
  environment:
    - BACKUP_INTERVAL=20000
    - BACKUP_FIRSTDELAY=3600
  links:
    - mysql
  restart: always
  volumes:
    - /opt/dockervolumes/wordpress/mysql-backup:/var/dbdumps
    - /etc/localtime:/etc/localtime
    - /etc/timezone:/etc/timezone
```
In docker-compose.yml, for swarm, with secrets ( secrets is already setup )  :
```yml
version: '3.2'

services:
  backup:
    image: dsteinkopf/backup-all-mysql:latest
    environment:
      - BACKUP_INTERVAL=21600 #6h
      - BACKUP_FIRSTDELAY=3600
      - MYSQL_HOST=mariadb
      - MYSQL_ENV_MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-pwd
    restart: always
    volumes:
      - /opt/dockervolumes/wordpress/mysql-backup:/var/dbdumps
      - /etc/localtime:/etc/localtime
      - /etc/timezone:/etc/timezone
    secrets:
      - mysql-pwd
      
  mariadb:
    image: mariadb:latest
    secrets:
      - mysql-pwd
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql-pwd

secrets:
  mysql-pwd:
    external: true
```

-> for example found in [my Zabbix Setup](https://nerdblog.steinkopf.net/2017/01/zabbix-monitoring-leicht-aufgesetzt/) (German language)
