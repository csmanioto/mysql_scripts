SET @database = 'XXX';
SET @tabela = 'YYY'; 

SELECT
    CONCAT(FORMAT(DAT/POWER(1024,pw1),2),' ',SUBSTR(units,pw1*2+1,2)) DATA_SIZE,
    CONCAT(FORMAT(NDX/POWER(1024,pw2),2),' ',SUBSTR(units,pw2*2+1,2)) INDX_SIZE,
    CONCAT(FORMAT(TBL/POWER(1024,pw3),2),' ',SUBSTR(units,pw3*2+1,2)) TABL_SIZE
FROM
(
    SELECT DAT,NDX,TBL,IF(px>4,4,px) pw1,IF(py>4,4,py) pw2,IF(pz>4,4,pz) pw3
    FROM
    (
        SELECT data_length DAT,index_length NDX,data_length+index_length TBL,
        FLOOR(LOG(IF(data_length=0,1,data_length))/LOG(1024)) px,
        FLOOR(LOG(IF(index_length=0,1,index_length))/LOG(1024)) py,
        FLOOR(LOG(IF(data_length+index_length=0,1,data_length+index_length))/LOG(1024)) pz
        FROM information_schema.tables
        WHERE table_schema=@database
        AND table_name= @tabela
    ) AA
) A,(SELECT 'B KBMBGBTB' units) B;
