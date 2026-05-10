-- 105_add_col_pig_prod_pig_ops.sql
-- Add pig_prod_pig_ops 
-- May 10, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_pig_prod_pig_ops $$
CREATE PROCEDURE add_col_pig_prod_pig_ops()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_prod_pig_ops' 
        AND COLUMN_NAME = 'account_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_prod_pig_ops
        ADD COLUMN account_id INT UNSIGNED    
        AFTER id;
    END IF;
    
    

    
    /** populate pig_prod_pig_ops.account_id */
    UPDATE pig_prod_pig_ops a, pig_production b SET 
        a.account_id = b.account_id
    WHERE a.pig_prod_id = b.id;
    
    
    /** Create index ON pig_prod_pig_ops.account_id */
    
    SET index_exists = 0;
    
    SELECT COUNT(*) INTO index_exists
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_prod_pig_ops' 
        AND INDEX_NAME = 'INDEX_ACCOUNT_ID';

    IF index_exists = 0 THEN
        CREATE INDEX INDEX_ACCOUNT_ID 
        ON pig_prod_pig_ops (account_id);
    END IF;
    
    
    
    
END$$

DELIMITER ;

CALL add_col_pig_prod_pig_ops();
DROP PROCEDURE add_col_pig_prod_pig_ops;
