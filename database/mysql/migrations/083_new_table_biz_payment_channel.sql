-- 083_new_table_biz_payment_channel.sql
-- May 5, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_biz_payment_channel $$
CREATE PROCEDURE add_table_biz_payment_channel()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `biz_payment_channel` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `country_id` int(10) unsigned DEFAULT NULL,
      `flag` int(10) unsigned DEFAULT 0,
      `channel_type` int unsigned DEFAULT 0,
      `channel_name` varchar(80) DEFAULT NULL,
      `account_name` varchar(80) DEFAULT NULL,
      `account_number` varchar(20) DEFAULT NULL,
      `added_by_user_id` int(10) unsigned DEFAULT NULL,
      `dt_entry` datetime DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `INDEX_COUNTRY_ID` (`country_id`)
    );

    
END$$

DELIMITER ;

CALL add_table_biz_payment_channel();
DROP PROCEDURE add_table_biz_payment_channel;
