-- 117_add_col_account_bill.sql
-- Add columns  account_bill 
-- May 14, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_account_bill $$
CREATE PROCEDURE add_col_account_bill()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'prev_account_bill_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN prev_account_bill_id INT UNSIGNED 
        AFTER currency_code;
    END IF;
    
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'prev_amount_balance';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN prev_amount_balance DECIMAL(8,2) UNSIGNED 
        AFTER prev_account_bill_id;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_account_bill();
DROP PROCEDURE add_col_account_bill;
