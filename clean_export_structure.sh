#!/bin/bash

# Carlos Smaniotto
# carlos.smaniotto@datapower.com.br
# https://github.com/csmanioto/

# This script will be make 3 files: yyyy-mm-dd.sql
#   |-> recreate_instance_structure_yyyy-mm-dd.sql; database_struct.sql and routine.sql
#
# recreate_instance_structure_yyyy-mm-dd.sql -> Contains "DDL" command to recreate database with your CHARSET.
#   * database_struct_yyyy-mm-dd.sql -> Contains the DDL command to create tables  completely clean of mysqldump code like SET @.
#   * routine_yyyy-mm-dd.sql -> Contains the DDL to create  triggers and procedures completely clean of mysqldump code.
#   * The first file, contains the mysql SOURCE command to invoke the others scripts.
#   * So has possibility automatic creating of all structure into destination using a single sql file to do it.


# Your source environment setings
SOURCE_MYSQL_USER="root"
SOURCE_MYSQL_PASSWORD="PASSWORD"
SOURCE_MYSQL_ENDPOINT="rds-db.remote.com"
SOURCE_MYSQL_DATABASES="dbv1 dbv2 leads clientes tmp"
FILE_DESTINANTIO_PATH="/export"

# Your destinatio environment setings
DESTINATION_MYSQL_CHARSET="utf8"
DESTINATION_MYSQL_COLLATE="utf8_general_ci"

##########################################
# imutable variables
# Don´t change code below..
DATE=`date +%Y-%m-%d`
RECREATE="${FILE_DESTINANTIO_PATH}/recreate_instance_structure_${DATE}.sql"
FILE="${FILE_DESTINANTIO_PATH}/database_struct_${DATE}.sql"
FILE_ROUTINES="${FILE_DESTINANTIO_PATH}/routine_${DATE}.sql"

echo "-- Create at $${DATE}" > $RECREATE
for db in ${SOURCE_MYSQL_DATABASES};
 do
  echo $db
  echo "DROP DATABASE IF EXISTS ${db};" >> ${RECREATE}
  echo "CREATE DATABASE ${db}  DEFAULT CHARACTER SET ${DESTINATION_MYSQL_CHARSET} DEFAULT COLLATE ${DESTINATION_MYSQL_COLLATE};" >> ${RECREATE}
done
echo "source ${FILE};" >> ${RECREATE}
echo "source ${FILE_ROUTINES}" >> ${RECREATE}

###########
# Regexp Rules and Filters...
# AUTO_INCREMENT=xxxx
# perl -pe 's/AUTO_INCREMENT\s*?[=]\s*[0-9]*//g'
#
# DEFAULT CHARSET=xxxx
# perl -pe 's/DEFAULT\s*?CHARSET\s*?[=]\s*[A-Za-z0-9]*//'
#
# COLLATE=xxx_xxxxx_xx
# perl -pe 's/COLLATE\s*=?\s*[A-Za-z0-9_]*//'
#
# CHARACTER SET xxxxx (latin1 or any other)
# perl -pe 's/CHARACTER SET\s*[A-Za-z0-9]*//'
# MyISAM
# perl -pe 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/'
#
# /*!40101 SET character_set_client = @saved_cs_client */;
# perl -pe 's/^\/\*![0-9]*\s?SET.*\;$//'
###########

echo "Exporting tables... "
LOGIN="-u ${SOURCE_MYSQL_USER} -p${SOURCE_MYSQL_PASSWORD}"
HOST="-h ${SOURCE_MYSQL_ENDPOINT}"

OPTIONS_TABLE="--skip-triggers --single-transaction --skip-set-charset --no-data --no-set-names --disable-keys --no-create-db "
OPTIONS_ROUTINE=" --routines --no-create-info --no-data --no-create-db --skip-opt  "
MYSQLDUMP_PARAMETERS_TABLES="${LOGIN} ${HOST} ${OPTIONS_TABLE} --databases ${SOURCE_MYSQL_DATABASES}"
MYSQLDUMP_PARAMETERS_ROUTINES="${LOGIN} ${HOST} ${OPTIONS_ROUTINE} --databases ${SOURCE_MYSQL_DATABASES}"

# Magic code Export tables and routines in sql file so clean :) Without SET @ or /* and without charset deffinition
echo " SET foreign_key_checks=0;" > ${FILE}
mysqldump ${MYSQLDUMP_PARAMETERS_TABLES} | perl -pe 's/AUTO_INCREMENT\s*?[=]\s*[0-9]*//g' | perl -pe 's/DEFAULT\s*?CHARSET\s*?[=]\s*[A-Za-z0-9]*//' | perl -pe 's/COLLATE\s*=?\s*[A-Za-z0-9_]*//' | perl -pe 's/CHARACTER SET\s*[A-Za-z0-9]*//' | perl -pe 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/' | perl -pe 's/^\/\*![0-9]*\s?SET.*\;$//' >> ${FILE}

echo "Exporting Procedures and Triggers... "
echo " SET foreign_key_checks=0;" > ${FILE_ROUTINES}
mysqldump ${MYSQLDUMP_PARAMETERS_ROUTINES} | perl -pe 's/AUTO_INCREMENT\s*?[=]\s*[0-9]*//g' | perl -pe 's/DEFAULT\s*?CHARSET\s*?[=]\s*[A-Za-z0-9]*//' | perl -pe 's/COLLATE\s*=?\s*[A-Za-z0-9_]*//' | perl -pe 's/CHARACTER SET\s*[A-Za-z0-9]*//' | perl -pe 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/' | perl -pe 's/^\/\*![0-9]*\s?SET.*\;$//' >> ${FILE_ROUTINES}
