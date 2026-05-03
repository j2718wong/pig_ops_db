-- 070_add_col_account.sql
-- Add account.date_next_sow_boar_count and account.last_sow_boar_count_id 
-- May 2, 2026
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
        AND COLUMN_NAME = 'date_next_sow_boar_count';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN date_next_sow_boar_count DATE    
        AFTER date_trial_end;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account' 
        AND COLUMN_NAME = 'last_sow_boar_count_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN last_sow_boar_count_id INT UNSIGNED;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_account();
DROP PROCEDURE add_col_account;
