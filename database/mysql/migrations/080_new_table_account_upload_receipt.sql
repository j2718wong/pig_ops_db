-- 080_new_table_account_upload_receipt.sql
-- May 5, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_account_upload_receipt $$
CREATE PROCEDURE add_table_account_upload_receipt()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `account_upload_receipt` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `account_id` int(10) unsigned DEFAULT NULL,
      `account_bill_id` int(10) unsigned DEFAULT NULL,
      `flag` int(10) unsigned DEFAULT 0,
      `file_path` varchar(255) DEFAULT NULL,
      `added_by_user_id` int(10) unsigned DEFAULT NULL,
      `dt_entry` datetime DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `INDEX_ACCOUNT_ID` (`account_id`)
    );

    
END$$

DELIMITER ;

CALL add_table_account_upload_receipt();
DROP PROCEDURE add_table_account_upload_receipt;
