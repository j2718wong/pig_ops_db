DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_dead_update $$
CREATE PROCEDURE pig_prod_pig_dead_update(
    in_user_id                  INT,
    
    in_pig_prod_pig_dead_id     INT,
    
    in_date_dead                VARCHAR(10),
    in_dead_type_id             INT,

    in_comments                 VARCHAR(160)
    
)

BEGIN

/** 
 * Will update pig_prod_pig_dead entry.
 * @author Jack Wong
 * @since August 27, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD    INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_pig_dead_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_dead_account_id        INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_prod_pig_dead_account_id
FROM    pig_prod_pig_dead
WHERE   id = in_pig_prod_pig_dead_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_pig_dead_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD,
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



UPDATE pig_prod_pig_dead SET
    date_dead           = in_date_dead,
    dead_type_id        = in_dead_type_id,

    comments            = in_comments,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_pig_dead_id;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_pig_dead_id             AS pig_prod_pig_dead_id;
    


END $$

DELIMITER ;
