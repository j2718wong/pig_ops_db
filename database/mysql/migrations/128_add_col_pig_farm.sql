-- 128_add_col_pig_farm.sql
-- Add column pig_farm 
-- May 18, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_pig_farm $$
CREATE PROCEDURE add_col_pig_farm()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'last_sow_due_chklst_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        RENAME COLUMN last_production_group_id TO last_sow_due_chklst_id;
    END IF;
    
    
END$$

DELIMITER ;

CALL add_col_pig_farm();
DROP PROCEDURE add_col_pig_farm;
