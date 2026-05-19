-- 133_add_col_pig_farm_sow_due_chklst_sow_due_chklst.sql
-- Add column pig_farm_sow_due_chklst_sow_due_chklst 
-- May 19, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_pig_farm_sow_due_chklst $$
CREATE PROCEDURE add_col_pig_farm_sow_due_chklst()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm_sow_due_chklst' 
        AND COLUMN_NAME = 'data_ver_num_chklst';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm_sow_due_chklst
        ADD COLUMN data_ver_num_chklst INT UNSIGNED DEFAULT 0
        AFTER dt_entry;
    END IF;
    
    
END$$

DELIMITER ;

CALL add_col_pig_farm_sow_due_chklst();
DROP PROCEDURE add_col_pig_farm_sow_due_chklst;
