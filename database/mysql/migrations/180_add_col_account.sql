-- 180_add_col_account.sql
-- Add column account 
-- June 15, 2026
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
        AND COLUMN_NAME = 'last_feed_price_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN last_feed_price_id INT UNSIGNED
        AFTER last_sow_boar_count_id;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account' 
        AND COLUMN_NAME = 'data_ver_num_last_feed_price';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN data_ver_num_last_feed_price INT UNSIGNED DEFAULT 0
        AFTER data_ver_num_sd_chklst;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_account();
DROP PROCEDURE add_col_account;
