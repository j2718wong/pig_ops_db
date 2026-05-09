-- 099_eod_init_values.sql
-- Add 
-- May 3, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS eod_init_values $$
CREATE PROCEDURE eod_init_values()
BEGIN
    DECLARE cur_count INT DEFAULT 0;
    
    SELECT  COUNT(*)
    INTO    cur_count
    FROM    a01_list_of_values
    WHERE   id = 5;
    
    IF cur_count = 0 THEN
        INSERT INTO a01_list_of_values(
            name,
            description,
            val_int
        ) VALUES(
            'LAST_BG_PROCESS_RUN_ID_EOD_SOW_BOAR_COUNT',
            'Last bg_process_run for EodSowBoarCountAllAccounts',
            0
        );
        
    ELSE
        UPDATE a01_list_of_values SET
            name            = 'LAST_BG_PROCESS_RUN_ID_EOD_SOW_BOAR_COUNT',
            description     = 'Last bg_process_run for EodSowBoarCountAllAccounts',
            val_int         = 0
        WHERE id = 1;
    END IF;
    
    
    
    
    
    
END$$

DELIMITER ;

CALL eod_init_values();
DROP PROCEDURE eod_init_values;
