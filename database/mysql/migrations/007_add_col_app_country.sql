-- 007_acc_col_app_country.sql
-- Add app_country.report_languages
-- March 27, 2026
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
        AND COLUMN_NAME = 'report_languages';
    
    IF col_exists = 0 THEN
        ALTER TABLE app_country 
        ADD COLUMN report_languages VARCHAR(160)  
        AFTER name;
    END IF;
    
    
    SET col_exists = 0;
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm_report' 
        AND COLUMN_NAME = 'report_language';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm_report 
        ADD COLUMN report_language VARCHAR(8)  
        AFTER report_date;
    END IF;
    
    
    UPDATE app_country SET
        report_languages = "en, ph-tag, ph-bis"
    WHERE id = 1;
    
    
END$$

DELIMITER ;

CALL add_col_app_country();
DROP PROCEDURE add_col_app_country;
