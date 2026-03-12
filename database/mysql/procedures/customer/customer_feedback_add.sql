DELIMITER $$

DROP PROCEDURE IF EXISTS customer_feedback_add $$
CREATE PROCEDURE customer_feedback_add(
    in_user_id              INT,
    
    in_notes                VARCHAR(500)
)  

BEGIN

/** 
 * Will create customer_feedback entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since March 12, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_customer_feedback_id                INT             DEFAULT 0;


DECLARE cur_flag                                INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";




CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
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



INSERT INTO customer_feedback (
    account_id,
    user_id,
    
    notes
    
) VALUES (
    cur_user_account_id,
    in_user_id,
    in_notes
);

SELECT LAST_INSERT_ID() INTO cur_customer_feedback_id;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_customer_feedback_id            AS customer_feedback_id;
    

END $$

DELIMITER ;
