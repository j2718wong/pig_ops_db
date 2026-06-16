-- 182_add_col_pig_farm.sql
-- Add column pig_farm 
-- June 16, 2026
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
        AND COLUMN_NAME = 'fixed_expense_electric';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN fixed_expense_electric DECIMAL(8,2)
        AFTER dt_entry;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'fixed_expense_water';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN fixed_expense_water DECIMAL(8,2)
        AFTER fixed_expense_electric;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'fixed_expense_internet';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN fixed_expense_internet DECIMAL(8,2)
        AFTER fixed_expense_water;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'fixed_expense_staff';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN fixed_expense_staff DECIMAL(8,2)
        AFTER fixed_expense_internet;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'fixed_expense_fuel';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN fixed_expense_fuel DECIMAL(8,2)
        AFTER fixed_expense_staff;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'fixed_expense_supplies';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN fixed_expense_supplies DECIMAL(8,2)
        AFTER fixed_expense_fuel;
    END IF;
    
    
    SET col_exists = 0;
   
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'fixed_expense_other';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN fixed_expense_other DECIMAL(8,2)
        AFTER fixed_expense_supplies;
    END IF;
    
    
    SET col_exists = 0;
   
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'data_ver_num_fixed_expense';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm
        ADD COLUMN data_ver_num_fixed_expense INT UNSIGNED DEFAULT 0        
        AFTER data_ver_num_prod_fatten;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_pig_farm();
DROP PROCEDURE add_col_pig_farm;
