# Add commands using main variables
# ${CONVERTED_FILE}, ${ORIGINAL_FILE}, etc..

sed -i -e 's/MyISAM/InnoDB/gi' ${CONVERTED_FILE}
