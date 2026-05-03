DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_add $$
CREATE PROCEDURE sow_boar_add(
    in_user_id              INT,
    
    in_pig_farm_id          INT,
    in_line_id              INT,
    in_sow_status_id        INT,
    
    in_sex                  CHAR(1),
    in_num_nipples          INT,
    in_is_external          INT,
    in_is_production_ready  INT,
    
    in_parent_sow_id        INT,
    in_parent_boar_id       INT,
    
    in_number               VARCHAR(10),
    in_name                 VARCHAR(20),
    in_date_of_birth        VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will add sow_boar entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;


DECLARE LOV_ID_ACCOUNT_NUMDAYS_FREE_TRIAL       INT             DEFAULT 1;
DECLARE LOV_ID_ACC_MAX_NUM_SOW_BOAR_FREE        INT             DEFAULT 2;
DECLARE LOV_ID_ACC_MIN_NUM_SOW_BOAR_REFERRAL_ACTIVE INT         DEFAULT 3;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


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
DECLARE FLAG_BIT_REFERRED_ACCOUNT_ACTIVE        INT             DEFAULT 1;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


DECLARE SOW_STATUS_ID_GROWING                   INT             DEFAULT 1;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_referral_id                 INT             DEFAULT 0;

DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_last_sow_id                INT             DEFAULT 0;
DECLARE cur_pig_farm_last_boar_id               INT             DEFAULT 0;

DECLARE cur_temp                                INT             DEFAULT 0;

DECLARE cur_sow_boar_id                         INT             DEFAULT 0;

DECLARE cur_max_num_sow_boar_free               INT             DEFAULT 0;
DECLARE cur_num_days_free_trial                 INT             DEFAULT 0;

DECLARE cur_acc_referral_date_active            DATE            DEFAULT NULL;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;

DECLARE cur_notes                               VARCHAR(200);



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        last_sow_id,
        last_boar_id
INTO    
        cur_pig_farm_account_id,
        cur_pig_farm_last_sow_id,
        cur_pig_farm_last_boar_id
FROM    pig_farm
WHERE   id = in_pig_farm_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SOW_BOAR,
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



/* Check for duplicate entry. */ 
IF in_number IS NOT NULL THEN 
    /* If sow_boar.number is given, will be check as one of unique keys. */

    SELECT  id
    INTO    cur_sow_boar_id
    FROM    sow_boar
    WHERE   account_id  = cur_user_account_id   AND
            pig_farm_id = in_pig_farm_id        AND
            sex         = in_sex                AND
            number      = in_number;

ELSE
    /* If sow_boar.name is given, will be check as one of unique keys. */
    
    SELECT  id
    INTO    cur_sow_boar_id
    FROM    sow_boar
    WHERE   account_id  = cur_user_account_id   AND
            pig_farm_id = in_pig_farm_id        AND
            sex         = in_sex                AND
            name        = in_name;

END IF;


IF cur_sow_boar_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



IF in_sex = 'F' THEN 
    SET cur_pig_farm_last_sow_id = cur_pig_farm_last_sow_id + 1;
    
    
    INSERT INTO sow_boar(
        account_id,
        pig_farm_id,
        farm_sow_id,
        
        line_id,
        sow_status_id,
        is_external,
        is_production_ready,
        num_nipples,
        
        parent_sow_id,
        parent_boar_id,
        
        sex,
        
        number,
        name,
        date_of_birth,
        
        added_by_user_id
    ) VALUES (
        cur_user_account_id,
        in_pig_farm_id,
        cur_pig_farm_last_sow_id,
        
        in_line_id,
        in_sow_status_id,
        in_is_external,
        in_is_production_ready,
        in_num_nipples,
        
        in_parent_sow_id,
        in_parent_boar_id,
        
        in_sex,
        
        in_number,
        in_name,
        in_date_of_birth,
        
        in_user_id
    );
    
    /* Count sow_boar entries of the farm. */
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    sow_boar
    WHERE   pig_farm_id = in_pig_farm_id;
    
    
    UPDATE pig_farm SET
        count_sow_boar      = cur_count,
        data_ver_num_sow    = data_ver_num_sow + 1
    WHERE id = in_pig_farm_id;

ELSE
    SET cur_pig_farm_last_boar_id = cur_pig_farm_last_boar_id + 1;
    
    INSERT INTO sow_boar(
        account_id,
        pig_farm_id,
        farm_boar_id,
        
        line_id,
        sow_status_id,
        is_external,
        is_production_ready,
        
        sex,
        
        number,
        name,
        date_of_birth,
        
        added_by_user_id
    ) VALUES (
        cur_user_account_id,
        in_pig_farm_id,
        cur_pig_farm_last_boar_id,        

        in_line_id,
        NULL,
        in_is_external,
        in_is_production_ready,
        
        in_sex,
        
        in_number,
        in_name,
        in_date_of_birth,
        
        in_user_id
    );
    
    /* Count sow_boar entries of the farm. */
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    sow_boar
    WHERE   pig_farm_id = in_pig_farm_id;
    
    
    UPDATE pig_farm SET 
        count_sow_boar      = cur_count,
        data_ver_num_boar   = data_ver_num_boar + 1
    WHERE id = in_pig_farm_id;
    
END IF;

SELECT LAST_INSERT_ID() INTO cur_sow_boar_id;




/*
2026-04-12 Notes:
1.) The account.date_trial_start is redefined when the account has reached
    the ACC_MIN_NUM_SOW_BOAR_FREE. This is to give flexibility to the 
    application as well as for marketing.

2.) This is not anymore the date of account registration to the give the user
    more time to evaluate the application. Note, account.date_trial_start is
    filled during account registration;  

3.) The account.date_trial_end will also be recomputed.

4.) Will also check if account used a account_referral; 
    The account_referral.business_date_active will also be updated, as this will
    be used for calculating rewards for the account who give the referral_code.
*/



/* Get account details */
SELECT  flag,
        account_referral_id

INTO    cur_account_flag,
        cur_account_referral_id
        
FROM    account
WHERE   id = cur_pig_farm_account_id;



/* Count sow_boar entries of the account. */
SET cur_count = 0;

SELECT  COUNT(*) 
INTO    cur_count
FROM    sow_boar
WHERE   account_id = cur_pig_farm_account_id;

UPDATE account SET 
    count_sow_boar = cur_count
WHERE id = cur_pig_farm_account_id;



IF cur_account_flag & FLAG_BIT_FREE_TRIAL_STARTED = 0 THEN 
    /* Get ACC_MAX_NUM_SOW_BOAR_FREE*/
    SELECT  val_int
    INTO    cur_max_num_sow_boar_free
    FROM    a01_list_of_values
    WHERE   id = LOV_ID_ACC_MAX_NUM_SOW_BOAR_FREE;  


    IF cur_count > cur_max_num_sow_boar_free THEN 
        
        /*Get ACCOUNT_NUMDAYS_FREE_TRIAL*/
        SELECT  val_int
        INTO    cur_num_days_free_trial
        FROM    a01_list_of_values
        WHERE   id = LOV_ID_ACCOUNT_NUMDAYS_FREE_TRIAL;  
        
        
        UPDATE account SET 
            date_trial_start        = CURRENT_DATE,
            date_trial_end          = CURRENT_DATE + INTERVAL cur_num_days_free_trial DAY,
            date_next_sow_boar_count= CURRENT_DATE + INTERVAL cur_num_days_free_trial DAY,
            flag                    = flag | FLAG_BIT_FREE_TRIAL_STARTED
        WHERE id = cur_pig_farm_account_id;
        
    END IF;


END IF;


/* Activate account_referral if needed. */
IF cur_account_referral_id > 0 THEN 
    /*Get ACC_MIN_NUM_SOW_BOAR_REFERRAL_ACTIVE*/
    SELECT  val_int
    INTO    cur_temp
    FROM    a01_list_of_values
    WHERE   id = LOV_ID_ACC_MIN_NUM_SOW_BOAR_REFERRAL_ACTIVE;  


    SELECT  business_date_active 
    INTO    cur_acc_referral_date_active
    FROM    account_referral
    WHERE   id = cur_account_referral_id;
    
    IF cur_acc_referral_date_active IS NULL THEN 
        
        IF cur_count >= cur_temp THEN 
        
            UPDATE account_referral SET 
                flag = flag | FLAG_BIT_REFERRED_ACCOUNT_ACTIVE,
                business_date_active = CURRENT_DATE
            WHERE id = cur_account_referral_id;
        END IF;
        
    END IF;
END IF;



/* This is necessary as notes is optional; It will leave blank in table row 
     UI if no notes.*/


SET cur_notes  = CONCAT('SYS: Added to list; ');


IF in_notes IS NOT NULL THEN 
    SET cur_notes  = CONCAT(cur_notes, in_notes);
END IF;


/* Truncate notes if needed. */
IF LENGTH(cur_notes) >= 160 THEN 
    SET cur_notes = SUBSTRING(cur_notes, 1, 159);
END IF;



INSERT INTO pig_prod_notes (
    account_id,
    pig_farm_id,
    
    pig_prod_id,
    sow_boar_id,
    
    notes,
    date_notes,
    added_by_user_id
    
) VALUES (
    cur_pig_farm_account_id,
    in_pig_farm_id,

    NULL,
    cur_sow_boar_id,
    
    cur_notes,
    CURRENT_DATE,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;

UPDATE sow_boar SET 
    add_notes_id = cur_pig_prod_notes_id
WHERE id = cur_sow_boar_id;



UPDATE pig_farm SET 
    last_sow_id     = cur_pig_farm_last_sow_id,
    last_boar_id    = cur_pig_farm_last_boar_id
WHERE id = in_pig_farm_id;


/* Add gilt ops if sow and birthdate is not NULL.
All sows regardless production ready or nt will create 
the gilt operations.
*/
IF in_sex = 'F' AND in_date_of_birth IS NOT NULL  THEN 
    
    /* Count if there is an account gilt pig ops.*/
    SELECT  COUNT(*) 
    INTO    cur_count 
    FROM    account_pig_ops
    WHERE   account_id = cur_pig_farm_account_id AND 
            operation_type = PIG_OPERATION_TYPE_GILT_OPS;
            
            
    IF cur_count > 0 THEN 
    
        CALL gilt_pig_ops_add(
            in_user_id,
            cur_user_account_id,
            PIG_OPERATION_TYPE_GILT_OPS,
            cur_sow_boar_id,
            in_date_of_birth
        );
        
    END IF;

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
