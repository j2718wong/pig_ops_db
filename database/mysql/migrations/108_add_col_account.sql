-- 108_add_col_account.sql
-- Add  
-- May 11, 2026
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
        AND COLUMN_NAME = 'count_push_notify_no_sow_boar';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN count_push_notify_no_sow_boar INT UNSIGNED DEFAULT 0
        AFTER count_pig_prod;
    END IF;
    
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account' 
        AND COLUMN_NAME = 'count_email_notify_no_sow_boar';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN  count_email_notify_no_sow_boar INT UNSIGNED DEFAULT 0
        AFTER count_push_notify_no_sow_boar;
    END IF;
    
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account' 
        AND COLUMN_NAME = 'date_last_push_notify_no_sow_boar';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN date_last_push_notify_no_sow_boar DATE;
    END IF;
    

    
END$$

DELIMITER ;

CALL add_col_account();
DROP PROCEDURE add_col_account;
