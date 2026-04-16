-- 041_new_table_account_notification.sql
-- April 16, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_account_notification $$
CREATE PROCEDURE add_table_account_notification()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `account_notification` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `account_id` int(10) unsigned DEFAULT NULL,
    `notification_type_id` int(10) unsigned DEFAULT NULL,
    `flag` int(10) unsigned DEFAULT 0,
    `date_sent` date DEFAULT NULL,
    `dt_entry` datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `INDEX_ACCOUNT_ID` (`account_id`)
    );
    
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account' 
        AND COLUMN_NAME = 'last_notify_inactive_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account 
        ADD COLUMN last_notify_inactive_id INT UNSIGNED  
        AFTER data_ver_num_pig_buyer;
    END IF;
    

    
END$$

DELIMITER ;

CALL add_table_account_notification();
DROP PROCEDURE add_table_account_notification;
