-- 066_account_free_trial_init_values.sql
-- Add 
-- May 1, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS account_free_trial_init_values $$
CREATE PROCEDURE account_free_trial_init_values()
BEGIN
    DECLARE cur_count INT DEFAULT 0;
    
    SELECT  COUNT(*)
    INTO    cur_count
    FROM    a01_list_of_values
    WHERE   id = 1;
    
    IF cur_count = 0 THEN
        INSERT INTO a01_list_of_values(
            name,
            description,
            val_int
        ) VALUES(
            'ACCOUNT_NUMDAYS_FREE_TRIAL',
            'Number of days free trial',
            90
        );
        
    ELSE
        UPDATE a01_list_of_values SET
            name            = 'ACCOUNT_NUMDAYS_FREE_TRIAL',
            description     = 'Number of days free trial',
            val_int         = 90
        WHERE id = 1;
    END IF;
    
    
    SELECT  COUNT(*)
    INTO    cur_count
    FROM    a01_list_of_values
    WHERE   id = 2;
    
    IF cur_count = 0 THEN
        INSERT INTO a01_list_of_values(
            name,
            description,
            val_int
        ) VALUES(
            'ACC_MAX_NUM_SOW_BOAR_FREE',
            'Maximum number of sow,boar that is free',
            3
        );
        
    ELSE
        UPDATE a01_list_of_values SET
            name            = 'ACC_MAX_NUM_SOW_BOAR_FREE',
            description     = 'Maximum number of sow,boar that is free',
            val_int         = 3
        WHERE id = 2;
    END IF;
    
    
    SELECT  COUNT(*)
    INTO    cur_count
    FROM    a01_list_of_values
    WHERE   id = 3;
    
    IF cur_count = 0 THEN
        INSERT INTO a01_list_of_values(
            name,
            description,
            val_int
        ) VALUES(
            'ACC_MIN_NUM_SOW_BOAR_REFERRAL_ACTIVE',
            'Minimum number of sow,boar that the referral becomes active',
            5
        );
        
    ELSE
        UPDATE a01_list_of_values SET
            name            = 'ACC_MIN_NUM_SOW_BOAR_REFERRAL_ACTIVE',
            description     = 'Minimum number of sow,boar that the referral becomes active',
            val_int         = 5
        WHERE id = 3;
    END IF;
    
    
    
    
END$$

DELIMITER ;

CALL account_free_trial_init_values();
DROP PROCEDURE account_free_trial_init_values;
