Regular backup an DB found in the mysql linked as "mysql" to the voloume `/var/dbdumps`.

* Interval may be set via environment `BACKUP_INTERVAL`.
* Use `BACKUP_FIRSTDELAY` to delay the very first backup to be done by n seconds. The idea behind this is to prevent existing backups to be overwritten in case of problems. So you can manually kill everything an try again within this delay.
* MYSQLDUMP_ADD_OPTS (default = ""): More options to be added to mysqldump.
* MYSQL_CONNECTION_PARAMS (default = ""): More mysql option to add to any mysql command (incl. mysqldump)
* MYSQL_HOST (default = "mysql"): Hostname (or IP) of mysql database.
* MYSQL_USER (default = "root"): Username to connect to mysql database.


So you have to:

* run the container `dsteinkopf/backup-all-mysql``
* create a link called `mysql` to you db to be backed up.
* Create a volume called `/var/dbdumps`.

Usage example: In docker-compose.yml:

```
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

-> for example found in [my Zabbix Setup](https://nerdblog.steinkopf.net/2017/01/zabbix-monitoring-leicht-aufgesetzt/) (German language)
