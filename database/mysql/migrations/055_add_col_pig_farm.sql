-- 055_add_col_pig_farm.sql
-- Add pig_farm.data_ver_num_pig_dead
-- April 28, 2026
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
        AND COLUMN_NAME = 'data_ver_num_pig_dead';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN data_ver_num_pig_dead INT UNSIGNED DEFAULT 0   
        AFTER data_ver_num_not_pregnant;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'data_ver_num_boar_ext_mate';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN data_ver_num_boar_ext_mate INT UNSIGNED DEFAULT 0   
        AFTER data_ver_num_not_pregnant;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_pig_farm();
DROP PROCEDURE add_col_pig_farm;
