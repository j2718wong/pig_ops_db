-- 155_add_col_pig_farm.sql
-- Add column pig_farm 
-- May 22, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_pig_farm $$
CREATE PROCEDURE add_col_pig_farm()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'data_ver_num_sb_disposed';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN data_ver_num_sb_disposed INT UNSIGNED DEFAULT 0;
    END IF;
    
    
END$$

DELIMITER ;

CALL add_col_pig_farm();
DROP PROCEDURE add_col_pig_farm;
