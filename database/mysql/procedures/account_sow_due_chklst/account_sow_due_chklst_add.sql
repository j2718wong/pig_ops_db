DELIMITER $$

DROP PROCEDURE IF EXISTS account_sow_due_chklst_add $$
CREATE PROCEDURE account_sow_due_chklst_add(
    in_user_id              INT,
    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will add account_sow_due_chklst entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 18, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;




DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 8;




DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_chklst_id                INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";




CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, 
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS, /* TODO */
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



INSERT INTO account_sow_due_chklst(
    account_id,
    
    order_num,
    name,
    added_by_user_id

) VALUES (
    cur_user_account_id,
    
    in_order_num,
    in_name,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_chklst_id;

CALL account_sow_due_chklst_add_loop(cur_user_account_id, cur_account_chklst_id);


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_chklst_id               AS account_chklst_id;

END $$

DELIMITER ;
