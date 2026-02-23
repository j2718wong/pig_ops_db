DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_weaning $$
CREATE PROCEDURE pig_prod_update_weaning(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_date_weaning         VARCHAR(10),
    
    in_num_pigs_female      INT,
    in_num_pigs_male        INT,
    
    /* There is an option to count the pigs 
    regardless of sex. This is because it maybe time 
    consuming to count per sex at wean. */
    in_num_pigs             INT,    
    
    in_total_weight         INT
)  

BEGIN

/** 
 * Will update weaning data for pig_production entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 27, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_UPDATE_WEAN_NOT_ALLOWED         INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;



DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE SOW_STATUS_ID_WEANING                   INT             DEFAULT 4;

DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;
DECLARE cur_pig_prod_date_weaning               DATE            DEFAULT NULL;

DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;

DECLARE cur_account_flag_settings               INT             DEFAULT 0;

DECLARE cur_count_account_pig_ops               INT             DEFAULT 0;
DECLARE cur_count_pig_prod_pig_ops              INT             DEFAULT 0;

DECLARE date_temp                               DATE            DEFAULT NULL;
DECLARE detected_date_weaning_change            INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        prod_status_id,
        flag,
        date_weaning
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        cur_pig_prod_flag,
        cur_pig_prod_date_weaning
        
FROM    pig_production 
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN


IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_LACTATING,
                                    PRODUCTION_STATUS_ID_WEANING) THEN 
    SET res_num     = RES_NUM_UPDATE_WEAN_NOT_ALLOWED;
    SET res_code    = "RES_NUM_UPDATE_WEAN_NOT_ALLOWED";
    SET res_desc    = "Production status not LACTATING or WEANING.";
    
    LEAVE process_user;
END IF;



/*
It is possible to change the pig_production.date_weaning after previously SET, 
but there is a series of operations to be done to the affected business objects. 
So that is why we need to check if the date_actual_birth is to be modified.
*/

IF cur_pig_prod_date_weaning IS NULL THEN 
    SET detected_date_weaning_change = 1;

ELSE
    SET date_temp = STR_TO_DATE(in_date_weaning, '%Y-%m-%d');
    
    IF date_temp != cur_pig_prod_date_weaning THEN 
        SET detected_date_weaning_change = 1;
    END IF;

END IF;




IF in_num_pigs IS NOT NULL THEN 
    UPDATE pig_production SET
        date_weaning                = in_date_weaning,
        prod_status_id              = PRODUCTION_STATUS_ID_WEANING,

        num_pigs_weaning_m          = NULL,
        num_pigs_weaning_f          = NULL,
        num_pigs_weaning            = in_num_pigs,

        num_pigs_current            = in_num_pigs,
        
        total_pigs_weight_weaning   = in_total_weight,
        
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP,
        
        data_ver_num_pig_prod       = data_ver_num_pig_prod + 1
        
    WHERE id = in_pig_prod_id;
    
ELSE
    UPDATE pig_production SET
        date_weaning                = in_date_weaning,
        prod_status_id              = PRODUCTION_STATUS_ID_WEANING,

        num_pigs_weaning_m          = in_num_pigs_male,
        num_pigs_weaning_f          = in_num_pigs_female,
        num_pigs_weaning            = NULL,

        num_pigs_current            = in_num_pigs_male + in_num_pigs_female,
        
        total_pigs_weight_weaning   = in_total_weight,
        
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP,
        
        data_ver_num_pig_prod       = data_ver_num_pig_prod + 1
        
    WHERE id = in_pig_prod_id;


END IF;



SELECT  sow_id
INTO    cur_pig_prod_sow_id
FROM    pig_production
WHERE   id = in_pig_prod_id;


UPDATE sow_boar SET
    sow_status_id = SOW_STATUS_ID_WEANING
WHERE id = cur_pig_prod_sow_id;



/* Count if there are pig operations to be done for weaning sow set by account.*/
SELECT  COUNT(*)
INTO    cur_count_account_pig_ops
FROM    account_pig_ops
WHERE   account_id = cur_pig_prod_account_id  AND 
        operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS AND 
        (flag & FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED) = 0;


IF cur_count_account_pig_ops > 0 THEN
    /* Count if there are already created pig_ops*/
    SELECT  COUNT(*)
    INTO    cur_count_pig_prod_pig_ops
    FROM    pig_prod_pig_ops
    WHERE   pig_prod_id = in_pig_prod_id AND 
            operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS;

    IF cur_count_pig_prod_pig_ops = 0 THEN 
        /* Create pig_prod_pig_ops entry*/
        CALL pig_prod_pig_ops_add(
            in_user_id,
            
            cur_pig_prod_account_id, 
            PIG_OPERATION_TYPE_WEANING_SOW_OPS,
            in_pig_prod_id,
            in_date_weaning
        );
        
        /* Since this is a weaning sow pig ops, need to relate to SOW.*/
        UPDATE pig_prod_pig_ops SET 
            sow_boar_id = cur_pig_prod_sow_id
        WHERE pig_prod_id = in_pig_prod_id AND operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS;
        
    ELSE
        IF detected_date_weaning_change > 0 THEN
            
            /* Need to adjust Day 1 counting.*/
            /*
            IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH = 0 THEN 
                UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                    a.date_target = DATE_ADD(in_date_weaning, INTERVAL b.num_days_since DAY)
                WHERE   a.pig_prod_id = in_pig_prod_id AND 
                        a.operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS AND
                        a.account_pig_ops_id = b.id;
            
            ELSE
                UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                    a.date_target = DATE_ADD(in_date_weaning, INTERVAL b.num_days_since - 1 DAY)
                WHERE   a.pig_prod_id = in_pig_prod_id AND 
                        a.operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS AND
                        a.account_pig_ops_id = b.id;
            END IF;
            
            */
            
            
            /* in_date_weaning is DAY 0 after wean */
            UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                a.date_target = DATE_ADD(in_date_weaning, INTERVAL b.num_days_since DAY)
            WHERE   a.pig_prod_id = in_pig_prod_id AND 
                    a.operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS AND
                    a.account_pig_ops_id = b.id;
        
        END IF;

    END IF;


END IF;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_prod_id;
    

END $$

DELIMITER ;
