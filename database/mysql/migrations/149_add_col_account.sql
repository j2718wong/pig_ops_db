-- 149_add_col_account.sql
-- Add column account 
-- May 20, 2026
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
        AND COLUMN_NAME = 'data_ver_num_sd_chklst';
    
    IF col_exists = 0 THEN
        ALTER TABLE account
        ADD COLUMN data_ver_num_sd_chklst INT UNSIGNED DEFAULT 0
        AFTER data_ver_num_pig_buyer;
    END IF;
    
    
END$$

DELIMITER ;

CALL add_col_account();
DROP PROCEDURE add_col_account;
