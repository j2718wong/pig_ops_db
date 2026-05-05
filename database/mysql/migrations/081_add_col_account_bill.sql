-- 081_add_col_account_bill.sql
-- Add account_bill.upload_receipt_id 
-- May 5, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_account_bill $$
CREATE PROCEDURE add_col_account_bill()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'upload_receipt_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN upload_receipt_id INT UNSIGNED    
        AFTER sow_boar_head_count_id;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'date_upload_payment_receipt';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN date_upload_payment_receipt DATE    
        AFTER date_due;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'date_payment_verified';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN date_payment_verified DATE    
        AFTER date_upload_payment_receipt;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'payment_verified_user_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN payment_verified_user_id INT UNSIGNED    
        AFTER last_update_user_id;
    END IF;
    
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'dt_payment_verified';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN dt_payment_verified DATETIME    
        AFTER payment_verified_user_id;
    END IF;
    
    
    

    
END$$

DELIMITER ;

CALL add_col_account_bill();
DROP PROCEDURE add_col_account_bill;
