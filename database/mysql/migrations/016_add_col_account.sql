-- 016_add_col_account.sql
-- Add account.num_days_move_to_farrow
-- April 7, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_account $$
CREATE PROCEDURE add_col_account()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account' 
        AND COLUMN_NAME = 'num_days_move_to_farrow';
    
    IF col_exists = 0 THEN
        ALTER TABLE account 
        ADD COLUMN num_days_move_to_farrow INT UNSIGNED DEFAULT 10  
        AFTER flag_settings;
    END IF;
    
   
    
END$$

DELIMITER ;

CALL add_col_account();
DROP PROCEDURE add_col_account;
