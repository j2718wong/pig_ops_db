-- 047_rename_table_account_notification.sql
-- rename table account_notification to email_notification
-- April 17, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS rename_table_account_notification $$
CREATE PROCEDURE rename_table_account_notification()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    RENAME TABLE account_notification TO email_notification;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'email_notification' 
        AND COLUMN_NAME = 'user_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE email_notification
        ADD COLUMN user_id INT UNSIGNED   
        AFTER account_id;
        
        CREATE INDEX INDEX_USER_ID ON email_notification(user_id);
    END IF;
    
    
    
END$$

DELIMITER ;

CALL rename_table_account_notification();
DROP PROCEDURE rename_table_account_notification;
