-- 118_add_col_account.sql
-- Add column account 
-- May 14, 2026
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
        AND COLUMN_NAME = 'previous_bill_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN previous_bill_id INT UNSIGNED DEFAULT 0
        AFTER num_bills_paid;
    END IF;
    

    
END$$

DELIMITER ;

CALL add_col_account();
DROP PROCEDURE add_col_account;
