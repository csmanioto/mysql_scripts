# Add commands using main variables
# ${CONVERTED_FILE}, ${ORIGINAL_FILE}, etc..

sed -i -e s/"KEY \`enderecos\` (\`URL_DEV\`(255),\`URL_HOMOL\`,\`URL_PROD\`(255),\`URL_MOBILE\`,\`URL_FACEBOOK\`),"//g  ${FILE_TABLES}
