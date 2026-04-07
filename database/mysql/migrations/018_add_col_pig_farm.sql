-- 018_add_col_pig_farm.sql
-- Add pig_farm.data_ver_num_farm
-- April 7, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_pig_farm $$
CREATE PROCEDURE add_col_pig_farm()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'data_ver_num_farm';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm 
        ADD COLUMN data_ver_num_farm INT UNSIGNED DEFAULT 0  
        AFTER last_summary_report_id;
    END IF;
    
   
    
END$$

DELIMITER ;

CALL add_col_pig_farm();
DROP PROCEDURE add_col_pig_farm;
