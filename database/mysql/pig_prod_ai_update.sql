DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_ai_update $$
CREATE PROCEDURE pig_prod_ai_update(
    in_user_id                  INT,
    
    in_pig_prod_ai_id           INT,
    in_semen_source_hid         INT,
    
    in_date_extracted           VARCHAR(10),
    in_date_insemination        VARCHAR(10)
    in_date_expiry              VARCHAR(10),
    in_hour_insemination        INT
    
    in_staff_id                 INT
)

BEGIN

/** 
 * Will update pig_prod_ai entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_AI             INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_ai_id                    INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_account_id            INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_flag                  INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_name                  VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  pig_prod_id
INTO    cur_pig_prod_id
FROM    pig_prod_ai
WHERE   id = in_pig_prod_ai_id
LIMIT   1;

SELECT  account_id
INTO    cur_pig_prod_account_id
FROM    pig_production
WHERE   id = cur_pig_prod_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id,
    
    BUSINESS_OBJ_ID_PIG_PROD_AI,
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




UPDATE pig_prod_ai SET
    semen_source_id     = in_semen_source_hid,
    
    date_extracted      = in_date_extracted,
    date_expiry         = in_date_expiry,
    date_insemination   = in_date_insemination,
    hour_insemination   = in_hour_insemination,
    staff_id            = in_staff_id,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_ai_id;

END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_ai_id                   AS pig_prod_ai_id;
   

END $$

DELIMITER ;
