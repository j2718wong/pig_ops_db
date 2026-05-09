-- 102_add_col_bg_process_run.sql
-- Add bg_process_run 
-- May 9, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_bg_process_run $$
CREATE PROCEDURE add_col_bg_process_run()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'bg_process_run' 
        AND COLUMN_NAME = 'push_notify_result';
    
    IF col_exists = 0 THEN
        ALTER TABLE bg_process_run
        ADD COLUMN push_notify_result VARCHAR(200)    
        AFTER business_date;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'bg_process_run' 
        AND COLUMN_NAME = 'email_notify_result';
    
    IF col_exists = 0 THEN
        ALTER TABLE bg_process_run
        ADD COLUMN email_notify_result VARCHAR(200)    
        AFTER push_notify_result;
    END IF;
    
    
    
    
END$$

DELIMITER ;

CALL add_col_bg_process_run();
DROP PROCEDURE add_col_bg_process_run;
