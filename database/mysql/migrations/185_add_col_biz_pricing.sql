-- 185_add_col_biz_pricing.sql
-- Add column biz_pricing 
-- June 27, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_biz_pricing $$
CREATE PROCEDURE add_col_biz_pricing()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'biz_pricing' 
        AND COLUMN_NAME = 'price_per_farm';
    
    IF col_exists = 0 THEN
        ALTER TABLE biz_pricing
        ADD COLUMN price_per_farm DECIMAL(6,1)
        AFTER price_per_head;
    END IF;
    
    
    UPDATE biz_pricing SET
        price_per_farm = 600.0
    WHERE id = 2;
    
    
END$$

DELIMITER ;

CALL add_col_biz_pricing();
DROP PROCEDURE add_col_biz_pricing;
