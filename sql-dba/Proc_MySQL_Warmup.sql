USE `mysql`;
delimiter //
DROP PROCEDURE IF EXISTS Proc_MySQL_Warmup;
CREATE PROCEDURE Proc_MySQL_Warmup()
COMMENT 'Warm up mysql stored procedure'
BEGIN
    DECLARE p_c INT DEFAULT 0;
    DECLARE p_table VARCHAR(1024);
    DECLARE cur1 CURSOR FOR SELECT CONCAT
                            (TABLE_SCHEMA, ".", table_name)
                            FROM information_schema.tables WHERE TABLE_TYPE='BASE TABLE';
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET p_c = NULL;
    OPEN cur1;
    FETCH cur1 INTO p_Table;
    WHILE (p_c IS NOT NULL)
        DO
            SET @p_Table = p_Table;
            SET @SQL = CONCAT("select count(1) from  ", p_Table);
            PREPARE smtm FROM @SQL;
            EXECUTE smtm;
            DEALLOCATE PREPARE smtm;
                FETCH cur1 INTO p_Table;
    END WHILE;
    CLOSE cur1;
END //
delimiter ;
