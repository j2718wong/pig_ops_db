DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_insem $$
CREATE PROCEDURE pig_prod_update_insem(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    
    in_semen_cost           DECIMAL(6,2),
    in_insemination_cost    DECIMAL(6,2),
    in_insem_cost_comments  VARCHAR(200),
    
    in_insem_staff_id       INT,
    in_date_insemination    VARCHAR(10)  /* in YYYY-MM-DD format*/

)

BEGIN

/** 
 * Will update pig_production entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;

DECLARE cur_pig_prod_date_actual_birth          DATE;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_prod_account_id
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


SELECT  date_actual_birth
INTO    cur_pig_prod_date_actual_birth
FROM    pig_production
WHERE   id = in_pig_prod_id;


IF cur_pig_prod_date_actual_birth IS NOT NULL THEN 

    SET res_num     = RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA;
    SET res_code    = "RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA";
    SET res_desc    = "Cannot update insemination data after birth.";
    
    LEAVE process_user;

END IF;


UPDATE pig_production SET
    semen_cost          = in_semen_cost,
    insemination_cost   = in_insemination_cost,
    insem_cost_comments = in_insem_cost_comments,
    
    date_insemination   = in_date_insemination,
    date_expected_birth = DATE_ADD(in_date_insemination, INTERVAL 115 DAY),
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_id;

END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;
    


END $$

DELIMITER ;
