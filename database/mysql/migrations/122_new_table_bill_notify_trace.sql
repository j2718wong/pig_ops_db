-- 122_new_table_bill_notify_trace.sql
-- May 16, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_account_bill_notify_trace $$
CREATE PROCEDURE add_table_account_bill_notify_trace()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `bill_notify_trace` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `account_bill_id` int(10) unsigned DEFAULT NULL,
      `user_id` int(10) unsigned DEFAULT NULL,
      `notify_type` VARCHAR(2),
      `notify_message` VARCHAR(30),
      `dt_notify` datetime DEFAULT NULL,
      `dt_entry` datetime DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `INDEX_ACCOUNT_BILL_ID` (`account_bill_id`)
    );

    
END$$

DELIMITER ;

CALL add_table_account_bill_notify_trace();
DROP PROCEDURE add_table_account_bill_notify_trace;
