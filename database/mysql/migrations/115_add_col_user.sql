-- 115_add_col_user.sql
-- Add 
-- May 13, 2026
-- Jack Wong

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_user $$
CREATE PROCEDURE add_col_user()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user' 
        AND COLUMN_NAME = 'last_notify_no_pwa_app_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE user
        ADD COLUMN last_notify_no_pwa_app_id INT UNSIGNED 
        AFTER last_notify_inc_account_id;
    END IF;
    
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user' 
        AND COLUMN_NAME = 'count_email_notify_inc_account';
    
    IF col_exists = 0 THEN
        ALTER TABLE user
        ADD COLUMN count_email_notify_inc_account INT UNSIGNED  DEFAULT 0
        AFTER dt_entry;
    END IF;
    
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user' 
        AND COLUMN_NAME = 'count_email_notify_no_pwa_app';
    
    IF col_exists = 0 THEN
        ALTER TABLE user
        ADD COLUMN count_email_notify_no_pwa_app INT UNSIGNED  DEFAULT 0
        AFTER count_email_notify_inc_account;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_user();
DROP PROCEDURE add_col_user;
