#!/bin/bash

LOGIN="-u root  -pPassword"
ENDPOINT="-h rds-db.remote.com"
OPTIONS="--skip-triggers --single-transaction --skip-set-charset --no-data --no-set-names --disable-keys --default-character-set=utf8 --add-drop-database "
OPTIONS_ROUTINE=" --routines --no-create-info --no-data --no-create-db --skip-opt  "
DATABASES="--databases dbv1 dbv2 leads clientes tmp" 


DATE=`date +%Y-%m-%d`
FILE="database_struct_${DATE}.sql"
FILE_ROUTINES="routine_${DATE}.sql"


echo " SET foreign_key_checks=0;" > ${FILE}
echo " SET foreign_key_checks=0;" > ${FILE}
echo " SET foreign_key_checks=0;" > ${FILE_ROUTINES}


mysqldump ${LOGIN} ${ENDPOINT} ${OPTIONS} ${DATABASES} | sed -e 's/DEFAULT\s*?CHARSET\s*?[=]\s*?[A-Za-z0-9]*\s*?COLLATE\s*?[=]\s*?[A-Za-z0-9_]*//g'  | sed -e 's/DEFAULT CHARSET=*[a-zA-Z]+[1|8]+//g' | sed -e 's/CHARACTER SET (utf8|UTF8|LATIN1|latin1)+ COLLATE [A-Za-z0-9 _]* //g' |  sed -e 's/DEFAULT CHARACTER SET latin1/DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci/g' | sed -e 's/DEFAULT CHARSET=latin1/DEFAULT CHARSET=utf8/g' |  sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | sed -e 's/AUTO_INCREMENT.*\d*//g' |sed -e 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/g' | grep -i -v -E "SET character_set_client|SET @saved_cs_client|SET @saved_col_connection|SET @saved_cs_results|SET character_set_client|SET character_set_results|SET collation_connection|SET @saved_sql_mode|SET sql_mode|set FOREIGN_KEY_CHECKS|set SQL_NOTES|set UNIQUE_CHECKS|set TIME_ZONE|set @OLD_CHARACTER_SET_RESULTS|set @OLD_CHARACTER_SET_CLIENT|SET @OLD_COLLATION_CONNECTION|SET NAMES|SET @OLD_TIME_ZONE|SET @OLD_UNIQUE_CHECKS|SET @OLD_FOREIGN_KEY_CHECKS|SET @OLD_SQL_MODE|SET @OLD_SQL_NOTES"  >> ${FILE}
mysqldump ${LOGIN} ${ENDPOINT} ${OPTIONS_ROUTINE} ${DATABASES} | sed -e 's/DEFAULT\s*?CHARSET\s*?[=]\s*?[A-Za-z0-9]*\s*?COLLATE\s*?[=]\s*?[A-Za-z0-9_]*//g'  | sed -e 's/DEFAULT CHARSET=*[a-zA-Z]+[1|8]+//g' | sed -e 's/CHARACTER SET (utf8|UTF8|LATIN1|latin1)+ COLLATE [A-Za-z0-9 _]* //g' |  sed -e 's/DEFAULT CHARACTER SET latin1/DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci/g' | sed -e 's/DEFAULT CHARSET=latin1/DEFAULT CHARSET=utf8/g' |  sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | sed -e 's/AUTO_INCREMENT\s*?[=]\s*?\d+//g' |sed -e 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/g' | grep -i -v -E "SET character_set_client|SET @saved_cs_client|SET @saved_col_connection|SET @saved_cs_results|SET character_set_client|SET character_set_results|SET collation_connection|SET @saved_sql_mode|SET sql_mode|set FOREIGN_KEY_CHECKS|set SQL_NOTES|set UNIQUE_CHECKS|set TIME_ZONE|set @OLD_CHARACTER_SET_RESULTS|set @OLD_CHARACTER_SET_CLIENT|SET @OLD_COLLATION_CONNECTION|SET NAMES|SET @OLD_TIME_ZONE|SET @OLD_UNIQUE_CHECKS|SET @OLD_FOREIGN_KEY_CHECKS|SET @OLD_SQL_MODE|SET @OLD_SQL_NOTES"  >> ${FILE_ROUTINES}