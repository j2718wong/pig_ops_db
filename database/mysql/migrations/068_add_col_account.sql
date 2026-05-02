-- 068_add_col_account.sql
-- Add account.count_sow_boar and account.count_pig_prod 
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
        AND COLUMN_NAME = 'count_sow_boar';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN count_sow_boar INT UNSIGNED DEFAULT 0   
        AFTER dt_entry;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account' 
        AND COLUMN_NAME = 'count_pig_prod';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN count_pig_prod INT UNSIGNED DEFAULT 0   
        AFTER count_sow_boar;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_account();
DROP PROCEDURE add_col_account;
