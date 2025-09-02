DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_update $$
CREATE PROCEDURE account_pig_ops_update(
    in_user_id                  INT,
    
    in_account_pig_ops_id       INT,
    in_num_days_since           INT,
    
    in_name                     VARCHAR(50),
    in_description              VARCHAR(160)
    
)

BEGIN

/** 
 * Will update account_pig_ops entry.
 * @author Jack Wong
 * @since August 10, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS   INT             DEFAULT 10;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

        
DECLARE cur_account_pig_ops_account_id          INT             DEFAULT 0;
DECLARE cur_account_pig_ops_flag                INT             DEFAULT 0;
DECLARE cur_account_pig_ops_name                VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_account_pig_ops_account_id
FROM    account_pig_ops
WHERE   id = in_account_pig_ops_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_pig_ops_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS,
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



UPDATE account_pig_ops SET
    num_days_since      = in_num_days_since,
    
    name                = in_name,
    description         = in_description,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_account_pig_ops_id;

END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_ops_flag,
    cur_account_pig_ops_name
FROM account_pig_ops
WHERE id = in_account_pig_ops_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_pig_ops_id               AS account_pig_ops_id,
    cur_account_pig_ops_flag            AS account_pig_ops_flag,
    cur_account_pig_ops_name            AS account_pig_ops_name;
    


END $$

DELIMITER ;
