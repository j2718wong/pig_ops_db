-- 023_add_col_pig_production.sql
-- Add pig_production.num_pigs_wean_xsmall
-- April 9, 2026
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
        AND COLUMN_NAME = 'num_pigs_wean_xsmall';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_production 
        ADD COLUMN num_pigs_wean_xsmall INT  
        AFTER num_pigs_weaning;
    END IF;
    
   
    
END$$

DELIMITER ;

CALL add_col_pig_production();
DROP PROCEDURE add_col_pig_production;
