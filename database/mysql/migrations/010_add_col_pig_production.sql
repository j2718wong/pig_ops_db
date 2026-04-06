-- 010_add_col_pig_production.sql
-- Add production group columns in pig_production
-- April 6, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_pig_production $$
CREATE PROCEDURE add_col_pig_production()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_production' 
        AND COLUMN_NAME = 'date_added_to_group';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_production 
        ADD COLUMN date_added_to_group DATE  
        AFTER wean_pigs_weight_pp;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_production' 
        AND COLUMN_NAME = 'added_to_group_by_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_production 
        ADD COLUMN added_to_group_by_id INT UNSIGNED  
        AFTER cost_finisher;
    END IF;
    

END$$

DELIMITER ;

CALL add_col_pig_production();
DROP PROCEDURE add_col_pig_production;
