#!/bin/bash
###################################################################################
#Author: carlos.smaniotto - Carlos Eduardo Smanioto
#Email: csmanioto@gmail.com
#Date  : 2012-06-02								  #
#INFO: Performing a backup (into s3, local, ssh) using crypt and PCI-DSS rules...
####################################################################################
SCRIPT_VERSION="2.1"

clear
DATE_NOW=$(date +"%Y-%m-%d")
HOSTNAME=$(hostname |cut -d'.' -f1)
MYSQL_VERSION="$(mysqld --version|awk '{ print $3 }')"
KEY256="F7FAA9274A2BAD72554DE543BC2731FD"
IV="5D82ECF3D3435CB30106EF21640B19F0"
DESTINATION=$2
BASEDIR=$(dirname $0)


make_conf_file() {
	if [ ! -f ${BASEDIR}//backup_mysql.conf ]; then
		mkdir -p ${BASEDIR}/
		echo "# Setup information" > ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_DB_SOURCE_NAME='dbpd03 dbpd03_audit'" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_BACKUP_USER=\"backup_agent\"" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_BACKUP_USER_HOST=\"localhost\"" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_BACKUP_STOP_SLAVE=\"yes\"" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_BACKUP_USER_FIRST_PASSWORD=\"123mudar\"" >> ${BASEDIR}/backup_mysql.conf
		echo "# How amount days I will store backup" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_CLEAR_OLD_BACKUP=\"yes\"" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_CLEAR_BACKUP__OLD_THAN_DAYS=1" >> ${BASEDIR}/backup_mysql.conf
		echo "MSQL_BACKUP_COMPRRESS=\"yes\"" >> ${BASEDIR}/backup_mysql.conf
		echo "# If backup will be store in local disk ou remote" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_LOCAL_BACKUP=\"no\"" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_LOCAL_BACKUP_FOLDER=\"/databases/backup\"" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_CLIENT_EXTRA_OPTIONS=\"\"" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_DUMP_EXTRA_OPTIONS=\"\"" >> ${BASEDIR}/backup_mysql.conf
		echo "MYSQL_DUMP_PER_TABLE=\"yes\"" >> ${BASEDIR}/backup_mysql.conf
		echo "SSH_CLIENT=\"/usr/bin/ssh\"" >> ${BASEDIR}/backup_mysql.conf
		echo "SCP_CLIENT=\"/usr/bin/scp\"" >> ${BASEDIR}/backup_mysql.conf
		echo "AMAZON_COPY=\"/usr/bin/s3cmd\"" >> ${BASEDIR}/backup_mysql.conf
		echo "SSH_USER=\"userbkpd\"" >> ${BASEDIR}/backup_mysql.conf
		echo "SSH_HOST=\"bkpd-lav-01\"" >> ${BASEDIR}/backup_mysql.conf
		echo "SSH_FOLDER=\"/data/\"" >> ${BASEDIR}/backup_mysql.conf
		echo "SSH_MBs=45" >> ${BASEDIR}/backup_mysql.conf
		echo "EXPORT_BACKUP=\"no\"" >> ${BASEDIR}/backup_mysql.conf
		echo "MAKE_TAR_FILE_BACKUP=\"yes\"" >> ${BASEDIR}/backup_mysql.conf
		echo "MAKE_TAR_FILE_BACKUP_CRYPT=\"yes\"" >> ${BASEDIR}/backup_mysql.conf
		echo "Criado arquivo de conf ${BASEDIR}/backup_mysql.conf"
	fi
}

# Se  nao tiver paramentro entao eh backup mesmo !
# Se o arquivo de confgiraucao nao existir, cria
if [ ! -f ${BASEDIR}/backup_mysql.conf ]; then
       	 make_conf_file;
fi

source ${BASEDIR}/backup_mysql.conf

if [ -z $SSH_CLIENT ]; then
	SSH_CLIENT="/usr/bin/ssh"
fi


if [ -z $SCP_CLIENT ]; then
        SCP_CLIENT="/usr/bin/scp"
fi

if [ -z $AMAZON_COPY ]; then
        AMAZON_COPY="/usr/bin/s3cmd"
fi

if [ ! $CONFIG_VERSION == $SCRIPT_VERSION ]; then
	echo "This Config File is not compatible with script!"
	exit 1
fi

	###################
	#
	# Smart Functions
	#
	##################

	make_hash_crypt(){
		MAKE_PASSWD="$(echo `</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c 25`)"
		KEY256_TAR="$(echo `</dev/urandom tr -dc A-Z-a-z-0-9 | head -c 33`)"
		IV_TAR="$(echo `</dev/urandom tr -dc A-Z-a-z-0-9 | head -c 33`)"

	}

	make_password(){
        	echo `</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c 25`
	}

	crypt(){
		echo -e "$1\n$2\n$3" | openssl enc -nosalt -aes-256-cbc -out ${BASEDIR}/backup_mysql.pwd -K $KEY256 -iv $IV

	}

	decrypt(){
		openssl enc -d -nosalt -aes-256-cbc -in ${BASEDIR}/backup_mysql.pwd -K $KEY256 -iv $IV
	}

	descrypt_backup(){
	        SOURCE=$1
                dd if=${SOURCE} | openssl des3 -d k $KEY256_TAR  |tar -xvf -
        }

        encrypt_backup(){
                 SOURCE=$1
                 BACKUP_TAR_FILE=$2
                 DESTINATION_FILE=${BACKUP_TAR_FILE}.des3

                 tar -cvf - $SOURCE | openssl des3 -salt -k $KEY256_TAR | dd of=${DESTINATION_FILE}
                 md5sum $DESTINATION_FILE > ${DESTINATION_FILE=}.md5
        }


	mysql_user_change_passwd(){
		make_hash_crypt;

		NEW_PASSWORD="$MAKE_PASSWD"
		OLD_PASSWORD=$1;
		MY_SET="$(which mysql) -u $MYSQL_BACKUP_USER --password=$OLD_PASSWORD"

		echo "Backup Tools changed passwd account for new random passowd"
		#echo "NEW RANDOM PASSWORD $NEW_PASSWORD"

		if $MY_SET --execute="SET PASSWORD FOR '$MYSQL_BACKUP_USER'@'$MYSQL_BACKUP_USER_HOST' = PASSWORD('$NEW_PASSWORD');"; then
		   crypt $NEW_PASSWORD $KEY256_TAR $IV_TAR
		   #echo "NEW PASSWORD IN CRYPT TYPE: $CRYPT_PASSWD"
		   chmod 400 ${BASEDIR}/backup_mysql.pwd
		   chown root:root ${BASEDIR}/backup_mysql.pwd
		   echo "New password has stored in crypt file: ${BASEDIR}/backup_mysql.pwd"
		else
			echo "Error #MySQL_Execute_Set_Password: Contact DBA";
			exit 1;
		fi
	}

	password_check(){
		if [ -f ${BASEDIR}/backup_mysql.pwd ]; then
			CRYPT_DATA="openssl enc -d -nosalt -aes-256-cbc -in ${BASEDIR}/backup_mysql.pwd -K $KEY256 -iv $IV"
			MYSQL_BACKUP_USER_PASSWORD="$($CRYPT_DATA | awk '{ print $1 }' | awk 'NR >= 1 && NR <=1')"
			KEY256_TAR="$($CRYPT_DATA | awk '{ print $1 }' | awk 'NR >= 2 && NR <=2')"
			IV_TAR="$($CRYPT_DATA | awk '{ print $1 }' |  awk 'NR >= 3 && NR <=3')"
			echo "Load Crypt Password file"
			err=0;
		else
			err=1;
		fi
		return $err
	}

	mysql_user_check(){
              if password_check; then
                    $(which mysql) -u $MYSQL_BACKUP_USER --password="$MYSQL_BACKUP_USER_PASSWORD" -h $MYSQL_BACKUP_USER_HOST --execute="select now()" 2> /dev/null;
              else
                 echo "User $MYSQL_BACKUP_USER not exist in mysql! Use makeuser"
              fi
	}

	folder_check(){
                if [ $DESTINATION == "ssh_direct" ]; then
                        BACKUP_FOLDER_BASE="${SSH_FOLDER}/${HOSTNAME}/"
                        BACKUP_FOLDER_DATA="${SSH_FOLDER}/${HOSTNAME}/${DATE_NOW}/data"
                        BACKUP_FOLDER_STRUCTURE="${SSH_FOLDER}/${HOSTNAME}/${DATE_NOW}"
                        $SSH_CLIENT -o TCPKeepAlive=yes  ${SSH_USER}@${SSH_HOST} "mkdir -p ${BACKUP_FOLDER_DATA}"
                fi

                if [ $DESTINATION == "local" || MYSQL_LOCAL_BACKUP="yes"  ]; then
                        BACKUP_FOLDER_BASE="${MYSQL_LOCAL_BACKUP_FOLDER}/${HOSTNAME}"
                        BACKUP_FOLDER_DATA="${MYSQL_LOCAL_BACKUP_FOLDER}/${HOSTNAME}/${DATE_NOW}/data"
                        BACKUP_FOLDER_STRUCTURE="${MYSQL_LOCAL_BACKUP_FOLDER}/${HOSTNAME}/${DATE_NOW}"
                        mkdir -p ${BACKUP_FOLDER_DATA}
                fi

                if [ $DESTINATION == "amazon_s3" ]; then
                       echo "making..."
                       AMAZON_S3_FOLDER="${AMAZON_S3}/${HOSTNAME}"
                       s3cmd mb ${AMAZON_S3_FOLDER}
                fi

        }

        make_user(){
              echo "Enter DBA acconunt"
              read dbalogin;
              echo "Enter DBA PASS"
              read dbapass;

              QUERY="
                CREATE USER backup_agent@localhost identified by '123mudar';
                GRANT RELOAD ON *.* to  backup_agent@localhost;
                GRANT SELECT, LOCK TABLES ON *.* TO backup_agent@localhost;
                GRANT TRIGGER, EVENT, EXECUTE, SHOW VIEW ON *.* TO backup_agent@localhost;
                GRANT SUPER,REPLICATION CLIENT  ON *.* to  backup_agent@localhost;
                GRANT EVENT  ON *.* to  backup_agent@localhost;
                GRANT SHOW VIEW  ON *.* to  backup_agent@localhost;
                "
                mysql -h 127.0.0.1 -u $dbalogin --password="$dbapass" --execute="$QUERY";
 		mysql_user_change_passwd $MYSQL_BACKUP_USER_FIRST_PASSWORD;
        }

        mysql_tar_backup(){
		if [ ${MAKE_TAR_FILE_BACKUP} == "yes" ]; then
                BACKUP_TAR_FILE="${HOSTNAME}.${DATE_NOW}.tar"
	                if [ $MAKE_TAR_FILE_BACKUP_CRYPT == "no" ]; then
	                        cd $BACKUP_FOLDER_BASE
	                        tar -cvf $BACKUP_TAR_FILE ${DATE_NOW}
	                        md5sum $BACKUP_TAR_FILE > {$BAKUP_TAR_FILE}.md5
	                else
	                        encrypt_backup $BACKUP_FOLDER_BASE  $BACKUP_TAR_FILE
	                        BACKUP_TAR_FILE=${BACKUP_TAR_FILE}.des3
	                fi
		fi
        }

        mysql_export_backup(){
                  if [ $EXPORT_BACKUP == "yes"]; then

                        if [  $DESTINATION == "ssh"];  then
                                echo "Send $FILE to $SSH_HOST"
                                $SCP_CLIENT $BACKUP_TAR_FILE ${SSH_USER}@${SSH_HOST}:${BACKUP_FOLDER_DATA}
                                else if [ $DESTINATION == "amazon_s3" ]; then
                                                echo "Send $BACKUP_TAR_FILE to AMAZON: $AMAZON_S3_FOLDER"
                                                $AMAZON_COPY ${BACKUP_TAR_FILE}.* $AMAZON_S3_FOLDER
                                fi
                        fi
                        rm -f ${BACKUP_TAR_FILE}.*
                fi

        }


	###################################
	#
	# 	Start of Backup Routines
	#
	###################################

	###########################
	#
	# Make Backup per table file.
	#
	#############################
	mysql_backup_per_file(){
		if [ $MYSQL_BACKUP_STOP_SLAVE == "yes" ]; then
			$MYSQL --execute="STOP SLAVE SQL_THREAD;"
		fi
			$MYSQL --execute="FLUSH TABLES;"

		for data_base in $MYSQL_DB_SOURCE_NAME; do
			echo "Data per file of $data_base on $BACKUP_FOLDER_DATA"

			QUERY_EXTRACT_TABLES="SELECT TABLE_NAME AS tabelas FROM information_schema.TABLES WHERE TABLE_SCHEMA = '${data_base}' AND NOT (TABLE_NAME LIKE '%_tmp' OR TABLE_NAME LIKE '%backup' OR TABLE_NAME LIKE '%bkp%' OR TABLE_NAME like '%temp%');"
			for single_table in $($MYSQL --execute="${QUERY_EXTRACT_TABLES}"); do
				echo "Dumping table ${data_base}.${single_table}..."

				if [ $DESTINATION == "ssh_direct"];  then
					$MYSQL_DUMP --no-create-info --no-create-db --skip-opt --insert-ignore $data_base $single_table | gzip -c |  /usr/bin/throttle -m ${SSH_MBs} | $SSH_CLIENT -o TCPKeepAlive=yes  ${SSH_USER}@${SSH_HOST} "cd ${BACKUP_FOLDER_DATA} && cat > ${data_base}-${single_table}_dataonly.sql.gz"
				else
					$MYSQL_DUMP --no-create-info --no-create-db --skip-opt --insert-ignore $data_base $single_table | gzip -c > ${BACKUP_FOLDER_DATA}/${data_base}-${single_table}_dataonly.sql.gz
				fi

			done
		done
		if [ $MYSQL_BACKUP_STOP_SLAVE == "yes" ]; then
			$MYSQL --execute="START SLAVE SQL_THREAD;"
		fi
	}


	#####
	#
	# Backup of procs, triggers and events
	#
	###
	mysql_backup_routines(){
		for data_base in $MYSQL_DB_SOURCE_NAME; do
			echo "Routines of $data_base"
			if [ $DESTINATION == "ssh_direct"];  then
				$MYSQL_DUMP --force --triggers --no-create-info --no-create-info --no-create-db --skip-opt --no-data ${data_base} | gzip -c | /usr/bin/throttle -m ${SSH_MBs} | $SSH_CLIENT -o TCPKeepAlive=yes  ${SSH_USER}@${SSH_HOST} "cd ${BACKUP_FOLDER_STRUCTURE} && cat > ${data_base}-triggers.sql.gz"
				$MYSQL_DUMP --force --routines --no-create-info --no-create-info --no-create-db --skip-opt --no-data ${data_base} | gzip -c | /usr/bin/throttle -m ${SSH_MBs} | $SSH_CLIENT -o TCPKeepAlive=yes  ${SSH_USER}@${SSH_HOST} "cd ${BACKUP_FOLDER_STRUCTURE} && cat > ${data_base}-rountines-${DATE_NOW}.sql.gz"
				$MYSQL_DUMP --force --events --no-create-info --no-create-info --no-create-db --skip-opt --no-data ${data_base} | gzip -c | /usr/bin/throttle -m ${SSH_MBs} | $SSH_CLIENT -o TCPKeepAlive=yes  ${SSH_USER}@${SSH_HOST} "cd ${BACKUP_FOLDER_STRUCTURE} && cat > ${data_base}-events-${DATE_NOW}.sql.gz"
			else
				$MYSQL_DUMP --force --routines --no-create-info --no-create-info --no-create-db --skip-opt --no-data ${data_base} | gzip -c > ${BACKUP_FOLDER_STRUCTURE}/${data_base}-rountines.sql.gz
				$MYSQL_DUMP --force --triggers --no-create-info --no-create-info --no-create-db --skip-opt --no-data ${data_base} | gzip -c > ${BACKUP_FOLDER_STRUCTURE}/${data_base}-triggers.sql.gz
				$MYSQL_DUMP --force --events --no-create-info --no-create-info --no-create-db --skip-opt --no-data ${data_base} | gzip -c > ${BACKUP_FOLDER_STRUCTURE}/${data_base}-events.sql.gz
			fi
		done
	}

	#######
	#
	# Backup of Structure only of databases
	#
	#######

	mysql_backup_structure(){
		for data_base in $MYSQL_DB_SOURCE_NAME; do
			echo "Structure of $data_base"
			echo "USER: $MYSQL_BACKUP_USER"
			 if [ $DESTINATION == "ssh_direct"];  then
				$MYSQL_DUMP  --no-data  ${data_base} | gzip -c | /usr/bin/throttle -m ${SSH_MBs} | $SSH_CLIENT -o TCPKeepAlive=yes  ${SSH_USER}@${SSH_HOST} "cd ${BACKUP_FOLDER_STRUCTURE} && cat > ${data_base}-${DATE_NOW}.sql.gz"
			 else
				$MYSQL_DUMP  --no-data  ${data_base} | gzip -c > ${BACKUP_FOLDER_STRUCTURE}/${data_base}-${DATE_NOW}.sql.gz
			 fi

		done
	}

	######
	#
	# Backup of MySQL Database (Backup all tables: grant, procedures and others of table set in mysql database
	#
	######

	mysql_backup_system(){
		echo "Backup of mysql base"
		if [ $DESTINATION == "ssh_direct"];  then
			 $MYSQL_DUMP --no-data mysql | gzip -c | /usr/bin/throttle -m ${SSH_MBs} | $SSH_CLIENT -o TCPKeepAlive=yes  ${SSH_USER}@${SSH_HOST} "cd ${BACKUP_FOLDER_STRUCTURE} && cat > mysql_base.sql.gz"
			 $MYSQL_DUMP --no-create-info --no-create-db --skip-opt --insert-ignore mysql | gzip -c | /usr/bin/throttle -m ${SSH_MBs} | $SSH_CLIENT -o TCPKeepAlive=yes  ${SSH_USER}@${SSH_HOST} "cd ${BACKUP_FOLDER_DATA} && cat > mysql_base.sql.gz"
			scp  /etc/my.cnf  ${SSH_USER}@${SSH_HOST}:${BACKUP_FOLDER_STRUCTURE}/my.cnf-${MYSQL_VERSION}
		else
			  $MYSQL_DUMP --no-data mysql | gzip -c > ${BACKUP_FOLDER_STRUCTURE}/mysql_base.sql.gz
			  $MYSQL_DUMP --no-create-info --no-create-db --skip-opt --insert-ignore  mysql | gzip -c > ${BACKUP_FOLDER_DATA}/mysql_base.sql.gz
			  cp /etc/my.cnf ${BACKUP_FOLDER_STRUCTURE}/my.cnf-${MYSQL_VERSION}
		fi

	}

	##############
	#
	# Export Backup File in TAR format to SSH or Amazon S3
	#
	##############

	mysql_tar_backup(){
		BACKUP_TAR_FILE="${HOSTNAME}.${DATE_NOW}.tar"
		if [ $CRYPT_TAR == "no" ]; then
			cd $BACKUP_FOLDER_BASE
			tar -cvf $BACKUP_TAR_FILE ${DATE_NOW}
			md5sum $BACKUP_TAR_FILE > {$BAKUP_TAR_FILE}.md5
		else
			encrypt_backup $BACKUP_FOLDER_BASE  $BACKUP_TAR_FILE
			BACKUP_TAR_FILE=${BACKUP_TAR_FILE}.des3
		fi
	}

	mysql_export_backup(){
	          if [ $EXPORT_BACKUP == "yes"]; then

			if [  $DESTINATION == "ssh"];  then
				echo "Send $FILE to $SSH_HOST"
				$SCP_CLIENT $BACKUP_TAR_FILE ${SSH_USER}@${SSH_HOST}:${BACKUP_FOLDER_DATA}
				else if [ $DESTINATION == "amazon_s3" ]; then
						echo "Send $BACKUP_TAR_FILE to AMAZON: $AMAZON_S3_FOLDER"
						$AMAZON_COPY ${BACKUP_TAR_FILE}.* $AMAZON_S3_FOLDER
				fi
			fi
			rm -f ${BACKUP_TAR_FILE}.*
		fi

	}

	###########################
	#
	# Remove older backup file
	#
	##########################

	mysql_clean_old_backup(){
		if [ "$MYSQL_CLEAR_OLD_BACKUP" == "yes" ]; then
			if [ "$MYSQL_CLEAR_OLD_BACKUP_WITHOUT_WIPE" == "yes" ]; then
				if [ $DESTINATION == "ssh_direct"] || [  $DESTINATION == "ssh"];  then
				 	$SSH_CLIENT -o TCPKeepAlive=yes ${SSH_USER}@${SSH_HOST} "cd ${BACKUP_FOLDER_BASE}/ && find ./ -iname \"*.sql.gz\" -mtime +${MYSQL_CLEAR_BACKUP_OLD_THAN_DAYS} -exec rm -f {} \; "
				fi

				 if [ $DESTINATION == "local" || MYSQL_LOCAL_BACKUP="yes"  ]; then
					cd ${BACKUP_FOLDER_BASE}/ && find ./ -iname \"*.sql.gz\" -mtime +${MYSQL_CLEAR_BACKUP_OLD_THAN_DAYS} -exec rm -f {} \;
				 fi

			else
				 if [ $DESTINATION == "ssh_direct"] || [  $DESTINATION == "ssh"];  then
					$SSH_CLIENT -o TCPKeepAlive=yes ${SSH_USER}@${SSH_HOST} "cd ${BACKUP_FOLDER_BASE}/ && find ./ -iname \"*.sql.gz\" -mtime +${MYSQL_CLEAR_BACKUP_OLD_THAN_DAYS} -exec wipe {} \; "
				fi

				 if [ $DESTINATION == "local" || MYSQL_LOCAL_BACKUP="yes"  ]; then
					cd ${BACKUP_FOLDER_BASE}/ && find ./ -iname \"*.sql.gz\" -mtime +${MYSQL_CLEAR_BACKUP_OLD_THAN_DAYS} -exec wipe {} \;
				 fi
			fi
		fi
	}

mysql_backup(){
                password_check;
                MYSQL="$(which mysql) --batch --skip-column-names -u $MYSQL_BACKUP_USER --password="$MYSQL_BACKUP_USER_PASSWORD" -h $MYSQL_BACKUP_USER_HOST $MYSQL_CLIENT_EXTRA_OPTIONS"
                MYSQL_DUMP="$(which mysqldump) -u $MYSQL_BACKUP_USER --password="$MYSQL_BACKUP_USER_PASSWORD" -h $MYSQL_BACKUP_USER_HOST $MYSQL_DUMP_EXTRA_OPTIONS"
                folder_check;
                mysql_clean_old_backup;
                mysql_backup_structure;
                mysql_backup_routines;
                mysql_backup_per_file;
                mysql_backup_system;
                mysql_export_backup;
                mysql_clean_old_backup;
                # Only Security:
                $MYSQL --execute="START SLAVE SQL_THREAD;"
}

mysql_clear_backup(){
                 folder_check;
                 mysql_clean_old_backup;
}
#####################################################################################################
#
#
#  		MAIN MENU
#
######################################################################################################

	#select OP in checkbin makeuser makepass backup; do
case $1 in
	    "user")
		  case $2 in
	    		"makeuser")
				echo "Making a new user for backup agent"
				make_user;
			 ;;

			 "checkuser")
				echo "Verify if user has exist in database"
	   			mysql_user_check;
			 ;;

			*)
			   echo "Use with paramenter: \"makeruser\" or \"checkuser\""
			;;
			esac;

	   ;;
	    "backup")
		    case $2 in
			 "amazon_s3")
				mysql_backup "amazon_s3"
			  ;;
			  " local")
				mysql_backup "local"
			  ;;
			  "ssh")
				mysql_backup "ssh"

			  ;;
			  "ssh_direct")
				mysql_backup "ssh_direct"

			  ;;

			*)
				echo "Enter with destination: amazon_s3. local, ssh, ssh_direct"
			;;

			esac;
	    ;;
	   "clear_backup")
		case $2 in
                         "amazon_s3")
                                mysql_clear_backup "amazon_s3"
                          ;;
                          " local")
                                mysql_clear_backup "local"
                          ;;
                          "ssh")
                                mysql_clear_backup "ssh"
                          ;;
                          "ssh_direct")
                                mysql_clear_backup "ssh_direct"
                          ;;

                        *)
                                echo "Enter with destination: amazon_s3. local, ssh, ssh_direct"
                        ;;

                        esac;
	   ;;
	   "descrypt_backup")
			decrypt_backup;
	    ;;
	    *)
		    echo "Enter with a option: \"user\" \"backup\" \"clear_backup\" \"descrypt_backup\"";
	    ;;
esac
