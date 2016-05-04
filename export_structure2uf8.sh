#!/bin/bash

LOGIN="-u root  -pPassword"
ENDPOINT="-h rds-db.remote.com""
OPTIONS="--skip-triggers --single-transaction --skip-set-charset --no-data --no-set-names --disable-keys –default-character-set=utf8"
DATABASES="--databases dbv1 dbv2 leads clientes tmp" 
FILE="database_innodb.sql"


echo " SET foreign_key_checks=0;" > ${FILE}
mysqldump ${LOGIN} ${ENDPOINT} ${OPTIONS} ${DATABASES} | sed -e 's/DEFAULT CHARACTER SET latin1/DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci/g' | sed -e 's/DEFAULT CHARSET=latin1/DEFAULT CHARSET=utf8/g' |  sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | sed -e 's/AUTO_INCREMENT.*\d*//g' |sed -e 's/[Mm][Yy][Ii][Ss][Aa][Mm]/INNODB/g' | grep -i -v -E "SET character_set_client|SET @saved_cs_client|SET @saved_col_connection|SET @saved_cs_results|SET character_set_client|SET character_set_results|SET collation_connection|SET @saved_sql_mode|SET sql_mode|set FOREIGN_KEY_CHECKS|set SQL_NOTES|set UNIQUE_CHECKS|set TIME_ZONE|set @OLD_CHARACTER_SET_RESULTS|set @OLD_CHARACTER_SET_CLIENT|SET @OLD_COLLATION_CONNECTION|SET NAMES|SET @OLD_TIME_ZONE|SET @OLD_UNIQUE_CHECKS|SET @OLD_FOREIGN_KEY_CHECKS|SET @OLD_SQL_MODE|SET @OLD_SQL_NOTES"  >> ${FILE}
