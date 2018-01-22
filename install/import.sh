#! /bin/bash

# Run this script on the test server to:
#
# 1. Load previosly built docker containers on the test server.
# 2. Import a database dump and media exported from another wiki.
#
# The wiki database is on docker volume ikondb (on the host)
# The upload directory is in /local/docker/test-ikon/ikon-smw-stack/data/upload/media (on the host)
#

# Read configuration options
source config.ini

configure() {
	# read database root password from input, if not set in config.ini
	if [ -z ${MYSQL_ROOT_PASSWORD+x} ]; then read -s -p "Password for database root: " MYSQL_ROOT_PASSWORD; fi
	echo "";
	
	# read database password from input, if not set in config.ini
	if [ -z ${MYSQL_PASSWORD+x} ]; then read -s -p "Password for database user $MYSQL_USER: " MYSQL_PASSWORD; fi
	echo "";
		
	# read mediawiki database name from input, if not set in config.ini
	if [ -z ${MYSQL_DATABASE+x} ]; then read -p "Name of the database used by this mediawiki: " MYSQL_DATABASE; fi
	echo "";

	export SMW_CONTAINER
	export DB_CONTAINER
	export UPLOAD_MOUNT
	export DB_MOUNT
	export NETWORK
	export MYSQL_ROOT_PASSWORD
	export MYSQL_USER
	export MYSQL_PASSWORD
	export MYSQL_DATABASE
	export PORT
	export PORTDB
	export MW_DOCKERDIR
}

# Loads a database dump and media exported from another wiki.
# The database dump is expected to be in the current directory and called "dump.sql"
# The directory containing media to import is expected to be in the current directory and called "images". 
import() {
    # import database
    echo "Loading database dump"
    sudo docker cp dump.sql $DB_CONTAINER:dump.sql
    sudo docker exec -ti $DB_CONTAINER script -q -c "mysqladmin -u root -p$MYSQL_ROOT_PASSWORD create $MYSQL_DATABASE"
    sudo docker exec -ti $DB_CONTAINER script -q -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE < dump.sql"
    sudo docker exec -ti $DB_CONTAINER script -q -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD <<< create user \"$MYSQL_USER\"@\"%\" identified by \"$MYSQL_PASSWORD\"";
    sudo docker exec -ti $DB_CONTAINER script -q -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD <<< grant all privileges on mfn_fp.* to \"$MYSQL_USER\"@\"%\";"
    # Upload images into the wiki
    echo "Importing media"
    sudo docker cp images $SMW_CONTAINER:/tmp/images
    sudo docker exec -ti $SMW_CONTAINER script -q -c "cp -r /tmp/images/* $MW_DOCKERDIR/images/"
    sudo docker exec -ti $SMW_CONTAINER script -q -c "chown -R www-data:www-data $MW_DOCKERDIR/images/"
}

configure
import
