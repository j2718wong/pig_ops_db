-- 129_new_table_pig_farm_sow_due_chklist.sql
-- May 18, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_pig_farm_sow_due_chklst $$
CREATE PROCEDURE add_table_pig_farm_sow_due_chklist()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `pig_farm_sow_due_chklst` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `pig_farm_id` int(10) unsigned DEFAULT NULL,
      `flag` int(10) unsigned DEFAULT 0,
      
      `date_start_show` DATE DEFAULT NULL,
      `date_start_end` DATE DEFAULT NULL,
      
      `dt_entry` datetime DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `INDEX_PIG_FARM_ID` (`pig_farm_id`)
    );

    
END$$

DELIMITER ;

CALL add_table_pig_farm_sow_due_chklist();
DROP PROCEDURE add_table_pig_farm_sow_due_chklist;
