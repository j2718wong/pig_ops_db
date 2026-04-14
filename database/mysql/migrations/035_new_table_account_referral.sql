-- 035_new_table_account_referral.sql
-- April 13, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_account_referral $$
CREATE PROCEDURE add_table_account_referral()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `account_referral` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `account_id` int(10) unsigned DEFAULT NULL,
    `referred_account_id` int(10) unsigned DEFAULT NULL,
    `flag` int(10) unsigned DEFAULT 0,
    `business_date_active` date DEFAULT NULL,
    `dt_entry` datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `INDEX_ACCOUNT_ID` (`account_id`)
    );
    
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'account' 
        AND COLUMN_NAME = 'account_referral_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE account 
        ADD COLUMN account_referral_id INT UNSIGNED  
        AFTER status_id;
    END IF;
    

    
END$$

DELIMITER ;

CALL add_table_account_referral();
DROP PROCEDURE add_table_account_referral;
