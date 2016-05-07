#!/bin/bash

# Carlos Smaniotto
# carlos.smaniotto@datapower.com.br
# https://github.com/csmanioto/

#This script will be make 3 files: yyyy-mm-dd.sql
# |-> recreate_instance_structure_yyyy-mm-dd.sql; database_struct.sql and routine.sql
#
#recreate_instance_structure_yyyy-mm-dd.sql -> Contains "DDL" command to recreate database with your CHARSET.
# * database_struct_yyyy-mm-dd.sql -> Contains the DDL command to create tables  completely clean of mysqldump code like SET @.
# * routine_yyyy-mm-dd.sql -> Contains the DDL to create  triggers and procedures completely clean of mysqldump code.
# * The first file, contains the mysql SOURCE command to invoke the others scripts.
# * So has possibility automatic creating of all structure into destination using a single sql file to do it.


# Your source environment setings
SOURCE_LOGIN="-u root  -pPassword"
SOURCE_ENDPOINT="-h rds-db.remote.com"
SOURCE_DATABASES="dbv1 dbv2 leads clientes tmp"

# Your destinatio environment setings
COLLATE="utf8"
CHARSET="utf8_general_ci"


# imutable variables
DATE=`date +%Y-%m-%d`
OPTIONS="--skip-triggers --single-transaction --skip-set-charset --no-data --no-set-names --disable-keys  "
OPTIONS_ROUTINE=" --routines --no-create-info --no-data --no-create-db --skip-opt  "
RECREATE="recreate_instance_structure_${DATE}.sql"
FILE="database_struct_${DATE}.sql"
FILE_ROUTINES="routine_${DATE}.sql"

# Magic code Export tables and routines in sql file so clean :) Without SET @ or /* and without charset deffinition
echo " SET foreign_key_checks=0;" > ${FILE}
echo " SET foreign_key_checks=0;" > ${FILE_ROUTINES}

# AUTO_INCREMENT=xxxx
#perl -pe 's/AUTO_INCREMENT\s*?[=]\s*[0-9]*//g'

#DEFAULT CHARSET=xxxx
#perl -pe 's/DEFAULT\s*?CHARSET\s*?[=]\s*[A-Za-z0-9]*//'

#COLLATE=xxx_xxxxx_xx
#perl -pe 's/COLLATE\s*=?\s*[A-Za-z0-9_]*//'

#CHARACTER SET xxxxx (latin1 or any other)
#perl -pe 's/CHARACTER SET\s*[A-Za-z0-9]*//'
 #MyISAM
#perl -pe 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/'

#/*!40101 SET character_set_client = @saved_cs_client */;
#perl -pe '/s^\/\*![0-9]*\s?SET.*\/;$//'

for db in ${DATABASES};
  echo "DROP DATABASE IF EXISTS `${db}`;" > ${RECREATE}
  echo "CREATE DATABASE `${db}`  DEFAULT CHARACTER SET ${CHARSET} DEFAULT COLLATE ${COLLATE};" >> ${RECREATE}
done
echo "source ${FILE};" >> ${RECREATE}
echo "source ${FILE_ROUTINES}" >> ${RECREATE}

mysqldump ${SOURCE_LOGIN} ${SOURCE_ENDPOINT} ${OPTIONS} --databases ${SOURCE_DATABASES} | perl -pe 's/AUTO_INCREMENT\s*?[=]\s*[0-9]*//g' | perl -pe 's/DEFAULT\s*?CHARSET\s*?[=]\s*[A-Za-z0-9]*//' | perl -pe 's/COLLATE\s*=?\s*[A-Za-z0-9_]*//' | perl -pe 's/CHARACTER SET\s*[A-Za-z0-9]*//' | perl -pe 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/' >> ${FILE}
mysqldump ${SOURCE_LOGIN} ${SOURCE_ENDPOINT} ${OPTIONS_ROUTINE} --databases ${SOURCE_DATABASES} | perl -pe 's/AUTO_INCREMENT\s*?[=]\s*[0-9]*//g' | perl -pe 's/DEFAULT\s*?CHARSET\s*?[=]\s*[A-Za-z0-9]*//' | perl -pe 's/COLLATE\s*=?\s*[A-Za-z0-9_]*//' | perl -pe 's/CHARACTER SET\s*[A-Za-z0-9]*//' | perl -pe 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/' >> ${FILE_ROUTINES}
