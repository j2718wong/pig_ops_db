-- 046_add_col_user_last_notify_inc_account.sql
-- Add user.last_notify_inc_account
-- April 7, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_user_last_notify_inc_account $$
CREATE PROCEDURE add_col_user_last_notify_inc_account()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user' 
        AND COLUMN_NAME = 'last_notify_inc_account';
    
    IF col_exists = 0 THEN
        ALTER TABLE user
        ADD COLUMN last_notify_inc_account INT UNSIGNED   
        AFTER dt_entry;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_user_last_notify_inc_account();
DROP PROCEDURE add_col_user_last_notify_inc_account;
