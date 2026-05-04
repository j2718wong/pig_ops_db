-- 076_add_col_account_bill.sql
-- Add account_bill.sow_boar_head_count_id 
-- May 2, 2026
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
        AND COLUMN_NAME = 'country_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN country_id INT UNSIGNED    
        AFTER date_due;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'tax_rate';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN tax_rate DECIMAL(4,2) UNSIGNED    
        AFTER country_id;
    END IF;
    
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'sow_boar_head_count_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN sow_boar_head_count_id INT UNSIGNED    
        AFTER status_id;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'num_sow_boar_billed';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN num_sow_boar_billed INT UNSIGNED    
        AFTER status_id;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'charge_per_pig';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN charge_per_pig DECIMAL(6,1) UNSIGNED    
        AFTER currency_code;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'deduction';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN deduction DECIMAL(8,2) UNSIGNED    
        AFTER amount;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'taxable_amount';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN taxable_amount DECIMAL(8,2) UNSIGNED    
        AFTER deduction;
    END IF;
    
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'taxes';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN taxes DECIMAL(8,2) UNSIGNED    
        AFTER taxable_amount;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND COLUMN_NAME = 'total_amount_due';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN total_amount_due DECIMAL(8,2) UNSIGNED    
        AFTER taxes;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_account_bill();
DROP PROCEDURE add_col_account_bill;
