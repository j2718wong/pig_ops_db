-- 026_new_table_pricing.sql
-- Drops production_group* tables and add pricing table
-- April 11, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_biz_pricing $$
CREATE PROCEDURE add_table_biz_pricing()

BEGIN

DECLARE FLAG_BIT_PRICE_TAX_INCLUSIVE        INT             DEFAULT 1;


DECLARE cur_pricing_id                      INT             DEFAULT 0;    

    -- These tables are not needed anymore;
    DROP TABLE IF EXISTS production_group;
    DROP TABLE IF EXISTS production_group_pig_prod;
    DROP TABLE IF EXISTS production_grp_status;
    
    
    CREATE TABLE IF NOT EXISTS `biz_pricing` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `country_id` int(10) unsigned DEFAULT 0,
    `flag` int(10) unsigned DEFAULT 0,
    `currency_code` VARCHAR(5) DEFAULT NULL,
    `price_per_head` decimal(6,1) unsigned DEFAULT NULL,
    `tax_name_1` VARCHAR(20) DEFAULT NULL,
    `tax_name_2` VARCHAR(20) DEFAULT NULL,
    `tax_rate_1` decimal(4,2) unsigned DEFAULT NULL,
    `tax_rate_2` decimal(4,2) unsigned DEFAULT NULL,
    `dt_last_update` datetime DEFAULT NULL,
    `dt_entry` datetime DEFAULT current_timestamp(),
    PRIMARY KEY (`id`)
    );
    
    -- Check if the DEFAULT pricing already existing
    SELECT  id
    INTO    cur_pricing_id
    FROM    biz_pricing
    WHERE   country_id = 0 AND currency_code = 'USD'
    LIMIT   1;
    
    IF cur_pricing_id = 0 THEN 
        -- The default currency code is USD
        INSERT INTO biz_pricing(
            country_id,
            currency_code,
            price_per_head
        ) VALUES(
            0,
            'USD',
            2.5
        );
    END IF;
    
    
    -- Check if Philippines pricing already existing
    SET cur_pricing_id = 0;
    
    SELECT  id
    INTO    cur_pricing_id
    FROM    biz_pricing
    WHERE   country_id = 1
    LIMIT   1;
    
    IF cur_pricing_id = 0 THEN 
        INSERT INTO biz_pricing(
            country_id,
            currency_code,
            flag,
            price_per_head,
            
            tax_name_1
        ) VALUES(
            1,
            'PHP',
            FLAG_BIT_PRICE_TAX_INCLUSIVE,
            120.0,
            
            'VAT'
        );
    END IF;
    

    
END$$

DELIMITER ;

CALL add_table_biz_pricing();
DROP PROCEDURE add_table_biz_pricing;
