-- 037_add_col_user_unverified.sql
-- Add pig_farm.data_ver_num_farm
-- April 7, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_user_unverified $$
CREATE PROCEDURE add_col_user_unverified()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_unverified' 
        AND COLUMN_NAME = 'name_first';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_unverified 
        ADD COLUMN name_first VARCHAR(50)   
        AFTER email;
    END IF;
    
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_unverified' 
        AND COLUMN_NAME = 'name_last';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_unverified 
        ADD COLUMN name_last VARCHAR(50)   
        AFTER email;
    END IF;
    
   
    
END$$

DELIMITER ;

CALL add_col_user_unverified();
DROP PROCEDURE add_col_user_unverified;
