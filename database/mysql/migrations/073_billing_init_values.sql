-- 073_billing_init_values.sql
-- Add 
-- May 3, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS billing_init_values $$
CREATE PROCEDURE billing_init_values()
BEGIN
    DECLARE cur_count INT DEFAULT 0;
    
    SELECT  COUNT(*)
    INTO    cur_count
    FROM    a01_list_of_values
    WHERE   id = 4;
    
    IF cur_count = 0 THEN
        INSERT INTO a01_list_of_values(
            name,
            description,
            val_int
        ) VALUES(
            'BILLING_NUM_DAYS_DUE_DATE',
            'Number of days due date after bill issue',
            15
        );
        
    ELSE
        UPDATE a01_list_of_values SET
            name            = 'BILLING_NUM_DAYS_DUE_DATE',
            description     = 'Number of days due date after bill issue',
            val_int         = 15
        WHERE id = 1;
    END IF;
    
    
    
    
    
    
END$$

DELIMITER ;

CALL billing_init_values();
DROP PROCEDURE billing_init_values;
