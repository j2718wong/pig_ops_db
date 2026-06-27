DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_count_all_accounts $$
CREATE PROCEDURE sow_boar_count_all_accounts()  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 2, 2026
 *
 */

DECLARE BG_PROCESS_ID_COUNT_BILLABLE_PIGS_ALL_ACCOUNTS     INT     DEFAULT 21;

DECLARE BG_PROCESS_COMPLETED                    INT             DEFAULT 100;   

DECLARE LOV_ID_ACC_MAX_NUM_SOW_BOAR_FREE        INT             DEFAULT 2;
DECLARE LOV_ID_BILLING_NUM_DAYS_DUE_DATE        INT             DEFAULT 4;
DECLARE LOV_ID_LAST_BG_PROCESS_RUN_ID_EOD_SOW_BOAR_COUNT INT    DEFAULT 5;
DECLARE LOV_ID_GLOBAL_CHARGING_METHOD           INT             DEFAULT 6;


/* account_bill.status id possible values;
Note: When account_bill.status id = ACC_BILL_STATUS_OVERDUE,
account users cannot access their data.
*/
DECLARE ACC_BILL_STATUS_NEW                     INT             DEFAULT 0;
DECLARE ACC_BILL_STATUS_OVERDUE                 INT             DEFAULT 1;
DECLARE ACC_BILL_STATUS_PAID                    INT             DEFAULT 2;


/* account.flag bits
bit 0: FLAG_BIT_ACCOUNT_ENABLE
bit 1: FLAG_BIT_FREE_TRIAL_STARTED
bit 2:
bit 3:  

bit 4: FLAG_BIT_ACCOUNT_IS_BILL_EXEMPTED
0 = not exempted has to pay bill
1 = exempted, no need to compute bill

bit 5: FLAG_BIT_ACCOUNT_IS_TEST_ACCOUNT
bit 6: COMPANY_OWNED ACCOUNT

*/

DECLARE FLAG_BIT_ACCOUNT_IS_BILL_EXEMPTED       INT             DEFAULT 16;
DECLARE FLAG_BIT_ACCOUNT_IS_TEST_ACCOUNT        INT             DEFAULT 32;
DECLARE FLAG_BIT_ACCOUNT_IS_COMPANY_OWNED       INT             DEFAULT 64;




/* app_country.flag bits
bit 0: FLAG_BIT_COUNTRY_ENABLED
bit 1: 
bit 2:
bit 3:

bit 4: FLAG_BIT_TAXES_ARE_EXCLUSIVE 
0 = taxes are inclusive in sale amount
1 = taxes are exclusive from sale amount


*/

DECLARE FLAG_BIT_TAXES_ARE_EXCLUSIVE                INT             DEFAULT 16;


/*
2026-05-24 Notes:
1.) There is no way to control how much the account will pay on a bill since
the actual payment is only known after payment verification in payment channels
such as bank account or digital wallets. Credit card payments are not yet supported
and impractical(for Philippine market) as of this writing.

2.) So it is assumed that the account can underpay or overpay the bill amount.

3.) If the bill is partially paid, there is a certain threshold, in proportion 
to the billed amount that the partial payment is OK and the remainder will be 
carried over the next billing cycle.

This should SET

account_bill.flag.FLAG_BIT_ACC_MADE_A_PARTIAL_PAYMENT = 1

and if payment is OK

account_bill.flag.FLAG_BIT_ACC_PARTIAL_PAYMENT_OK = 1

(Note: This partial payment system is also used by many electric distribution
companies in PH, where accounts can pay minimum payment; these companies
can charge surcharges too on the balance).


4.) When a new bill is issued:

- the account.cur_bill_id should be filled;
- The "New Bill Available" indicator should shown in APP UI;
- email should be sent to account admins

5.) If the bill is fully paid, the account.cur_bill_id should be SET zero 
and the paid bill should be referenced in account.previous_bill_id; 
There is a bill history anyway for the account.
The "New Bill Available" indicator should be hidden in APP UI;

6.) If the bill is partially paid,

if account_bill.flag.FLAG_BIT_ACC_PARTIAL_PAYMENT_OK = 0, 
- The "New Bill Available" indicator should still be visible in the APP UI
- email the account admins for the partial payment

if account_bill.flag.FLAG_BIT_ACC_PARTIAL_PAYMENT_OK = 1, 
    the account.cur_bill_id should be SET zero 
    and the paid bill should be referenced in account.previous_bill_id; 
    There is a bill history anyway for the account.
    The "New Bill Available" indicator should be hidden in APP UI;

    - should email the admins that the balance will be carried over next 
    billing cycle. 


2026-06-27 Notes:
1.) There is now a system wide option to charge accounts flat rate on per farm
basis instead of per head breeding pigs;

2.) This is controlled by a database flag 
a01_list_of_values.id = 6; GLOBAL_CHARGING_METHOD

0 or None = per head of breeding pigs (sow boar gilt)
1 = per farm charging


*/



/* account_bill flag bits

bit 0: FLAG_BIT_ACC_MADE_A_PARTIAL_PAYMENT          INT             DEFAULT 1;
0 = 
1 = account has made a partial payment



bit 1: FLAG_BIT_ACC_PARTIAL_PAYMENT_OK              INT             DEFAULT 2;
0 = the partial payment is not enough to not to flag ACC_BILL_STATUS_OVERDUE;
    In this case the account will still be locked;

1 = the partial payment is enough, the remaining balance will be carried over
    the next billing cycle.



bit 1: FLAG_BIT_ACC_CHARGING_METHOD                 INT             DEFAULT 16;
0 = per head charging method

1 = per farm charging method

*/

DECLARE FLAG_BIT_ACC_CHARGING_METHOD            INT             DEFAULT 16;



DECLARE NUM_DAYS_NEXT_SOW_BOAR_COUNT            INT             DEFAULT 30;



DECLARE t_init                                  BIGINT          DEFAULT 0;
DECLARE t_final                                 BIGINT          DEFAULT 0;
DECLARE t_delta                                 INT;

DECLARE cur_business_date                       DATE;

DECLARE cur_max_sow_boar_free                   INT             DEFAULT 0;
DECLARE cur_billing_num_days_due_date           INT             DEFAULT 0;

DECLARE cur_account_id                          INT             DEFAULT 0;
DECLARE cur_account_previous_bill_id            INT             DEFAULT 0;
DECLARE cur_account_current_bill_id             INT             DEFAULT 0;
DECLARE cur_account_country_id                  INT             DEFAULT 0;

DECLARE cur_charging_method                     INT             DEFAULT 0;

DECLARE cur_num_pig_farm                        INT             DEFAULT 0;

DECLARE cur_country_flag                        INT             DEFAULT 0;
DECLARE cur_country_currency                    VARCHAR(4)      DEFAULT NULL;
DECLARE cur_country_tax_rate                    DECIMAL(4,2)    DEFAULT NULL;

DECLARE cur_num_pig_count                       INT             DEFAULT 0;
DECLARE cur_sow_boar_count_id                   INT             DEFAULT 0;    
DECLARE cur_num_billable_pigs                   INT             DEFAULT 0;

DECLARE cur_bill_count                          INT             DEFAULT 0;
DECLARE cur_obfuscated                          INT             DEFAULT 0;

DECLARE cur_date_prefix                         VARCHAR(6)      DEFAULT NULL;
DECLARE cur_checksum                            INT             DEFAULT 0;

DECLARE cur_bill_flag                           INT             DEFAULT 0;
DECLARE cur_bill_reference                      VARCHAR(50);

DECLARE DEFAULT_PRICE_PER_HEAD                  DECIMAL(6,1)    DEFAULT NULL;
DECLARE DEFAULT_PRICE_PER_FARM                  DECIMAL(6,1)    DEFAULT NULL;
DECLARE DEFAULT_CURRENCY_CODE                   VARCHAR(4)      DEFAULT NULL;

DECLARE cur_country_price_per_head              DECIMAL(6,1)    DEFAULT NULL;
DECLARE cur_country_price_per_farm              DECIMAL(6,1)    DEFAULT NULL;
DECLARE cur_country_currency_code               VARCHAR(4)      DEFAULT NULL;


DECLARE cur_bill_charge                         DECIMAL(8,2)    DEFAULT NULL;
DECLARE cur_deduction                           DECIMAL(8,2)    DEFAULT NULL;
DECLARE cur_taxable_amount                      DECIMAL(8,2)    DEFAULT NULL;
DECLARE cur_taxes                               DECIMAL(8,2)    DEFAULT NULL;

DECLARE cur_prev_amount_balance                 DECIMAL(8,2)    DEFAULT NULL;

DECLARE cur_total_amount_due                    DECIMAL(8,2)    DEFAULT NULL;



DECLARE cur_account_bill_id                     INT             DEFAULT 0;

DECLARE cur_record_processed                    INT             DEFAULT 0;

DECLARE cur_bg_process_run_id                   INT             DEFAULT 0;







DECLARE l_last_row_fetched TINYINT;
DECLARE c_account CURSOR FOR
    SELECT  a.id,
            a.previous_bill_id,
            a.current_bill_id,
            a.country_id,
            
            b.flag,
            b.currency_code,
            b.tax_rate
    
    FROM    account a
    LEFT OUTER JOIN app_country b ON a.country_id = b.id
            
    WHERE   (a.flag & 112) = 0 AND 
            a.date_next_sow_boar_count = CURRENT_DATE;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


SET t_init = UNIX_TIMESTAMP();

SET cur_business_date = CURRENT_DATE;



/** Insert bg_process_run record*/

INSERT INTO bg_process_run(
    bg_process_id,     
    business_date   
) VALUES (
    BG_PROCESS_ID_COUNT_BILLABLE_PIGS_ALL_ACCOUNTS,
    cur_business_date
);
SELECT LAST_INSERT_ID() INTO cur_bg_process_run_id;



/* Read ACC_MAX_NUM_SOW_BOAR_FREE.*/
SELECT  val_int
INTO    cur_max_sow_boar_free
FROM    a01_list_of_values
WHERE   id = LOV_ID_ACC_MAX_NUM_SOW_BOAR_FREE;



/* Read BILLING_NUM_DAYS_DUE_DATE. */
SELECT  val_int
INTO    cur_billing_num_days_due_date
FROM    a01_list_of_values
WHERE   id = LOV_ID_BILLING_NUM_DAYS_DUE_DATE;


/* Read GLOBAL_CHARGING_METHOD. */
SELECT  val_int
INTO    cur_charging_method
FROM    a01_list_of_values
WHERE   id = LOV_ID_GLOBAL_CHARGING_METHOD;




    
/* Read default price_per_head and currency first; this should be in USD;
This is for accounts outside PH, future expansion
*/
    
SELECT  currency_code,
        price_per_head,
        price_per_farm
        
INTO    DEFAULT_CURRENCY_CODE,
        DEFAULT_PRICE_PER_HEAD,
        DEFAULT_PRICE_PER_FARM
        

FROM    biz_pricing
WHERE   id = 1;   



SET cur_date_prefix = DATE_FORMAT(cur_business_date, '%y%m%d');

    
SET l_last_row_fetched=0;
OPEN c_account;   
    

loop_here: LOOP
    FETCH c_account INTO 
        cur_account_id,
        cur_account_previous_bill_id,
        cur_account_current_bill_id,
        cur_account_country_id,
        
        cur_country_flag,
        cur_country_currency,
        cur_country_tax_rate;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;


    SET cur_num_pig_count       = 0;
    SET cur_sow_boar_count_id   = 0;

    /* Count sow, boar for each account; The account.last_sow_boar_count_id 
    should be updated after this procedure call.*/
    CALL sow_boar_count_per_account(cur_account_id, cur_num_pig_count, 
            cur_sow_boar_count_id);

    
    UPDATE account SET 
        date_next_sow_boar_count = cur_business_date + INTERVAL NUM_DAYS_NEXT_SOW_BOAR_COUNT DAY
    WHERE id = cur_account_id;


    SET cur_country_currency_code   = NULL;
    SET cur_country_price_per_head  = NULL;
    SET cur_country_price_per_farm  = NULL;


    /* Get the price_per_head, price_per_farm and currency code from account country;
    This is a Full table scan, with very few rows.
    */
    SELECT  currency_code,
            price_per_head,
            price_per_farm
            
    INTO    cur_country_currency_code,
            cur_country_price_per_head,
            cur_country_price_per_farm

    FROM    biz_pricing
    WHERE   country_id = cur_account_country_id
    LIMIT   1;   


    /* Set to default pricing if price per country cannot be found*/
    IF cur_country_price_per_head IS NULL THEN 
        SET cur_country_currency_code   = DEFAULT_CURRENCY_CODE;
        SET cur_country_price_per_head  = DEFAULT_PRICE_PER_HEAD;
        SET cur_country_price_per_farm  = DEFAULT_PRICE_PER_FARM;
        
    END IF;
  
  
    SET cur_bill_flag   = 0;
    

    /* Check first the status of the old bill; When account is billed for the  
    first time, account.current_bill_id is 0; 
    When the bill is paid, account.current_bill_id is 0;
    
    
    To simplify billing logic, if the account has still a not paid outstanding 
    bill, no new bill will be created.
    */
    IF cur_account_current_bill_id = 0 THEN 
        
        /* Compute number of billable sow_boar*/
        IF cur_num_pig_count > cur_max_sow_boar_free THEN 
            SET cur_num_billable_pigs = cur_num_pig_count - cur_max_sow_boar_free;
        ELSE 
            SET cur_num_billable_pigs = 0;
        END IF;
        
        
        IF cur_charging_method > 0 THEN 
            /* Per pig farm*/
            
            SET cur_num_pig_farm = 0;
            
            SELECT  COUNT(*) 
            INTO    cur_num_pig_farm
            FROM    pig_farm 
            WHERE   account_id = cur_account_id;
            
            SET cur_bill_charge = cur_num_pig_farm * cur_country_price_per_farm;
            
            SET cur_bill_flag   = FLAG_BIT_ACC_CHARGING_METHOD;
            
        ELSE
            /* Per head of breeding pigs*/
            /* Compute bill charge.*/
            SET cur_bill_charge = cur_num_billable_pigs * cur_country_price_per_head;
            
            
            /* Subtract any discount, referral reward etc later*/
        END IF;
        
        
        /* Compute taxes, taxable amount and total_amount_due. */
        IF cur_country_flag & FLAG_BIT_TAXES_ARE_EXCLUSIVE = 0 THEN 
            SET cur_taxes            = cur_bill_charge * cur_country_tax_rate / 100;
            SET cur_taxable_amount   = cur_bill_charge - cur_taxes; 
            SET cur_total_amount_due = cur_bill_charge;
        ELSE
            SET cur_taxes            = cur_bill_charge * cur_country_tax_rate / 100;
            SET cur_taxable_amount   = cur_bill_charge; 
            SET cur_total_amount_due = cur_bill_charge + cur_taxes;
        END IF;
        
        
        SET cur_bill_count = cur_bill_count + 1; 
        
        -- Obfuscate: 4-digit number between 1000-9999
        SET cur_obfuscated = ((cur_bill_count * 7) + 123) % 9000 + 1000;
        
        
        -- Calculate checksum (sum of all digits mod 9, 1-9 range)
        SET cur_checksum = (
            SELECT (
                (SUBSTRING(cur_date_prefix, 1, 1) + SUBSTRING(cur_date_prefix, 2, 1) +
                 SUBSTRING(cur_date_prefix, 3, 1) + SUBSTRING(cur_date_prefix, 4, 1) +
                 SUBSTRING(cur_date_prefix, 5, 1) + SUBSTRING(cur_date_prefix, 6, 1) +
                 SUBSTRING(cur_obfuscated, 1, 1) + SUBSTRING(cur_obfuscated, 2, 1) +
                 SUBSTRING(cur_obfuscated, 3, 1) + SUBSTRING(cur_obfuscated, 4, 1)
                ) % 9
            ) + 1
        );
        
        SET cur_bill_reference = CONCAT(cur_date_prefix, '-', cur_obfuscated, '-', cur_checksum);
        
        SET cur_prev_amount_balance = 0;
        
        /* Check if there was a previous bill balance.*/
        IF cur_account_previous_bill_id > 0 THEN 
            SELECT  amount_balance 
            INTO    cur_prev_amount_balance
            FROM    account_bill
            WHERE   id = cur_account_previous_bill_id;
            
            
            /** If there  is any previous balance, it should be added to total amount*/
            IF cur_prev_amount_balance >  0 THEN
                SET cur_total_amount_due = cur_total_amount_due + cur_prev_amount_balance;
            END IF;
            
        END IF;
        
        
        
        /* Create account_bill entry; the account_bill.status_id is default 0;*/
        INSERT INTO account_bill (
            bg_process_run_id,
        
            account_id,
            bill_reference,
            date_bill_end,
            date_issue,
            date_due,
            
            country_id,
            tax_rate,
            
            num_sow_boar_billed,
            sow_boar_head_count_id,
            
            prev_amount_balance,
            
            currency_code,
            charge_per_pig,
            amount,
            taxable_amount,
            taxes,
            total_amount_due,
            
            flag
        ) VALUES(
            cur_bg_process_run_id,
        
            cur_account_id,
            cur_bill_reference, 
            cur_business_date,
            cur_business_date,
            cur_business_date + INTERVAL cur_billing_num_days_due_date DAY,
            
            cur_account_country_id,
            cur_country_tax_rate,
            
            cur_num_billable_pigs,
            cur_sow_boar_count_id,
            
            cur_prev_amount_balance,
            
            cur_country_currency_code,
            cur_country_price_per_head,
            cur_bill_charge,
            cur_taxable_amount,
            cur_taxes,
            cur_total_amount_due,
            
            cur_bill_flag
        );
        SELECT LAST_INSERT_ID() INTO cur_account_bill_id;
        
        UPDATE account SET 
            current_bill_id = cur_account_bill_id
        WHERE id = cur_account_id;
        
        SET cur_record_processed = cur_record_processed + 1;
        
    END IF;
    
    
    

END LOOP loop_here;
 
CLOSE c_account;
SET l_last_row_fetched=0;   


SET t_final = UNIX_TIMESTAMP();

SET t_delta = t_final - t_init;


/** Record the last cur_bg_process_run_id in a01_list_of_values*/
UPDATE a01_list_of_values SET
    val_int     = cur_bg_process_run_id,
    val_str     = DATE_FORMAT(cur_business_date, '%Y-%m-%d')
WHERE id = LOV_ID_LAST_BG_PROCESS_RUN_ID_EOD_SOW_BOAR_COUNT;


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
