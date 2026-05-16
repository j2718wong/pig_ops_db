-- 121_add_col_account_receipt.sql
-- Add column account 
-- May 15, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_account_receipt $$
CREATE PROCEDURE add_col_account_receipt()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_upload_receipt' 
        AND COLUMN_NAME = 'date_input_data_entry';
    
    IF col_exists = 0 THEN
        ALTER TABLE account_upload_receipt
        ADD COLUMN date_input_data_entry DATE
        AFTER data_entry_user_id;
    END IF;
    
    
    
    SET index_exists = 0;
    
    SELECT COUNT(*) INTO index_exists
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_upload_receipt' 
        AND INDEX_NAME = 'INDEX_ACC_RECEIPT_STATUS_ID';
    
    IF index_exists = 0 THEN
        CREATE INDEX INDEX_ACC_RECEIPT_STATUS_ID 
        ON account_upload_receipt (status_id);
    END IF;
    
    
    SET index_exists = 0;
    
    SELECT COUNT(*) INTO index_exists
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_upload_receipt' 
        AND INDEX_NAME = 'INDEX_DATA_ENTRY_USER_ID';
    
    IF index_exists = 0 THEN
        CREATE INDEX INDEX_DATA_ENTRY_USER_ID 
        ON account_upload_receipt (data_entry_user_id);
    END IF;
    
    
    
    SET index_exists = 0;
    
    SELECT COUNT(*) INTO index_exists
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account_upload_receipt' 
        AND INDEX_NAME = 'INDEX_DATE_DATA_ENTRY';
    
    IF index_exists = 0 THEN
        CREATE INDEX INDEX_DATE_DATA_ENTRY 
        ON account_upload_receipt (date_input_data_entry);
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_account_receipt();
DROP PROCEDURE add_col_account_receipt;
