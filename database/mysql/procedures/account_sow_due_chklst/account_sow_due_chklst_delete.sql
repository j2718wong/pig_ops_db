DELIMITER $$

DROP PROCEDURE IF EXISTS account_sow_due_chklst_delete $$
CREATE PROCEDURE account_sow_due_chklst_delete(
    in_user_id                  INT,
    
    in_acc_chklst_id            INT
)  

BEGIN

/** 
 * Will delete account_sow_due_chklst entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 20, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 8;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";

/* account_sow_due_chklst.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_CHECKLIST_IS_DELETED   INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_chklst_account_id                   INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_chklst_account_id
FROM    account_sow_due_chklst
WHERE   id = in_account_sow_due_chklst_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_chklst_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS,
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



UPDATE account_sow_due_chklst SET
    flag                = flag | FLAG_BIT_ACCOUNT_CHECKLIST_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_acc_chklst_id;


CALL account_sow_due_chklst_delete_loop(cur_user_account_id, in_acc_chklst_id);


UPDATE account SET 
    data_ver_num_sd_chklst = data_ver_num_sd_chklst + 1
WHERE id = cur_user_account_id;


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc;
    

END $$

DELIMITER ;
