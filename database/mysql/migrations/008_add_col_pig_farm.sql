-- 008_add_col_pig_farm.sql
-- Add pig_farm.last_feed_balance_date
-- March 31, 2026
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
        AND COLUMN_NAME = 'last_feed_balance_date';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm 
        ADD COLUMN last_feed_balance_date DATE  
        AFTER name;
    END IF;
    
   
    
END$$

DELIMITER ;

CALL add_col_pig_farm();
DROP PROCEDURE add_col_pig_farm;
