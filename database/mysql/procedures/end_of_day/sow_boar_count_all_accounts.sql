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


DECLARE LOV_ID_ACC_MAX_NUM_SOW_BOAR_FREE        INT             DEFAULT 2;
DECLARE LOV_ID_BILLING_NUM_DAYS_DUE_DATE        INT             DEFAULT 4;


DECLARE NUM_DAYS_NEXT_SOW_BOAR_COUNT            INT             DEFAULT 30;

DECLARE FLAG_BIT_ACCOUNT_IS_TEST_ACCOUNT        INT             DEFAULT 32;


DECLARE cur_max_sow_boar_free                   INT             DEFAULT 0;
DECLARE cur_billing_num_days_due_date           INT             DEFAULT 0;

DECLARE cur_account_id                          INT             DEFAULT 0;
DECLARE cur_account_current_bill_id             INT             DEFAULT 0;
DECLARE cur_account_country_id                  INT             DEFAULT 0;
DECLARE cur_account_currency                    VARCHAR(4)      DEFAULT NULL;


DECLARE cur_num_pig_count                       INT             DEFAULT 0;
DECLARE cur_num_billable_pigs                   INT             DEFAULT 0;

DECLARE cur_bill_count                          INT             DEFAULT 0;
DECLARE cur_obfuscated                          INT             DEFAULT 0;

DECLARE cur_date_prefix                         VARCHAR(6)      DEFAULT NULL;
DECLARE cur_checksum                            INT             DEFAULT 0;

DECLARE cur_bill_reference                      VARCHAR(50);

DECLARE DEFAULT_PRICE_PER_HEAD                  DECIMAL(6,1)    DEFAULT NULL;
DECLARE DEFAULT_CURRENCY_CODE                   VARCHAR(4)      DEFAULT NULL;

DECLARE cur_country_price_per_head              DECIMAL(6,1)    DEFAULT NULL;
DECLARE cur_country_currency_code               VARCHAR(4)      DEFAULT NULL;

DECLARE cur_bill_charge                         DECIMAL(8,2)    DEFAULT NULL;

DECLARE cur_account_bill_id                     INT             DEFAULT 0;



/* account.flag bits
bit 0: FLAG_BIT_ACCOUNT_ENABLE
bit 1: FLAG_BIT_FREE_TRIAL_STARTED
bit 2:
bit 3:  

bit 4: FLAG_BIT_ACCOUNT_IS_BILL_EXEMPTED
0 = not exempted has to pay bill
1 = exempted, no need to compute bill

bit 5: FLAG_BIT_ACCOUNT_IS_TEST_ACCOUNT


bit 15: COMPANY_OWNED ACCOUNT
*/


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account CURSOR FOR
    SELECT  a.id,
            a.current_bill_id,
            a.country_id,
            b.currency_code
    
    FROM    account a
    LEFT OUTER JOIN app_country b ON a.country_id = b.id
            
    WHERE   (a.flag & FLAG_BIT_ACCOUNT_IS_TEST_ACCOUNT) = 0 AND 
            a.date_next_sow_boar_count = CURRENT_DATE;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 



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


    
/* Read default price_per_head and currency first; this should be in USD;
This is for accounts outside PH, future expansion
*/
    
SELECT  currency_code,
        price_per_head
        
INTO    DEFAULT_PRICE_PER_HEAD,
        DEFAULT_CURRENCY_CODE

FROM    biz_pricing
WHERE   id = 1;   



SET cur_date_prefix = DATE_FORMAT(CURRENT_DATE, '%y%m%d');

    
SET l_last_row_fetched=0;
OPEN c_account;   
    

loop_here: LOOP
    FETCH c_account INTO 
        cur_account_id,
        cur_account_current_bill_id,
        cur_account_country_id,
        cur_account_currency;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;


    SET cur_num_pig_count = 0;

    /* Count sow, boar for each account; The account.last_sow_boar_count_id 
    should be updated after this procedure call.*/
    CALL sow_boar_count_per_account(cur_account_id, cur_num_pig_count);

    
    UPDATE account SET 
        date_next_sow_boar_count = CURRENT_DATE + INTERVAL NUM_DAYS_NEXT_SOW_BOAR_COUNT DAY
    WHERE id = cur_account_id;


    /* Get the price_per_head and currency code from account country;
    This is a Full table scan, with vew few rows.
    */
    SELECT  currency_code,
            price_per_head
            
    INTO    cur_country_price_per_head,
            cur_country_currency_code

    FROM    biz_pricing
    WHERE   country_id = cur_account_country_id
    LIMIT   1;   


    /* Set to default pricing if price per country cannot be found*/
    IF cur_country_price_per_head IS NULL THEN 
        SET cur_country_price_per_head  = DEFAULT_PRICE_PER_HEAD;
        SET cur_country_currency_code   = DEFAULT_CURRENCY_CODE;
    END IF;
    
    
    /* Create account_bill 
    Need to consider
    1.) What happens when previous bill was not yet paid?
    - should it create a new bill?
    
    2.) The current planned process is, 
    - generate bill
    - send to account admins
    - wait for payment verification
    - due date = date bill_generated + 15 days
    - if bill is not settled after due date, account  is locked, only the payment
        verification page is viewable in UI
    
    - if bill is paid after account locked up, users can acceess again the app.
    
    but waht happens to sow_boar_head counts after bill was issued and bill was settled?
        
    
    */
   


    /* Check first the status of the old bill; When account is billed for the  
    first time, account.current_bill_id is 0; 
    When the bill is paid, account.current_bill_id is 0;*/
    IF cur_account_current_bill_id = 0 THEN 
        
        /* Compute number of billable sow_boar*/
        IF cur_num_pig_count > cur_max_sow_boar_free THEN 
            SET cur_num_billable_pigs = cur_num_pig_count - cur_max_sow_boar_free;
        ELSE 
            SET cur_num_billable_pigs = 0;
        END IF;
        
        
        /* Compute bill charge.*/
        SET cur_bill_charge = cur_num_billable_pigs * cur_country_price_per_head;
        
        
        /* Subtract any discount, referral reward etc later*/
        
        
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
        
        /* Create account_bill entry*/
        INSERT INTO account_bill (
            account_id,
            bill_reference,
            date_bill_end,
            date_issue,
            date_due,
            
            currency_code,
            amount
        ) VALUES(
            cur_account_id,
            cur_bill_reference, 
            CURRENT_DATE,
            CURRENT_DATE,
            CURRENT_DATE + INTERVAL cur_billing_num_days_due_date DAY,
            
            cur_country_currency_code,
            cur_bill_charge
        );
        SELECT LAST_INSERT_ID() INTO cur_account_bill_id;
        
        UPDATE account SET 
            current_bill_id = cur_account_bill_id
        WHERE id = cur_account_id;
        
        
    END IF;
    
    
    

END LOOP loop_here;
 
CLOSE c_account;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
