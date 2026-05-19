-- 127_new_table_account_sow_due_chklst.sql
-- May 18, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_account_sow_due_chklst $$
CREATE PROCEDURE add_table_account_sow_due_chklst()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `account_sow_due_chklst` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `account_id` int(10) unsigned DEFAULT NULL,
      `flag` int(10) unsigned DEFAULT 0,
      `order_number` int(10) unsigned DEFAULT NULL,
      `name` VARCHAR(50),
      `added_by_user_id` int(10) unsigned DEFAULT NULL,
      `last_update_user_id` int(10) unsigned DEFAULT NULL,
      `dt_last_update` datetime DEFAULT NULL,
      `dt_entry` datetime DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `INDEX_ACCOUNT_ID` (`account_id`)
    );

    
END$$

DELIMITER ;

CALL add_table_account_sow_due_chklst();
DROP PROCEDURE add_table_account_sow_due_chklst;
