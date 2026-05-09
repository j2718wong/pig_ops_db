-- 103_bg_process_init_values.sql
-- Add 
-- May 3, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS bg_process_init_values $$
CREATE PROCEDURE bg_process_init_values()
BEGIN
    DECLARE cur_count INT DEFAULT 0;
    
    
    UPDATE bg_process SET
        name = NULL
    WHERE id = 3;
    
    
    
    -- Core Billing Processes (21-30)
    UPDATE bg_process SET
        name = 'BG_PROCESS_EOD_COUNT_BILLABLE_PIGS_ALL_ACCOUNTS'
    WHERE id = 21;

    UPDATE bg_process SET
        name = 'BG_PROCESS_PUSH_NOTIFY_NEW_BILLS'
    WHERE id = 22;

    UPDATE bg_process SET
        name = 'BG_PROCESS_EMAIL_NOTIFY_NEW_BILLS'
    WHERE id = 23;

    UPDATE bg_process SET
        name = 'BG_PROCESS_PUSH_NOTIFY_REMINDER_1_NOT_PAID_BILLS'
    WHERE id = 24;

    UPDATE bg_process SET
        name = 'BG_PROCESS_EMAIL_NOTIFY_REMINDER_1_NOT_PAID_BILLS'
    WHERE id = 25;

    UPDATE bg_process SET
        name = 'BG_PROCESS_EMAIL_NOTIFY_OVERDUE_BILLS'
    WHERE id = 26;


    -- Farm Operations Processes (31-50)
    UPDATE bg_process SET
        name = 'BG_PROCESS_PUSH_NOTIFY_SOW_MOVE_IN_TO_FARROW'
    WHERE id = 31;

    UPDATE bg_process SET
        name = 'BG_PROCESS_PUSH_NOTIFY_GESTATING_SOW_MEDVAC'
    WHERE id = 32;

    UPDATE bg_process SET
        name = 'BG_PROCESS_PUSH_NOTIFY_SOW_MOVE_OUT_FARROW'
    WHERE id = 33;


END$$

DELIMITER ;

CALL bg_process_init_values();
DROP PROCEDURE bg_process_init_values;
