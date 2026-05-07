-- 089_add_col_account_bill.sql
-- Add account_bill.upload_receipt_id 
-- May 6, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_account_bill $$
CREATE PROCEDURE add_col_account_bill()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'dt_email_bill_notify';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN dt_email_bill_notify DATETIME    
        AFTER dt_last_update;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'dt_email_near_due_1';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN dt_email_near_due_1 DATETIME    
        AFTER dt_email_bill_notify;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'dt_email_near_due_2';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN dt_email_near_due_2 DATETIME    
        AFTER dt_email_near_due_1;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_account_bill();
DROP PROCEDURE add_col_account_bill;
