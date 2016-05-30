# mysql_scripts : DBA tools to MYSQL Database

## How I am ?
Carlos Smaniotto - More than 15 years of career in Database and infrastructure IT.
* https://www.linkedin.com/in/smanioto
* http://www.csmaniotto.com/
* http://make-install.blogspot.com.br/

## Motivation of this repository motivation:

In my career I did many script to work with MySQL and I lost it and unfortunately i needed recoding this scripts. I did lost time doing it :(

Now I decided save this script in github to make versions. But I love helping persons and why not share all scripts in public repository ?

# Help file
* rds_parameter_group.txt

  Most common variables used in  Amazon Web Sercice -  RDS.
    - [x] Variables used when change MyISAM to InnoDB
    - [x] Variables used to character set.


# Stable scripts:
* convert_db Folder:
  * clean_export_structure.sh
    - [x] Converting database engine from myisam to innodb. Recreating  triggers and routines in a clean sql file without charset and especial mysqldump command;
    - [x] Convert all innodb simple table in INNODB ROW_FORMAT=DYNAMIC (change my.cnf to enable barracuda)
    - [x] Use it to do two things: converting engine and converting charset types (latin1 to utf8 or outhers).

    * convert_charset_database.sh
    - [x] Export data and convert character set from x to y and import into new server
    - [x] Log of all steps

* super_backup Folder:

  Performing a full backup into S3 or local folder or remote using ssh using cryptography and PCI-DSS rules.

    - [x] Backup in: AWS S3, Local Folder and SSH Copy
    - [x] PCI-DSS rules
    - [x] Cryptography of datas (OpenSSL)
    - [x] Restore using the same script
    - [x] Backup in separate files: Tables and datas
