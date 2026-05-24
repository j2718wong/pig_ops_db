DELIMITER $$

DROP PROCEDURE IF EXISTS account_bill_check_overdue $$
CREATE PROCEDURE account_bill_check_overdue()  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 24, 2026
 *
 */

DECLARE BG_PROCESS_ACCOUNT_BILL_CHECK_OVERDUE   INT             DEFAULT 28;

DECLARE BG_PROCESS_COMPLETED                    INT             DEFAULT 100;   




/* account_bill.status id possible values;
Note: When account_bill.status id = ACC_BILL_STATUS_OVERDUE,
account users cannot access their data.
*/
DECLARE ACC_BILL_STATUS_NEW                     INT             DEFAULT 0;
DECLARE ACC_BILL_STATUS_OVERDUE                 INT             DEFAULT 1;
DECLARE ACC_BILL_STATUS_PAID                    INT             DEFAULT 2;



/* account_bill flag bits

bit 0: FLAG_BIT_ACC_MADE_A_PARTIAL_PAYMENT          INT             DEFAULT 1;
0 = 
1 = account has made a partial payment



bit 1: FLAG_BIT_ACC_PARTIAL_PAYMENT_OK              INT             DEFAULT 2;
0 = the partial payment is not enough to not to flag ACC_BILL_STATUS_OVERDUE;
    In this case the account will still be locked;

1 = the partial payment is enough, the remaining balance will be carried over
    the next billing cycle.



*/

DECLARE NUM_DAYS_NEXT_SOW_BOAR_COUNT            INT             DEFAULT 30;



DECLARE t_init                                  BIGINT          DEFAULT 0;
DECLARE t_final                                 BIGINT          DEFAULT 0;
DECLARE t_delta                                 INT;

DECLARE cur_business_date                       DATE;


DECLARE cur_overdue_before                      INT             DEFAULT 0;
DECLARE cur_overdue_after                       INT             DEFAULT 0;


DECLARE cur_record_processed                    INT             DEFAULT 0;

DECLARE cur_bg_process_run_id                   INT             DEFAULT 0;






SET t_init = UNIX_TIMESTAMP();

SET cur_business_date = CURRENT_DATE;



/** Insert bg_process_run record*/

INSERT INTO bg_process_run(
    bg_process_id,     
    business_date   
) VALUES (
    BG_PROCESS_ACCOUNT_BILL_CHECK_OVERDUE,
    cur_business_date
);
SELECT LAST_INSERT_ID() INTO cur_bg_process_run_id;


/* Count existing overdue account_bill*/
SELECT  COUNT(*) 
INTO    cur_overdue_before
FROM    account a
LEFT OUTER JOIN account_bill b ON a.cur_bill_id = b.id
WHERE   a.cur_bill_id > 0 AND b.status_id = ACC_BILL_STATUS_OVERDUE;



/* Should filter by account.current_bill_id so that less data to read;*/
UPDATE  account a, account_bill b SET
    b.status_id = ACC_BILL_STATUS_OVERDUE
WHERE a.current_bill_id > 0 AND  (a.current_bill_id = b.id)
AND b.status_id = ACC_BILL_STATUS_NEW 
AND b.date_due < CURRENT_DATE 
AND b.flag = 0;  /* Has not made any partial payment at ALL*/


/* Should filter by account.current_bill_id so that less data to read;*/
/* Has made partial payment but not enough not to trigger ACC_BILL_STATUS_OVERDUE */
UPDATE  account a, account_bill b SET
    b.status_id = ACC_BILL_STATUS_OVERDUE
WHERE a.current_bill_id > 0 AND  (a.current_bill_id = b.id)
AND b.status_id = ACC_BILL_STATUS_NEW 
AND b.date_due < CURRENT_DATE 
AND (b.flag & 3)= 1;  



/* Count current overdue account_bill*/
SELECT  COUNT(*) 
INTO    cur_overdue_after
FROM    account a
LEFT OUTER JOIN account_bill b ON a.cur_bill_id = b.id
WHERE   a.cur_bill_id > 0 AND b.status_id = ACC_BILL_STATUS_OVERDUE;



SET cur_record_processed = cur_overdue_after - cur_overdue_before;

SET t_final = UNIX_TIMESTAMP();

SET t_delta = t_final - t_init;


/** UPDATE bg_process_run record*/

UPDATE bg_process_run SET
    duration_secs       = t_delta,     
    proc_status         = BG_PROCESS_COMPLETED,       
    records_processed   = cur_record_processed 
WHERE id = cur_bg_process_run_id;


SELECT  cur_bg_process_run_id   AS bg_process_run_id,
        cur_business_date       AS business_date,
        cur_record_processed    AS record_processed;


END $$

DELIMITER ;
