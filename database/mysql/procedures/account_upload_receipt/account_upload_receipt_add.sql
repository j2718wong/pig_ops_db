DELIMITER $$

DROP PROCEDURE IF EXISTS account_upload_receipt_add $$
CREATE PROCEDURE account_upload_receipt_add(
    in_user_id              INT,
    in_account_bill_id      INT,
    
    in_file_path            VARCHAR(255)
)  

BEGIN

/** 
 * Will add account_upload_receipt entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 5, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;



DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE BILL_STATUS_ID_PENDING_PAYMENT_VERIFY   INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_user_group_id               INT             DEFAULT 0;

DECLARE cur_account_upload_receipt_id              INT             DEFAULT 0;



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



INSERT INTO account_upload_receipt(
    account_id,
    account_bill_id,
    file_path,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_account_bill_id,
    in_file_path,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_upload_receipt_id;


UPDATE account_bill SET 
    status_id           = BILL_STATUS_ID_PENDING_PAYMENT_VERIFY,
    upload_receipt_id   = cur_account_upload_receipt_id,
    date_upload_payment_receipt = CURRENT_DATE
WHERE id = in_account_bill_id;
 

END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_upload_receipt_id       AS upload_receipt_id;

END $$

DELIMITER ;
