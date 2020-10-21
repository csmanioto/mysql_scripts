SELECT CONCAT("CREATE USER '", user, "'@'",host,"'  IDENTIFIED WITH mysql_native_password BY '", password, "'"  )  FROM mysql.user where user not in ('root');
