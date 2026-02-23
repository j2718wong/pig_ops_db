DELIMITER $$

DROP PROCEDURE IF EXISTS gilt_pig_ops_add $$
CREATE PROCEDURE gilt_pig_ops_add(
    in_user_id              INT,
    
    in_account_id           INT,
    in_operation_type       INT,
    in_sow_id               INT,
    in_date_reference       VARCHAR(10)
)  

BEGIN

/** 
 * A sub procedure to create pig_prod_pig_ops entries.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 12, 2025
 *
 */

DECLARE cur_account_flag_settings               INT             DEFAULT 0;
DECLARE cur_account_pig_ops_id                  INT             DEFAULT 0;
DECLARE cur_account_pig_ops_num_days            INT             DEFAULT 0;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_ops CURSOR FOR
    SELECT  id,
            num_days_since
    FROM    account_pig_ops
    WHERE   account_id = in_account_id      AND 
            operation_type = PIG_OPERATION_TYPE_GILT_OPS AND 
            (flag & 1) = 0
    ORDER BY num_days_since ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;


    
SET l_last_row_fetched=0;
OPEN c_account_pig_ops;   
    

loop_here: LOOP
    FETCH c_account_pig_ops INTO 
        cur_account_pig_ops_id,
        cur_account_pig_ops_num_days;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;


    /* Default*/
    SET num_days_to_add = cur_account_pig_ops_num_days;
    
    /* Need to adjust Day 1 counting.*/
    IF  in_operation_type = PIG_OPERATION_TYPE_GILT_OPS THEN 
        IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH > 0 THEN 
            SET num_days_to_add = cur_account_pig_ops_num_days - 1;
        ELSE
            SET num_days_to_add = cur_account_pig_ops_num_days;
        END IF;
    END IF;
    
   

    INSERT INTO pig_prod_pig_ops(
        pig_prod_id,
        
        sow_boar_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        NULL,
        
        in_sow_id,
        cur_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(in_date_reference, INTERVAL num_days_to_add DAY)
    );
    
    UPDATE sow_boar SET 
        data_ver_num_sow_boar   = data_ver_num_sow_boar + 1
    WHERE id = in_sow_id;
    

END LOOP loop_here;
 
CLOSE c_account_pig_ops;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
