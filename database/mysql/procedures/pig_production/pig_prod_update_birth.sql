DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_birth $$
CREATE PROCEDURE pig_prod_update_birth(
    in_user_id                  INT,
    
    in_pig_prod_id              INT,
    
    in_date_actual_birth        VARCHAR(10),  /* in YYYY-MM-DD format*/
    in_num_pigs_dead_at_birth   INT,
    in_num_pigs_live_m          INT,
    in_num_pigs_live_f          INT,
    
    in_birth_staff_id           INT
    
)

BEGIN

/** 
 * Will update pig_production at piglets birth entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_STATUS_NOT_GESTATING   INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 10;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING            INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_GROWING              INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_count_pig_prod_pig_ops            INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        prod_status_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_status_id
        
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

IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
    SET res_num     = RES_NUM_PIG_PROD_STATUS_NOT_GESTATING ;
    SET res_code    = "RES_NUM_PIG_PROD_STATUS_NOT_GESTATING";
END IF;



UPDATE pig_production SET 
    date_actual_birth           = in_date_actual_birth,
    num_days_actual             = DATEDIFF(in_date_actual_birth, date_insemination),
    prod_status_id              = PRODUCTION_STATUS_ID_LACTATING,
    
    num_pigs_dead_at_birth      = in_num_pigs_dead_at_birth,
    num_pigs_live_m             = in_num_pigs_live_m,
    num_pigs_live_f             = in_num_pigs_live_f,
    
    num_pigs_current_m          = in_num_pigs_live_m,
    num_pigs_current_f          = in_num_pigs_live_f,
    
    birth_staff_id              = in_birth_staff_id,
    
    last_update_user_id         = in_user_id,
    dt_last_update              = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_id;


SELECT  COUNT(*)
INTO    cur_count_pig_prod_pig_ops
FROM    pig_prod_pig_ops
WHERE   pig_prod_id = in_pig_prod_id AND operation_type = PIG_OPERATION_TYPE_LACTATING;

IF cur_count_pig_prod_pig_ops = 0 THEN 
    /* Create pig_prod_pig_ops entry*/
    CALL pig_prod_pig_ops_add(
        in_user_id,
        
        cur_pig_prod_account_id, 
        PIG_OPERATION_TYPE_LACTATING,
        in_pig_prod_id,
        in_date_actual_birth
    );

END IF;

END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;


END $$

DELIMITER ;
