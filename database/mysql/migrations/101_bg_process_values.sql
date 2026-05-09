-- 101_bg_process_values.sql
-- Add 
-- May 9, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS bg_process_init_values $$
CREATE PROCEDURE bg_process_init_values()
BEGIN
    DECLARE cur_count INT DEFAULT 0;
    DECLARE cur_index INT DEFAULT 0;
    
    SELECT  COUNT(*)
    INTO    cur_count
    FROM    bg_process;
    
    
    SET cur_index = cur_count;
    
    IF cur_count < 50 THEN 
        loop_here: LOOP
            INSERT INTO bg_process(
                name
            )
            VALUE(NULL);
            
            SET cur_index = cur_index + 1;
            IF cur_index >= 50 THEN 
                LEAVE loop_here;
            END IF;

        END LOOP loop_here;
    END IF;
    
    
    
    
END$$

DELIMITER ;

CALL bg_process_init_values();
DROP PROCEDURE bg_process_init_values;
