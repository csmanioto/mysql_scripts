#!/bin/bash

# Carlos Smaniotto
# carlos.smaniotto@datapower.com.br
# https://github.com/csmanioto/

# This script will export and convert charset of database´s data.
# Important: Export and Import data only! You need prepar the new mysql to do it.
# I recommend the use of clean_export_structure.sh to  help you to do this task.
# https://raw.githubusercontent.com/csmanioto/mysql_scripts/master/clean_export_structure.sh
# Remember of set the variables in your my.cnf :
# - character_set_server
# - character_set_client
# - character_set_results
# - collation_connection
# With your $DESTINATION_MYSQL_CHARSET and $DESTINATION_MYSQL_COLLATE


##########################################
# Your source environment setings
# Change with your environment information.
SOURCE_MYSQL_USER="root"
SOURCE_MYSQL_PASSWORD="PASSWORD"
SOURCE_MYSQL_ENDPOINT="rds-db.remote.com"
SOURCE_MYSQL_CHARSET="latin1"

# Your destinantion environment setings
DESTINATION_MYSQL_USER="root"
DESTINATION_MYSQL_PASSWORD="password"
DESTINATION_MYSQL_ENDPOINT="rdsdb.remote.com"
DESTINATION_MYSQL_CHARSET="utf8"
DESTINATION_MYSQL_COLLATE="utf8_general_ci"

# Export settings...
# If SOURCE_MYSQL_DATABASES is empty, script will export from SOURCE_ENDPOINT all databases (except systems databases)
MYSQL_DATABASES_LIST="dbv1 dbv2 leads clientes tmp"
FILE_DESTINANTIO_PATH="/export"

#################################################

#########################################
# imutable variables                    #
# Don´t change code below..             #
#########################################
if [-f user_variables.cfg]; then
  source user_variables.cfg
fi

DATE=$(date +%Y-%m-%d)
ERROR_LOG="${FILE_DESTINANTIO_PATH}/error_${DATE}.log"
STATUS_LOG="${FILE_DESTINANTIO_PATH}/status_${DATE}.log"

#Variables of SOURCE DATABASE - MySQLDUMP
SRC_LOGIN="-u ${SOURCE_MYSQL_USER} -p${SOURCE_MYSQL_PASSWORD}"
SRC_HOST="-h ${SOURCE_MYSQL_ENDPOINT}"
SOURCE_MYSQL_CHARSET=$(echo ${SOURCE_MYSQL_CHARSET} | tr '[:upper:]' '[:lower:]' )
SOURCE_ICONV_CHARSET=$(echo ${SOURCE_MYSQL_CHARSET} | tr '[:lower:]' '[:upper:]' )
MYSQLDUMP_OPTIONS="--default-character-set=${SOURCE_MYSQL_CHARSET} --disable-keys --skip-triggers -no-create-info --single-transaction --no-set-names --disable-keys "
MYSQLDUMP_PARAMETERS="${SRC_LOGIN} ${SRC_HOST} ${MYSQLDUMP_OPTIONS} "

#Variables of destinantion - MySQL (Import)
DST_LOGIN="-u ${DESTINATION_MYSQL_USER} -p${DESTINATION_MYSQL_PASSWORD}"
DST_HOST="-h ${DESTINATION_MYSQL_ENDPOINT}"
DESTINATION_MYSQL_CHARSET=$(echo ${DESTINATION_MYSQL_CHARSET} | tr '[:upper:]' '[:lower:]' )
DESTINATION_MYSQL_COLLATE=$(echo ${DESTINATION_MYSQL_COLLATE} | tr '[:upper:]' '[:lower:]' )
DESTINATION_ICONV_CHARSET=$(echo ${DESTINATION_MYSQL_CHARSET} | tr '[:lower:]' '[:upper:]' )

MYSQL_OPTIONS="--default-character-set=${DESTINATION_MYSQL_CHARSET}"
MYSQL_PARAMTERS="${DST_LOGIN} ${DST_HOST} ${MYSQL_OPTIONS} "


###########################################
# Start of export algorithim              #
###########################################
if [ -z $MYSQL_DATABASES_LIST ]; then
    MYSQL_DATABASES_LIST=$(mysql ${SRC_LOGIN} -h ${SRC_HOST} -r -s -N -e "show databases" | grep -Ev "^(Database|mysql|performance_schema|information_schema|innodb|sys)$")
fi


echo "--------------------------------------" > ${STATUS_LOG}
echo "--------------------------------------" > ${ERROR_LOG}


NEW_DATE=$(date "+%Y-%m-%d %H:%M:%S")
echo "${NEW_DATE}:  +++ START PROCESS "  | tee -a ${STATUS_LOG}

cd ${FILE_DESTINANTIO_PATH}
for db in ${MYSQL_DATABASES_LIST};
do
    NEW_DATE=$(date "+%Y-%m-%d %H:%M:%S")
    echo "${NEW_DATE}: Exporting database ${db}..."  | tee -a ${STATUS_LOG}
    ORIGINAL_FILE="${FILE_DESTINANTIO_PATH}/${db}_dataonly_${SOURCE_MYSQL_CHARSET}_${DATE}.sql"
    CONVERTED_FILE"${FILE_DESTINANTIO_PATH}/${db}_dataonly_${DESTINATION_MYSQL_CHARSET}_${DATE}.sql"

    if mysqldump ${MYSQLDUMP_PARAMETERS} ${db} -r  ${ORIGINAL_FILE}; then
      if iconv -f ${SOURCE_ICONV_CHARSET} -f ${DESTINATION_ICONV_CHARSET} < ${ORIGINAL_FILE} > ${CONVERTED_FILE};
        sed -e "s/SET NAMES ${SOURCE_MYSQL_CHARSET}/SET NAMES ${DESTINATION_MYSQL_CHARSET}/g" -i ${CONVERTED_FILE}
        sed -e "s/CHARSET=latin1/CHARSET=${DESTINATION_MYSQL_CHARSET} COLLATE=${DESTINATION_MYSQL_COLLATE}/g" -i ${CONVERTED_FILE}
        rm -f ${ORIGINAL_FILE}
      else
        echo "${NEW_DATE}: Error on iconv of ${db} " | tee -a ${ERROR_LOG}
        echo "${NEW_DATE}:  +++ END PROCESS WITH ERROR.. SEE ${ERROR_LOG} "  | tee -a ${STATUS_LOG}
        exit 1
      fi
    else
      echo "${NEW_DATE}: Error on mysqldump of ${db} " | tee -a ${ERROR_LOG}
      echo "${NEW_DATE}:  +++ END PROCESS WITH ERROR.. SEE ${ERROR_LOG} "  | tee -a ${STATUS_LOG}
      exit 1
    fi
done


NEW_DATE=$(date "+%Y-%m-%d %H:%M:%S")
echo "${NEW_DATE}: IMPORTING PROCESSS.."  | tee -a ${STATUS_LOG}
echo "---------------------------------"  | tee -a ${STATUS_LOG}

echo "${NEW_DATE}: IMPORTING database ${db}..."  | tee -a ${STATUS_LOG}
for db in ${MYSQL_DATABASES_LIST};
do
  NEW_DATE=$(date "+%Y-%m-%d %H:%M:%S")
  echo "${NEW_DATE}: IMPORTING database ${db}..."  | tee -a ${STATUS_LOG}
  CONVERTED_FILE"${FILE_DESTINANTIO_PATH}/${db}_dataonly_${DESTINATION_MYSQL_CHARSET}_${DATE}.sql"
  if mysql ${MYSQL_PARAMTERS} $db -e"source ${CONVERTED_FILE}"; then
    NEW_DATE=$(date "+%Y-%m-%d %H:%M:%S")
    echo "${NEW_DATE}: ${db} IMPORTED WITH SUCCESSFUL"  | tee -a ${STATUS_LOG}
  else
    NEW_DATE=$(date "+%Y-%m-%d %H:%M:%S")
    echo "${NEW_DATE}: Error on import ${db} " | tee -a ${ERROR_LOG}
    echo "${NEW_DATE}:  +++ END PROCESS WITH ERROR.. SEE ${ERROR_LOG} "  | tee -a ${STATUS_LOG}
    exit 1
  fi
done

NEW_DATE=$(date "+%Y-%m-%d %H:%M:%S")
echo "${NEW_DATE}:  +++ END PROCESS "  | tee -a ${STATUS_LOG}
