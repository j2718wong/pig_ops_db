-- 098_add_col_bg_process_run.sql
-- Add bg_process_run 
-- May 8, 2026
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
        AND COLUMN_NAME = 'dt_send_push_notify';
    
    IF col_exists = 0 THEN
        ALTER TABLE bg_process_run
        ADD COLUMN dt_send_push_notify DATETIME    
        AFTER business_date;
    END IF;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'bg_process_run' 
        AND COLUMN_NAME = 'dt_send_email_notify';
    
    IF col_exists = 0 THEN
        ALTER TABLE bg_process_run
        ADD COLUMN dt_send_email_notify DATETIME    
        AFTER dt_send_push_notify;
    END IF;
    
    
    
    
END$$

DELIMITER ;

CALL add_col_bg_process_run();
DROP PROCEDURE add_col_bg_process_run;
