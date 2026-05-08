-- 094_add_col_account_bill.sql
-- Add account_bill.INDEX_DATE_ISSUE 
-- May 8, 2026
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
        AND COLUMN_NAME = 'bg_process_run_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_bill
        ADD COLUMN bg_process_run_id INT UNSIGNED 
        AFTER upload_receipt_count;
    END IF;
    
    
    SET index_exists = 0;
    
    SELECT COUNT(*) INTO index_exists
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_bill' 
        AND INDEX_NAME = 'INDEX_DATE_ISSUE';

    IF index_exists = 0 THEN
        CREATE INDEX INDEX_DATE_ISSUE 
        ON account_bill (date_issue);
    END IF;
    
    
    
    
    
END$$

DELIMITER ;

CALL add_col_account_bill();
DROP PROCEDURE add_col_account_bill;
