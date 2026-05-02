DELIMITER $$

DROP PROCEDURE IF EXISTS account_calc_free_trial_start $$
CREATE PROCEDURE account_calc_free_trial_start(
    in_account_id           INT
   
)  

BEGIN

/** 
 * Will add sow_boar entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 1, 2026
 *
 */

/* account.flag bits
bit 0: FLAG_BIT_ACCOUNT_ENABLE
bit 1: FLAG_BIT_FREE_TRIAL_STARTED
bit 2:
bit 3:  

bit 4:  FLAG_BIT_ACCOUNT_IS_BILL_EXEMPTED
0 = not exempted has to pay bill
1 = exempted, no need to compute bill



bit 16: COMPANY_OWNED ACCOUNT

*/

DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_FREE_TRIAL_STARTED             INT             DEFAULT 2;
    

/* account_referral.flag bits
bit 0: FLAG_BIT_REFERRED_ACCOUNT_ACTIVE
*/




DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";






/*
2026-05-01 Notes:
1.) The account.date_trial_start is redefined when these two conditions are meet

a.) the number of sow/boar/gilt >= MIN_NUMBER_TRIAL_START_SOW_BOAR of the account
b.) the number of production entries >= MIN_NUMBER_TRIAL_START_PIG_PROD of the account

This is to give flexibility to adjust these minimum threshold

2.) This is not anymore the date of account registration to the give the user
    more time to evaluate the application.  

3.) The account.date_trial_end will also be recomputed.

4.) Will also check if account used a account_referral; 
    The account_referral.business_date_active will also be updated, as this will
    be used for calculating rewards for the account who give the referral_code.
*/

SET cur_count = 0;

SELECT  COUNT(*)
INTO    cur_count
FROM    sow_boar
WHERE   account_id = cur_user_account_id;

IF cur_count = 0 THEN 
    SELECT  account_referral_id
    INTO    cur_account_referral_id
    FROM    account
    WHERE   id = cur_user_account_id;
    
    
    IF cur_account_referral_id > 0 THEN 
        UPDATE account_referral SET 
            flag = flag | FLAG_BIT_REFERRED_ACCOUNT_ACTIVE,
            business_date_active = CURRENT_DATE
        WHERE id = account_referral_id;
    END IF;


    /*ACCOUNT_NUMDAYS_FREE_TRIAL*/
    SELECT  val_int
    INTO    cur_temp
    FROM    a01_list_of_values
    WHERE   id = 1;  
    
    
    UPDATE account SET 
        date_trial_start    = CURRENT_DATE,
        date_trial_end      = CURRENT_DATE + INTERVAL cur_temp DAY,
        flag                = flag | FLAG_BIT_FREE_TRIAL_STARTED
    WHERE id = cur_user_account_id;
    
END IF;





END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_sow_boar_id                     AS sow_boar_id,
    cur_pig_farm_last_sow_id            AS farm_sow_id,
    cur_pig_farm_last_boar_id           AS farm_boar_id;
    

END $$

DELIMITER ;
