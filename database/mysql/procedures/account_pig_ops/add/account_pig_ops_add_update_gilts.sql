DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_add_update_gilts $$
CREATE PROCEDURE account_pig_ops_add_update_gilts(
    in_account_id           INT,
    in_operation_type       INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 12, 2025
 *
 */

DECLARE SOW_STATUS_GROWING                      INT             DEFAULT 1;

DECLARE cur_sow_id                              INT             DEFAULT 0;
DECLARE cur_sow_date_of_birth                   DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_gilts CURSOR FOR
    SELECT  id,
            date_of_birth
    FROM    sow_boar
    WHERE   account_id      = in_account_id AND 
            sex = 'F'                       AND
            date_of_birth IS NOT NULL       AND
            sow_status_id   = SOW_STATUS_GROWING
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 




SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;


IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH > 0 THEN 
    SET num_days_to_add = in_num_days_since - 1;
ELSE
    SET num_days_to_add = in_num_days_since;
END IF;
    

    
SET l_last_row_fetched=0;
OPEN c_account_gilts;   
    

loop_here: LOOP
    FETCH c_account_gilts INTO 
        cur_sow_id,
        cur_sow_date_of_birth;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    INSERT INTO pig_prod_pig_ops(
        sow_boar_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        cur_sow_id,
        in_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(cur_sow_date_of_birth, INTERVAL num_days_to_add DAY)
    );
    

END LOOP loop_here;
 
CLOSE c_account_gilts;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
