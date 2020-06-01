#!/usr/bin/env bash

export DA_WORKDIR="/var/www"
export DA_BACKUPDIR="/var/www-backup"

cli_help() {
	echo "
Backup of the whole the Web-Server.

This will save all mysql databases, apache vhost configurations and files under /var/www.
"
	exit 1
}

#prepare backup folder
da_prepare_backup() {
	mkdir -p "$DA_BACKUPDIR"
	mkdir -p "$DA_BACKUPDIR/data"
	mkdir -p "$DA_BACKUPDIR/db"
	mkdir -p "$DA_BACKUPDIR/vhosts"
}

da_get_databases() {
	mysql -e 'SHOW DATABASES;' --batch --skip-column-names \
	| grep -v "mysql" | grep -v "sys" | grep -v "_schema"
}

case "$1" in
	help|--help|-h|-?)
		cli_help
		;;
	*)
		echo 'Backup started'

		#create empty folders
		da_prepare_backup

		#dump databases
		for DB in $(da_get_databases)
		do
			mysqldump $DB > "$DA_BACKUPDIR/db/$DB.sql"
		done

		#copy vhost configurations
		rsync -az --delete "/etc/apache2/sites-available" "$DA_BACKUPDIR/vhosts/"
		rsync -az --delete "/etc/apache2/sites-enabled" "$DA_BACKUPDIR/vhosts/"

		#copy files
		rsync -az --delete "$DA_WORKDIR/" "$DA_BACKUPDIR/data/"

		echo 'Backup finished'
		;;
esac
