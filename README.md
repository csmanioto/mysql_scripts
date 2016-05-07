# mysql_scripts : DBA tools to MYSQL Database

## How I am ?
Carlos Smaniotto - More than 15 years of career in Database and infrastructure IT.
* https://www.linkedin.com/in/smanioto
* http://www.csmaniotto.com/

## Motivation of this repository motivation:

In my career I did many script to work with MySQL and I lost it and unfortunately i needed recoding this scripts. I did lost time doing it :(

Now I decided save this script in github to make versions. But I love helping persons and why not share all scripts in public repository ?

# Help file
* rds_parameter_group.txt

  Most common variables used in  Amazon Web Sercice -  RDS.
    - [x] Variables used when change MyISAM to InnoDB
    - [x] Variables used to character set.

    
# Stable scripts:
* clean_export_structure.sh
      - [x] Converting database engine from myisam to innodb. Recreating  triggers and routines in a clean sql file without charset and especial  mysqldump command.
      - [x] Use it to do two things: converting engine and converting charset types (latin1 to utf8 or outhers).
