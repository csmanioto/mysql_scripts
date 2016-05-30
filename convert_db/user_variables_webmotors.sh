#CONFIG FILE
# SET THE VARIABLE TO clean_export_structure.sh and convert_charset_database.sh
# This file not is pre-requisite

SOURCE_MYSQL_USER="admin"
SOURCE_MYSQL_PASSWORD="RG7lCad1Hlps"
SOURCE_MYSQL_ENDPOINT="rds-d-1.vmotors.com.br"

# Your destinantion environment setings
DESTINATION_MYSQL_USER="rds_hkmigrate"
DESTINATION_MYSQL_PASSWORD="RG7lCad1Hlps"
DESTINATION_MYSQL_ENDPOINT="rds-hk.vmotors.com.br"

# Export settings...
# If SOURCE_MYSQL_DATABASES is empty, script will export from SOURCE_ENDPOINT all databases (except systems databases)
MYSQL_DATABASES_LIST="vmotor_BDV1 vmotor_historico vmotor_indice_preco vmotor_leads_emails_normalizado vmotor_leads_midias vmotor_log_erro vmotor_mantis vmotor_site_cliente vmotor_vigorito tmp"
FILE_DESTINANTIO_PATH="/export"

# This settings is valid only in convert_charset_database.sh script
SOURCE_MYSQL_CHARSET="latin1"
DESTINATION_MYSQL_CHARSET="utf8"
DESTINATION_MYSQL_COLLATE="utf8_general_ci"
