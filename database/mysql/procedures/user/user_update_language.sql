DELIMITER $$

DROP PROCEDURE IF EXISTS user_update_language $$
CREATE PROCEDURE user_update_language(
    in_user_id                  INT,
    
    in_language                 VARCHAR(10)
    
)

BEGIN

/** 
 * Will update user language
 * @author Jack Wong
 * @since March 25, 2026
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;



/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;


DECLARE BUSINESS_OBJ_ID_USER                	INT             DEFAULT 1;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;




DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";

CALL basic_user_check(
    in_user_id, 
    0, 
    0, 
    
    BUSINESS_OBJ_ID_USER,
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



UPDATE user SET
    language_preference = in_language
    
WHERE id = in_user_id;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc;


END $$

DELIMITER ;
