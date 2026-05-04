-- 077_add_col_app_country.sql
-- Add app_country.sow_boar_head_count_id 
-- May 4, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_app_country $$
CREATE PROCEDURE add_col_app_country()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'app_country' 
        AND COLUMN_NAME = 'tax_rate';
    
    IF col_exists = 0 THEN
        ALTER TABLE app_country
        ADD COLUMN tax_rate DECIMAL(4,2) UNSIGNED    
        AFTER report_languages;
    END IF;
    
    /* Pihilippines tax rate*/
    UPDATE app_country SET
        tax_rate =  12.0
    WHERE id = 1;
    
    
END$$

DELIMITER ;

CALL add_col_app_country();
DROP PROCEDURE add_col_app_country;
