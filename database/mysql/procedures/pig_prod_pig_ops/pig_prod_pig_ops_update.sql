DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_ops_update $$
CREATE PROCEDURE pig_prod_pig_ops_update(
    in_user_id                  INT,
   
    in_pig_prod_pig_ops_id      INT,
    in_staff_id                 INT,
    in_date                     VARCHAR(10),
    in_notes                    VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_pig_ops entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_CANNOT_BE_UDPATED               INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING            INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_GROWING              INT             DEFAULT 3;



DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_operation_type     INT             DEFAULT 0;

DECLARE cur_prod_pig_ops_id                     INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        b.account_id,
        a.pig_prod_id,
        a.operation_type,
        b.prod_status_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_id,
        cur_pig_prod_pig_ops_operation_type,
        cur_pig_prod_status_id
        
FROM    pig_prod_pig_ops a
LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id
WHERE   a.id = in_pig_prod_pig_ops_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS,
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


IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
    IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
        SET res_num     = RES_NUM_CANNOT_BE_UDPATED;
        SET res_code    = "RES_NUM_CANNOT_BE_UDPATED";
        
        LEAVE process_user;
    END IF;
END IF;


UPDATE pig_prod_pig_ops SET
    date_actual         = in_date,
    notes               = in_notes,
    staff_id            = in_staff_id,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_pig_prod_pig_ops_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_pig_ops_id              AS pig_prod_pig_ops_id;
    

END $$

DELIMITER ;
