-- 107_add_col_account.sql
-- Add  
-- May 10, 2026
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
        AND COLUMN_NAME = 'num_days_prep_lead';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN num_days_prep_lead INT UNSIGNED DEFAULT 4
        COMMENT 'Days before gestating medvac operation to send preparation notification'   
        AFTER flag_settings;
    END IF;

    
END$$

DELIMITER ;

CALL add_col_account();
DROP PROCEDURE add_col_account;
