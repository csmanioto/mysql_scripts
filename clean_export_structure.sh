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
# POS INSTALATION
# $ cd $FILE_DESTINANTIO_PATH
# $ mysql -u new_mysql_login -h new_mysql_endpoint < recreate_instance_structure_yyyy-mm-dd.sql

##############################################################
# Your source environment setings in file user_variables.cfg #
##############################################################

#########################################
# imutable variables                    #
# Don´t change code below..             #
#########################################
if [ -f user_variables.cfg ]; then
  source ./user_variables.cfg
else
  echo "user_variables.cfg not found..."
  exit 1
fi

LOGIN="-u ${SOURCE_MYSQL_USER} -p${SOURCE_MYSQL_PASSWORD}"
HOST="-h ${SOURCE_MYSQL_ENDPOINT}"
OPTIONS_MYSQLDUMP_COMMON=" --single-transaction --skip-set-charset --no-data --no-set-names --disable-keys --no-create-db "
OPTIONS_MYSQLDUMP_TABLE="${OPTIONS_MYSQLDUMP_COMMON} --skip-triggers "
OPTIONS_MYSQLDUMP_ROUTINE="${OPTIONS_MYSQLDUMP_COMMON} --routines --no-create-info --skip-opt"
#OPTIONS_TABLE="--skip-triggers --single-transaction --skip-set-charset --no-data --no-set-names --disable-keys --no-create-db "
#OPTIONS_ROUTINE="--routines --single-transaction --skip-set-charset  --no-data --no-set-names --disable-keys --no-create-info --no-create-db --skip-opt "


###########################################
# Start of export algorithim              #
###########################################
if [ -z $MYSQL_DATABASES_LIST ]; then
    MYSQL_DATABASES_LIST=$(mysql ${LOGIN} ${HOST} -r -s -N -e "show databases" | grep -Ev "^(Database|mysql|performance_schema|information_schema|innodb|sys)$")
fi

DATE=$(date +%Y-%m-%d)
FILE_TABLES="${FILE_DESTINANTIO_PATH}/tables_structure_${DATE}.sql"
FILE_DBS="${FILE_DESTINANTIO_PATH}/database_struct_${DATE}.sql"
FILE_ROUTINES="${FILE_DESTINANTIO_PATH}/routine_${DATE}.sql"
ALL_IN_ONE="${FILE_DESTINANTIO_PATH}/allinone_${DATE}.sql"

echo "-- Create at ${DATE}" > ${FILE_TABLES}
for db in ${MYSQL_DATABASES_LIST};
 do
  echo $db
  echo "DROP DATABASE IF EXISTS ${db};" >> ${FILE_DBS}
  echo "CREATE DATABASE ${db}  DEFAULT CHARACTER SET ${DESTINATION_MYSQL_CHARSET} DEFAULT COLLATE ${DESTINATION_MYSQL_COLLATE};" >> ${FILE_DBS}
done

###########
# Test online on https://regex101.com/
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
#
# Remove ROW_FORMAT=COMPACT AND COMPRESS, ETC
# perl -pe 's/[Ii][Nn][Nn][Oo][Dd][Bb]\s*?ROW_FORMAT=[aA-zZ]*;$/INNODB ROW_FORMAT=DYNAMIC/'
#
# Change the single  "InnoDB;"" to InnoDB with Row DYNAMIC compress - ROW_FORMAT=DYNAMIC;
# perl -pe 's/[Ii][Nn][Nn][Oo][Dd][Bb]\s*?;$/INNODB ROW_FORMAT=DYNAMIC;/'
#
# Remove /*!50013 DEFINER=`admin`@`%` SQL SECURITY DEFINER */
# Remobe SQL SECURITY part...
# perl -pe 's/SQL\s*?SECURITY\s*?DEFINER//'
#
# Remove DEFINER between /* and */
# perl -pe 's/DEFINER=\`admin\`@\`%\`//'
#
# REMOVE  'latin1_swedish_ci' or  'utf8_general_ci'
# perl -pe "s/\'(latin1|utf8).*?\'//"
#
# Remove collate utf8_general_ci
# perl -pe 's/collate\s(latin1|utf8)_[a-z]*_[a-z]*//'
#
# REMOVE CHARSET latin1
# perl -pe 's/CHARSET\s(latin1|utf8)?\s//'
###########

echo "Exporting tables... "
MYSQLDUMP_PARAMETERS_TABLES="${LOGIN} ${HOST} ${OPTIONS_MYSQLDUMP_TABLE} --databases ${MYSQL_DATABASES_LIST}"
MYSQLDUMP_PARAMETERS_ROUTINES="${LOGIN} ${HOST} ${OPTIONS_MYSQLDUMP_ROUTINE} --databases ${MYSQL_DATABASES_LIST}"

# Magic code Export tables and routines in sql file so clean :) Without SET @ or /* and without charset deffinition
echo "-- Create at ${DATE}" > ${FILE_TABLES}
echo " SET foreign_key_checks=0;" >> ${FILE_TABLES}
mysqldump ${MYSQLDUMP_PARAMETERS_TABLES} | perl -pe 's/AUTO_INCREMENT\s*?[=]\s*[0-9]*//g' | perl -pe 's/DEFAULT\s*?CHARSET\s*?[=]\s*[A-Za-z0-9]*//' | perl -pe 's/COLLATE\s*=?\s*[A-Za-z0-9_]*//' | perl -pe 's/CHARACTER SET\s*[A-Za-z0-9]*//' | perl -pe 's/^\/\*![0-9]*\s?SET.*\;$//' | perl -pe 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/' | perl -pe 's/[Ii][Nn][Nn][Oo][Dd][Bb]\s*?ROW_FORMAT=[aA-zZ]*;$/INNODB ROW_FORMAT=DYNAMIC;/' |  perl -pe 's/[Ii][Nn][Nn][Oo][Dd][Bb]\s*?;$/INNODB ROW_FORMAT=DYNAMIC;/'  |  perl -pe 's/DEFINER=\`admin\`@\`%\`//' | perl -pe 's/SQL\s*?SECURITY\s*?DEFINER//'  >> ${FILE_TABLES}

echo "Exporting Procedures and Triggers... "
echo "-- Create at ${DATE}" >> ${FILE_ROUTINES}
echo " SET foreign_key_checks=0;" > ${FILE_ROUTINES}
#mysqldump ${MYSQLDUMP_PARAMETERS_ROUTINES} | perl -pe 's/AUTO_INCREMENT\s*?[=]\s*[0-9]*//g' | perl -pe 's/DEFAULT\s*?CHARSET\s*?[=]\s*[A-Za-z0-9]*//' | perl -pe 's/COLLATE\s*=?\s*[A-Za-z0-9_]*//' | perl -pe 's/CHARACTER SET\s*[A-Za-z0-9]*//' | perl -pe 's/^\/\*![0-9]*\s?SET.*\;$//' | perl -pe 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/' | perl -pe 's/[Ii][Nn][Nn][Oo][Dd][Bb]\s*?ROW_FORMAT=[aA-zZ]*;$/INNODB ROW_FORMAT=DYNAMIC;/' | perl -pe 's/[Ii][Nn][Nn][Oo][Dd][Bb]\s*?;$/INNODB ROW_FORMAT=DYNAMIC;/' |  perl -pe 's/DEFINER=\`admin\`@\`%\`//' | perl -pe 's/SQL\s*?SECURITY\s*?DEFINER//' |  perl -pe "s/\'latin1.*?\'//" | perl -pe 's/CHARSET\s(latin1|utf8)?\s//' | perl -pe 's/collate\s(latin1|utf8)_[a-z]*_[a-z]*//' | perl -pe "s/\'(latin1|utf8).*?\'//" >> ${FILE_ROUTINES}
mysqldump ${MYSQLDUMP_PARAMETERS_ROUTINES} | perl -pe 's/AUTO_INCREMENT\s*?[=]\s*[0-9]*//g' | perl -pe 's/DEFAULT\s*?CHARSET\s*?[=]\s*[A-Za-z0-9]*//' | perl -pe 's/COLLATE\s*=?\s*[A-Za-z0-9_]*//' | perl -pe 's/CHARACTER SET\s*[A-Za-z0-9]*//' | perl -pe 's/^\/\*![0-9]*\s?SET.*\;$//' | perl -pe 's/[Mm][Yy][Ii][Ss][Aa][Mm]/InnoDB/' | perl -pe 's/[Ii][Nn][Nn][Oo][Dd][Bb]\s*?ROW_FORMAT=[aA-zZ]*;$/INNODB ROW_FORMAT=DYNAMIC;/' | perl -pe 's/[Ii][Nn][Nn][Oo][Dd][Bb]\s*?;$/INNODB ROW_FORMAT=DYNAMIC;/' |  perl -pe 's/DEFINER=\`admin\`@\`%\`//' | perl -pe 's/SQL\s*?SECURITY\s*?DEFINER//' |  perl -pe 's/CHARSET\s(latin1|utf8)?\s//' | perl -pe 's/collate\s(latin1|utf8)_[a-z]*_[a-z]*//' | perl -pe "s/\'(latin1|utf8).*?\'//" >> ${FILE_ROUTINES}

## Remote Server
# Execute Script Session
DST_LOGIN="-u ${DESTINATION_MYSQL_USER} -p${DESTINATION_MYSQL_PASSWORD}"
DST_HOST="-h ${DESTINATION_MYSQL_ENDPOINT}"
MYSQL_OPTIONS="--default-character-set=${DESTINATION_MYSQL_CHARSET}"
MYSQL_PARAMTERS="${DST_LOGIN} ${DST_HOST} ${MYSQL_OPTIONS} "

# apply custom Filters
if [ -f ./clean_export_custom_filter.sh ]; then
  source ./clean_export_custom_filter.sh
fi

echo "-- Create at ${DATE}" > ${ALL_IN_ONE}
echo "source ${FILE_DBS};" >> ${ALL_IN_ONE}
echo "source ${FILE_TABLES};" >> ${ALL_IN_ONE}
echo "source ${FILE_ROUTINES};" >> ${ALL_IN_ONE}

#read -t 10 -r -p "Execute the script on remote server? [y/N] (10 seconds timeout ) " response
#case $response in
#    [yY][eE][sS]|[yY])
#        mysql ${MYSQL_PARAMTERS} < ${RECREATE}
#        mysql ${MYSQL_PARAMTERS} < ${FILE_ROUTINES}
#        ;;
#    *)
        echo "Finish... You can execute in anytime:"
        echo "File per file"
        echo "mysql options < ${FILE_DBS}"
        echo "mysql options < ${FILE_TABLES}"
        echo "mysql options < ${FILE_ROUTINES}"
        echo " OR  "
        echo "myqsl options < ${ALL_IN_ONE}"
#        ;;
#esac
