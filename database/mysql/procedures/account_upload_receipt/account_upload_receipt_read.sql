DELIMITER $$

DROP PROCEDURE IF EXISTS account_upload_receipt_read $$
CREATE PROCEDURE account_upload_receipt_read(
    in_user_id              INT,
    
    in_account_receipt_id   INT,
    
    is_read_status_id       INT,
    
    in_payment_channel_id   INT,
    in_amount_receipt       DECIMAL(8,2),    
    in_payment_reference    VARCHAR(32), 
    in_dt_receipt           VARCHAR(20)
    
)  

BEGIN

/** 
 * Will update account_upload_receipt data entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 6, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_ACCOUNT_BILL_ALREADY_PAID       INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/** The receipt details was read either manually OR automated*/
DECLARE RECEIPT_STATUS_ID_READ                  INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;




DECLARE cur_count                               INT             DEFAULT 0;


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



UPDATE account_upload_receipt SET 
    status_id           = is_read_status_id,

    payment_channel_id  = in_payment_channel_id,
    amount_receipt      = in_amount_receipt,    
    payment_reference   = in_payment_reference, 
    dt_receipt          = in_dt_receipt,
    
    data_entry_user_id  = in_user_id,
    dt_input_data_entry = CURRENT_TIMESTAMP        
    
WHERE id = in_account_receipt_id; 


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_receipt_id               AS upload_receipt_id;

END $$

DELIMITER ;
