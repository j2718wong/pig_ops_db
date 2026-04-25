-- 051_new_table_sow_boar_head_count.sql
-- April 21, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_sow_boar_head_count $$
CREATE PROCEDURE add_table_sow_boar_head_count()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `sow_boar_head_count` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `account_id` int(10) unsigned DEFAULT NULL,
    `pig_farm_id` int(10) unsigned DEFAULT NULL,
    `num_sow` int(10) unsigned DEFAULT NULL,
    `num_boar` int(10) unsigned DEFAULT NULL,
    `num_gilt` int(10) unsigned DEFAULT NULL,
    `business_date` DATE DEFAULT NULL,
    `dt_entry` datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `INDEX_ACCOUNT_ID` (`account_id`),
    KEY `INDEX_PIG_FARM_ID` (`pig_farm_id`)
    );
    
    

    
END$$

DELIMITER ;

CALL add_table_sow_boar_head_count();
DROP PROCEDURE add_table_sow_boar_head_count;
