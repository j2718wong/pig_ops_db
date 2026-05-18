-- 125_add_col_common_supplier.sql
-- Add column account 
-- May 18, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_common_supplier $$
CREATE PROCEDURE add_col_common_supplier()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'common_supplier' 
        AND COLUMN_NAME = 'account_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE common_supplier
        ADD COLUMN account_id INT UNSIGNED
        AFTER id;
    END IF;
    
    
    SET index_exists = 0;
    
    SELECT COUNT(*) INTO index_exists
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'common_supplier' 
        AND INDEX_NAME = 'INDEX_ACCOUNT_ID';
    
    IF index_exists = 0 THEN
        CREATE INDEX INDEX_ACCOUNT_ID 
        ON common_supplier (account_id);
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_common_supplier();
DROP PROCEDURE add_col_common_supplier;
