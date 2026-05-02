-- 062_add_col_pig_farm.sql
-- Add pig_farm.count_sow_boar and pig_farm.count_pig_prod 
-- May 1, 2026
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
        AND COLUMN_NAME = 'count_sow_boar';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN count_sow_boar INT UNSIGNED DEFAULT 0   
        AFTER last_summary_report_id;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'count_pig_prod';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN count_pig_prod INT UNSIGNED DEFAULT 0   
        AFTER count_sow_boar;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_pig_farm();
DROP PROCEDURE add_col_pig_farm;
