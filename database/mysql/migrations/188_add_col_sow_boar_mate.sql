-- 188_add_col_sow_boar_mate.sql
-- Add column sow_boar_mate 
-- September 3, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_sow_boar_mate $$
CREATE PROCEDURE add_col_sow_boar_mate()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'sow_boar_mate' 
        AND COLUMN_NAME = 'flag';
    
    IF col_exists = 0 THEN
        ALTER TABLE sow_boar_mate
        ADD COLUMN flag INT UNSIGNED DEFAULT 0
        AFTER boar_customer_id;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_sow_boar_mate();
DROP PROCEDURE add_col_sow_boar_mate;
