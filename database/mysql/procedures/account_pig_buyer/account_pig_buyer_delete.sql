DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_buyer_delete $$
CREATE PROCEDURE account_pig_buyer_delete(
    in_user_id                  INT,
    
    in_account_pig_buyer_id     INT
)  

BEGIN

/** 
 * Will delete account_pig_buyer entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER      	INT             DEFAULT 12;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";

/* account_pig_buyer.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED   INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_pig_buyer_account_id        INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_flag              INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_name              VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_account_pig_buyer_account_id
FROM    account_pig_buyer
WHERE   id = in_account_pig_buyer_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_pig_buyer_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER,
    FLAG_BIT_OPERATION_DELETE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



UPDATE account_pig_buyer SET
    flag                = flag | FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_account_pig_buyer_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_buyer_flag,
    cur_account_pig_buyer_name
FROM account_pig_buyer
WHERE id = in_account_pig_buyer_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_pig_buyer_id             AS account_pig_buyer_id,
    cur_account_pig_buyer_flag          AS account_pig_buyer_flag,
    cur_account_pig_buyer_name          AS account_pig_buyer_name;
    

END $$

DELIMITER ;
