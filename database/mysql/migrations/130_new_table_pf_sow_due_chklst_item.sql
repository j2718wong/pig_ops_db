-- 129_new_table_pf_sow_due_chklst_item.sql
-- May 18, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_pf_sow_due_chklst_item $$
CREATE PROCEDURE add_table_pf_sow_due_chklst_item()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `pf_sow_due_chklst_item` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `pf_sow_due_chklst_id` int(10) unsigned DEFAULT NULL,
      `flag` int(10) unsigned DEFAULT 0,
      
      `acc_sow_due_chklst_id` int(10) unsigned DEFAULT NULL,
      
      `date_checked` DATETIME DEFAULT NULL,
      `checked_user_id` int(10) unsigned DEFAULT NULL,
      `dt_entry` datetime DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `INDEX_PF_CHKLST_ID` (`pf_sow_due_chklst_id`)
    );

    
END$$

DELIMITER ;

CALL add_table_pf_sow_due_chklst_item();
DROP PROCEDURE add_table_pf_sow_due_chklst_item;
