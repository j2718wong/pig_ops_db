-- 049_add_col_email_notification.sql
-- Add email_notification.bg_process_run_id
-- April 20, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_email_notification $$
CREATE PROCEDURE add_col_email_notification()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'email_notification' 
        AND COLUMN_NAME = 'bg_process_run_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE email_notification
        ADD COLUMN bg_process_run_id INT UNSIGNED   
        AFTER user_id;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_email_notification();
DROP PROCEDURE add_col_email_notification;
