-- 172_add_col_account.sql
-- Add column account 
-- May 20, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_account $$
CREATE PROCEDURE add_col_account()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account' 
        AND COLUMN_NAME = 'day_of_week_feed_inventory';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN day_of_week_feed_inventory INT UNSIGNED
        AFTER num_days_harvest_from_wean;
    END IF;
    
    
END$$

DELIMITER ;

CALL add_col_account();
DROP PROCEDURE add_col_account;
