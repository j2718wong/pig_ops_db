DELIMITER $$

DROP PROCEDURE IF EXISTS account_access_code_update $$
CREATE PROCEDURE account_access_code_update(
    in_user_id              INT,
    
    in_access_code_id      INT,
    
    in_user_group_id        INT)  

BEGIN

/** 
 * Will update  account access code entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since March 18, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;



DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_access_code_account_id              INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  account_id
INTO    cur_access_code_account_id
FROM    account_access_code
WHERE   id = in_access_code_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_access_code_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT,
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



UPDATE account_access_code SET 
    user_group_id = in_user_group_id
WHERE id = in_access_code_id;



 

END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_access_code_id                   AS access_code_id;

END $$

DELIMITER ;
