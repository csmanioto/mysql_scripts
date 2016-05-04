#!/bin/bash

SOURCE_USER="root"
SOURCE_PASSWORD="password"
SOURCE_ENDPOINT="mysqldb.localhost.com"
MYSQLDUMP_OPT="-u ${USER} -p¢{PASSWORD} -h ${SOURCE_ENDPOINT} --default-character-set=latin1 --disable-keys --skip-triggers -no-create-info --single-transaction "

DESTINATION_USER="root"
DESTINATION_PASSWORD="password"
DESTINATION_ENDPOINT="rdsdb.remote.com"
DESTINATION_MYSQL_OPTS="--u ${DESTINATION_USER} -p${DESTINATION_PASSWORD} --default-character-set=utf8 "

PATH_EXPORT="/mnt"
cd $PATH_EXPORT

candidates=$(mysql -h ${SOURCE_ENDPOINT} -u ${SOURCE_USER} -p${SOURCE_PASSWORD} -r -s -N -e"show databases" | grep -Ev "^(Database|mysql|performance_schema|information_schema|innodb|sys)$"

echo "Export...."
for candidate in $candidates[*]; do
    mysqldump $MYSQLDUMP_OPT $candidate -r ${candidate}_data.latin1
    iconv -f LATIN1 -t UTF-8 < ${candidate}_data.latin1 > ${candidate}_data_utf8.sql
    sed -e 's/SET NAMES latin1/SET NAMES utf8/g' -i ${candidate}_data_utf8.sql
    sed -e 's/CHARSET=latin1/CHARSET=utf8 COLLATE=utf8_general_ci/g' -i ${candidate}_data_utf8.sql
    rm -f ${candidate}_data.latin1
done


echo "IMPORT..."
for candidate in $candidates[*]; do
  mysql ${DESTINATION_MYSQL_OPTS} $candidate -e"source ${candidate}_data_utf8.sql"
done
