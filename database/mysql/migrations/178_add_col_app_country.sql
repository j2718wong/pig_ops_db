-- 178_add_col_app_country.sql
-- Add column app_country 
-- June 15, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_app_country $$
CREATE PROCEDURE add_col_app_country()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'app_country' 
        AND COLUMN_NAME = 'ave_price_puwt_gestating';
    
    IF col_exists = 0 THEN
        ALTER TABLE app_country
        ADD COLUMN ave_price_puwt_gestating decimal(6, 2)
        AFTER tax_rate;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'app_country' 
        AND COLUMN_NAME = 'ave_price_puwt_lactating';
    
    IF col_exists = 0 THEN
        ALTER TABLE app_country
        ADD COLUMN ave_price_puwt_lactating decimal(6, 2)
        AFTER ave_price_puwt_gestating;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'app_country' 
        AND COLUMN_NAME = 'ave_price_puwt_booster';
    
    IF col_exists = 0 THEN
        ALTER TABLE app_country
        ADD COLUMN ave_price_puwt_booster decimal(6, 2)
        AFTER ave_price_puwt_lactating;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'app_country' 
        AND COLUMN_NAME = 'ave_price_puwt_prestarter';
    
    IF col_exists = 0 THEN
        ALTER TABLE app_country
        ADD COLUMN ave_price_puwt_prestarter decimal(6, 2)
        AFTER ave_price_puwt_booster;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'app_country' 
        AND COLUMN_NAME = 'ave_price_puwt_starter';
    
    IF col_exists = 0 THEN
        ALTER TABLE app_country
        ADD COLUMN ave_price_puwt_starter decimal(6, 2)
        AFTER ave_price_puwt_prestarter;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'app_country' 
        AND COLUMN_NAME = 'ave_price_puwt_grower';
    
    IF col_exists = 0 THEN
        ALTER TABLE app_country
        ADD COLUMN ave_price_puwt_grower decimal(6, 2)
        AFTER ave_price_puwt_starter;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'app_country' 
        AND COLUMN_NAME = 'ave_price_puwt_finisher';
    
    IF col_exists = 0 THEN
        ALTER TABLE app_country
        ADD COLUMN ave_price_puwt_finisher decimal(6, 2)
        AFTER ave_price_puwt_grower;
    END IF;
    
    
    
    
END$$

DELIMITER ;

CALL add_col_app_country();
DROP PROCEDURE add_col_app_country;
