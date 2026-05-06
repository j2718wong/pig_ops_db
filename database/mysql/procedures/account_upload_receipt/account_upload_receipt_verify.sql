DELIMITER $$

DROP PROCEDURE IF EXISTS account_upload_receipt_verify $$
CREATE PROCEDURE account_upload_receipt_verify(
    in_user_id              INT,
    
    in_account_receipt_id   INT,
    
    in_amount_verified      DECIMAL(8,2)
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


DECLARE BILL_STATUS_ID_ISSUED                   INT             DEFAULT 0;
DECLARE BILL_STATUS_ID_PENDING_PAYMENT_VERIFY   INT             DEFAULT 1;
DECLARE BILL_STATUS_ID_VERIFIED_PAID            INT             DEFAULT 2;
DECLARE BILL_STATUS_ID_PARTIALLY_PAID           INT             DEFAULT 3;


/** The receipt details was read either manually OR automated*/
DECLARE RECEIPT_STATUS_ID_READ                  INT             DEFAULT 1;


/** The payment amount verified in the payment channel is NOT same what is read from receipt*/
DECLARE RECEIPT_STATUS_ID_VERIFIED_MISMATCH     INT             DEFAULT 2;


/** The payment amount verified in the payment channel is same what is printed on receipt*/
DECLARE RECEIPT_STATUS_ID_VERIFIED_MATCHED      INT             DEFAULT 3;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_bill_id                     INT             DEFAULT 0;
DECLARE cur_receipt_amount                      DECIMAL(8,2)    DEFAULT NULL;
DECLARE cur_account_id                          INT             DEFAULT 0;
DECLARE cur_account_bill_total_amount_due       DECIMAL(8,2)    DEFAULT NULL;

DECLARE cur_receipt_status_id                   INT             DEFAULT 0;

DECLARE cur_total_amount_verified               DECIMAL(8,2)    DEFAULT NULL;

DECLARE cur_balance                             DECIMAL(8,2)    DEFAULT NULL;


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


SELECT  a.account_bill_id,
        a.amount_receipt,
        b.account_id,
        b.total_amount_due

INTO    cur_account_bill_id,
        cur_receipt_amount,
        cur_account_id,
        cur_account_bill_total_amount_due

FROM    account_upload_receipt a
LEFT OUTER JOIN account_bill b ON a.account_bill_id = b.id
WHERE   a.id = in_account_receipt_id;


IF cur_receipt_amount = in_amount_verified  THEN 
    SET cur_receipt_status_id = RECEIPT_STATUS_ID_VERIFIED_MATCHED;
ELSE
    SET cur_receipt_status_id = RECEIPT_STATUS_ID_VERIFIED_MISMATCH;
END IF;


UPDATE account_upload_receipt SET
    status_id                   = cur_receipt_status_id,
    amount_verified             = in_amount_verified,
    payment_verified_user_id    = in_user_id, 
    dt_payment_verified         = CURRENT_TIMESTAMP
WHERE id = in_account_receipt_id;


IF cur_receipt_status_id = RECEIPT_STATUS_ID_VERIFIED_MATCHED THEN 
    /* Sum up all verified payments of the account_bill*/
    SELECT  SUM(amount_verified)
    INTO    cur_total_amount_verified
    FROM    account_upload_receipt
    WHERE   account_bill_id = cur_account_bill_id;
    
    
    /* Need to know if the total payments were just a partial payment or complete 
    payment for the account_bill*/
    
    IF cur_total_amount_verified >= cur_account_bill_total_amount_due THEN 
        /* UPDATE account_bill. */
        
        UPDATE account_bill SET
            status_id               = BILL_STATUS_ID_VERIFIED_PAID,
        
            amount_paid             = cur_total_amount_verified,
            amount_balance          = 0,
            date_payment_verified   = CURRENT_DATE,
            dt_payment_verified     = CURRENT_TIMESTAMP
        WHERE id = cur_account_bill_id;
        
        
        /* UPDATE account */
        UPDATE account SET 
            current_bill_id         = 0, 
            num_bills_paid          = num_bills_paid + 1,
            data_ver_num_account    = data_ver_num_account + 1
        WHERE id = cur_account_id;
            
        
        IF cur_total_amount_verified > cur_account_bill_total_amount_due THEN
            /** TODO what will happen to this excess money?*/
            SET cur_count = 0;
        END IF;
    
    ELSE
        /* Calculate balance*/
        SET cur_balance = cur_account_bill_total_amount_due - cur_total_amount_verified;
        
        UPDATE account_bill SET
            status_id               = BILL_STATUS_ID_PARTIALLY_PAID,
            
            amount_paid             = cur_total_amount_verified,
            amount_balance          = cur_balance
        WHERE id = cur_account_bill_id;
        
        
    END IF;
    
ELSE
    /** TODO what to do for mismatch receipt amount and actual verified amount?*/
    SET cur_count = 0;


END IF;



END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_receipt_id               AS upload_receipt_id;

END $$

DELIMITER ;
