DELIMITER $$

DROP PROCEDURE IF EXISTS account_access_code_add $$
CREATE PROCEDURE account_access_code_add(
    in_user_id              INT,
    
    in_user_group_num       INT)  

BEGIN

/** 
 * Will add account access code entry.
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


DECLARE cur_account_user_group_id               INT             DEFAULT 0;

DECLARE cur_account_access_code_id              INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_ACCOUNT,
    FLAG_BIT_OPERATION_ADD,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


SELECT  id
INTO    cur_account_user_group_id
FROM    user_group
WHERE   account_id = cur_user_account_id AND  group_num = in_user_group_num;


INSERT INTO account_access_code(
    account_id,
    issued_by_user_id,
    user_group_id
) VALUES (
    cur_user_account_id,
    in_user_id,
    cur_account_user_group_id
);

SELECT LAST_INSERT_ID() INTO cur_account_access_code_id;



 

END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_access_code_id          AS access_code_id,
    cur_user_account_id                 AS user_account_id, 
    cur_user_group_id                   AS user_group_id;

END $$

DELIMITER ;
