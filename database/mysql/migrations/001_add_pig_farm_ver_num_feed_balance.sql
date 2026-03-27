-- 001_add_pig_farm_ver_num_feed_balance.sql
-- Add feed balance version column to pig_farm table
-- March 27, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_pig_farm_ver_num_feed_balance $$
CREATE PROCEDURE add_pig_farm_ver_num_feed_balance()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'data_ver_num_feed_balance';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm 
        ADD COLUMN data_ver_num_feed_balance INT UNSIGNED DEFAULT 0  
        AFTER data_ver_num_feed_buy;
    END IF;
    
    
END$$

DELIMITER ;

CALL add_pig_farm_ver_num_feed_balance();
DROP PROCEDURE add_pig_farm_ver_num_feed_balance;
