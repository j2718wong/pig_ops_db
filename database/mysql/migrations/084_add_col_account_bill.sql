-- 084_add_col_account_bill.sql
-- Add account_bill.upload_receipt_id 
-- May 5, 2026
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
        AND COLUMN_NAME = 'upload_receipt_count';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN upload_receipt_count INT UNSIGNED    
        AFTER upload_receipt_id;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'amount_paid';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN amount_paid DECIMAL(8,2) UNSIGNED    
        AFTER total_amount_due;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'amount_balance';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN amount_balance DECIMAL(8,2) UNSIGNED    
        AFTER amount_paid;
    END IF;
    
    
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'payment_channel_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN payment_channel_id INT UNSIGNED    
        AFTER last_update_user_id;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'payment_reference';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN payment_reference VARCHAR(32)    
        AFTER payment_verified_user_id;
    END IF;
    

    
END$$

DELIMITER ;

CALL add_col_account_bill();
DROP PROCEDURE add_col_account_bill;
