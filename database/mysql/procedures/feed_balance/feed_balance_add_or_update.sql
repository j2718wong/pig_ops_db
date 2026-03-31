DELIMITER $$

DROP PROCEDURE IF EXISTS feed_balance_add_or_update $$
CREATE PROCEDURE feed_balance_add_or_update(
    in_user_id              INT,
    
    in_pig_farm_id          INT,    /* IF this is filled up, this is for farm_balance */
    in_pig_prod_id          INT,    
    in_prod_group_id        INT,
    
    in_date_balance         VARCHAR(10),
    
    in_num_pigs             INT, /* This can be entered null; 
                                if entered null, this is computed.*/
    
    in_num_gestating        DECIMAL(5,1),
    in_num_lactating        DECIMAL(5,1),
    in_num_booster          DECIMAL(5,1),
    in_num_prestarter       DECIMAL(5,1),
    in_num_starter          DECIMAL(5,1),
    in_num_grower           DECIMAL(5,1),
    in_num_finisher         DECIMAL(5,1)
)  

BEGIN

/** 
 * Will add feed_balance entry.
 *
 * Notes 2025-12-05:
 * 1.) This is modified to allow add entry and update entry on the same procedure.
 *
 * 2.) Automatic num_pigs calculation if in_num_pigs input is null.
 *  The mixed up of number of pigs in the feed balance was originally intended
 *  to show in the reports the number of pigs in every feed_balance entry.
 *  In the UI, this is not manually entered
 *
 * 3.) Feed consumption is not anymore calculated in every feed balance entry 
 *  or update. This is because user can frequently update the feed_balance on 
 *  the same date_balance than rather entering only once a week (as it was 
 *  originally designed). 
 *
 * 4.) The feed_balance table is not visible to user in UI. As this may not be 
 *  useful to the user. 
 *
 * 5.) Additional gestating feed in feed balance in case user wants to
 *  to track this.
 *
 *
 * Notes 2026-01-26:
 * 1.) There will be a sum up of feed_buy of a given pig_prod or pig_prod_group
 * on the date_balance. This is because in the mobile UI, the already bought 
 * feeds will be visible in every feed_balance entry.
 *
 *
 * Notes 2026-02-27
 * 1.) The farm feed balance will now be saved in feed_balance table. Previously 
 * this was saved in sow_boar_balance table to simplify sow_balance report.
 *
 * Input matrix
 *                 in_pig_farm_id   in_pig_prod_id  in_prod_group_id
 * farm_balance         >0          NULL            NULL 
 * pig_prod_balance    NULL         >0              NULL
 * prod_group_balance  NULL         NULL            >0  
 *
 * 
 * 2.) The feeds in sow_boar_balance will be discontinued later;
 * The sow_boar_balance will still be maintained.   
 *
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 25, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_FEED_BAL INT         DEFAULT 20;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BALANCE            INT             DEFAULT 18;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE FEED_TYPE_ID_GESTATING                  INT             DEFAULT 1;
DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;


DECLARE KG_WEIGHT_PER_UNIT_LACTATING            INT             DEFAULT 50;
DECLARE KG_WEIGHT_PER_UNIT_BOOSTER              INT             DEFAULT 1;
DECLARE KG_WEIGHT_PER_UNIT_PRESTARTER           INT             DEFAULT 25;
DECLARE KG_WEIGHT_PER_UNIT_STARTER              INT             DEFAULT 50;
DECLARE KG_WEIGHT_PER_UNIT_GROWER               INT             DEFAULT 50;
DECLARE KG_WEIGHT_PER_UNIT_FINISHER             INT             DEFAULT 50;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE compare_account_id                      INT             DEFAULT 0;

DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;
DECLARE cur_pig_prod_last_feed_balance_id       INT             DEFAULT 0;


DECLARE cur_feed_balance_id                     INT             DEFAULT 0;

DECLARE cur_feed_buy_gestating                  INT             DEFAULT 0;
DECLARE cur_feed_buy_lactating                  INT             DEFAULT 0;
DECLARE cur_feed_buy_booster                    INT             DEFAULT 0;
DECLARE cur_feed_buy_prestarter                 INT             DEFAULT 0;
DECLARE cur_feed_buy_starter                    INT             DEFAULT 0;
DECLARE cur_feed_buy_grower                     INT             DEFAULT 0;
DECLARE cur_feed_buy_finisher                   INT             DEFAULT 0;
    




DECLARE cur_num_days_since_birth                INT             DEFAULT 0;
DECLARE cur_num_weeks_since_birth               INT             DEFAULT 0;

DECLARE cur_kg_total_gestating                  INT             DEFAULT 0;
DECLARE cur_kg_total_lactating                  INT             DEFAULT 0;
DECLARE cur_kg_total_booster                    INT             DEFAULT 0;
DECLARE cur_kg_total_prestarter                 INT             DEFAULT 0;
DECLARE cur_kg_total_starter                    INT             DEFAULT 0;
DECLARE cur_kg_total_grower                     INT             DEFAULT 0;
DECLARE cur_kg_total_finisher                   INT             DEFAULT 0;

DECLARE prev_consumed_kg_total                  INT             DEFAULT 0;
DECLARE curr_consumed_kg_total                  INT             DEFAULT 0;
DECLARE diff_consumed_kg_total                  INT             DEFAULT 0;

DECLARE consumption_per_pig                     DECIMAL(5,2)    DEFAULT NULL;

DECLARE cur_consumed_kg_gestating               INT             DEFAULT 0;
DECLARE cur_consumed_kg_lactating               INT             DEFAULT 0;
DECLARE cur_consumed_kg_booster                 INT             DEFAULT 0;
DECLARE cur_consumed_kg_prestarter              INT             DEFAULT 0;
DECLARE cur_consumed_kg_starter                 INT             DEFAULT 0;
DECLARE cur_consumed_kg_grower                  INT             DEFAULT 0;
DECLARE cur_consumed_kg_finisher                INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_farm_id > 0 THEN 
    SELECT
        account_id
    INTO 
        cur_pig_farm_account_id
    FROM pig_farm
    WHERE id =  in_pig_farm_id;
        
    SET compare_account_id = cur_pig_farm_account_id;
END IF;


IF in_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        pig_farm_id,
        prod_status_id,
        date_actual_birth,
        last_feed_balance_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_actual_birth,
        cur_pig_prod_last_feed_balance_id

    FROM pig_production 
    WHERE id = in_pig_prod_id;
    
    SET compare_account_id = cur_pig_prod_account_id;
END IF;


IF in_prod_group_id > 0 THEN 
    /** TO FIX*/
    SELECT 
        account_id,
        pig_prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM production_group 
    WHERE id = in_prod_group_id;

END IF;
    


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    compare_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BALANCE,
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


IF in_pig_prod_id > 0 THEN
    IF cur_pig_prod_status_id IN (  PRODUCTION_STATUS_ID_TERMINATED,
                                    PRODUCTION_STATUS_ID_NOT_PREGNANT,
                                    PRODUCTION_STATUS_ID_COMBINED,
                                    PRODUCTION_STATUS_ID_HARVESTED,
                                    PRODUCTION_STATUS_ID_CLOSED) THEN 
        SET res_num     = RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_FEED_BAL;
        SET res_code    = "RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_FEED_BAL";
        
        LEAVE process_user;
    END IF;
END IF;


IF in_pig_farm_id > 0 THEN 
    SELECT  id
    INTO    cur_feed_balance_id
    FROM    feed_balance
    WHERE   pig_farm_id         = in_pig_farm_id    AND
            pig_prod_id IS NULL  AND
            date_balance        = in_date_balance
    LIMIT   1;
END IF;    


IF in_pig_prod_id > 0 THEN 
    SELECT  id
    INTO    cur_feed_balance_id
    FROM    feed_balance
    WHERE   pig_prod_id         = in_pig_prod_id    AND
            date_balance        = in_date_balance
    LIMIT   1;
END IF;    

    
IF in_prod_group_id > 0 THEN 
    SELECT  id
    INTO    cur_feed_balance_id
    FROM    feed_balance
    WHERE   pig_prod_group_id   = in_prod_group_id    AND
            date_balance        = in_date_balance
    LIMIT   1;
END IF;
    



IF in_pig_prod_id > 0 THEN 
    
    /* Automatic pigs counting if not manually counted.*/
    IF in_num_pigs IS NULL THEN 
        IF in_pig_prod_id > 0 THEN 
            IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_GESTATING THEN 
                SET in_num_pigs = 0;
            ELSE
                CALL production_calculate_current_pigs(in_pig_prod_id, 0, in_num_pigs);
            END IF;
        ELSE /*production_group*/
            CALL production_calculate_current_pigs(0, in_prod_group_id, in_num_pigs);
        END IF;

    END IF;


    /*
    Count all feed_buy before and on this in_date_balance
    for every feed_type.
    */



    SELECT  SUM(quantity)
    INTO    cur_feed_buy_gestating
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_GESTATING AND
            date_buy <= in_date_balance;

    SELECT  SUM(quantity)
    INTO    cur_feed_buy_lactating
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_LACTATING AND
            date_buy <= in_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_booster
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_BOOSTER AND
            date_buy <= in_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_prestarter
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_PRESTARTER AND
            date_buy <= in_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_starter
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_STARTER AND
            date_buy <= in_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_grower
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_GROWER AND
            date_buy <= in_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_finisher
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_FINISHER AND
            date_buy <= in_date_balance;

END IF;    





IF cur_feed_balance_id = 0 THEN 
    IF in_pig_farm_id > 0 THEN 
        SET cur_pig_prod_pig_farm_id = in_pig_farm_id;
    END IF;


    INSERT INTO feed_balance(
        pig_farm_id,
        pig_prod_id,
        pig_prod_group_id,
        
        date_balance,
        
        num_pigs,
        
        num_b_gestating,
        num_b_lactating,
        num_b_booster,
        num_b_prestarter,
        num_b_starter,
        num_b_grower,
        num_b_finisher,
        
        num_gestating,
        num_lactating,
        num_booster,
        num_prestarter,
        num_starter,
        num_grower,
        num_finisher,

        added_by_user_id
    ) VALUES (
        cur_pig_prod_pig_farm_id,
        in_pig_prod_id,
        in_prod_group_id,
        
        in_date_balance,
        
        in_num_pigs,
        
        cur_feed_buy_gestating,
        cur_feed_buy_lactating,
        cur_feed_buy_booster,
        cur_feed_buy_prestarter,
        cur_feed_buy_starter,
        cur_feed_buy_grower,
        cur_feed_buy_finisher,
        
        in_num_gestating,
        in_num_lactating,
        in_num_booster,
        in_num_prestarter,
        in_num_starter,
        in_num_grower,
        in_num_finisher,

        in_user_id
    );
    
    SELECT LAST_INSERT_ID() INTO cur_feed_balance_id;

    IF in_pig_farm_id > 0 THEN 
        UPDATE pig_farm SET 
            last_feed_balance_date = in_date_balance
        WHERE id = in_pig_farm_id;
    END IF;
    
    IF in_pig_prod_id > 0 THEN 
        UPDATE pig_farm SET 
            last_feed_balance_date = in_date_balance
        WHERE id = cur_pig_prod_pig_farm_id;
    END IF;
    

ELSE
    UPDATE feed_balance SET 
    
        num_pigs            = in_num_pigs,
        
        num_b_gestating     = cur_feed_buy_gestating,
        num_b_lactating     = cur_feed_buy_lactating,
        num_b_booster       = cur_feed_buy_booster,
        num_b_prestarter    = cur_feed_buy_prestarter,
        num_b_starter       = cur_feed_buy_starter,
        num_b_grower        = cur_feed_buy_grower,
        num_b_finisher      = cur_feed_buy_finisher,
        
        num_gestating       = in_num_gestating,
        num_lactating       = in_num_lactating,
        num_booster         = in_num_booster,
        num_prestarter      = in_num_prestarter,
        num_starter         = in_num_starter,
        num_grower          = in_num_grower,
        num_finisher        = in_num_finisher,
    
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP

    WHERE id = cur_feed_balance_id;


END IF;




IF in_pig_prod_id > 0 THEN 
    /* Compute num_days_since_birth, num_weeks_since_birth;
    This is calculated as pigs date birth is DAY 0 regardless
    of the account.flag_settings.FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH setting.
    */
    IF cur_pig_prod_date_actual_birth IS NOT NULL THEN
        IF in_date_balance > cur_pig_prod_date_actual_birth THEN 
            SET cur_num_days_since_birth    = DATEDIFF(in_date_balance, cur_pig_prod_date_actual_birth);
            SET cur_num_weeks_since_birth   = ROUND(cur_num_days_since_birth/7);
        END IF;
    END IF; 
    

    UPDATE pig_production SET
        last_feed_balance_id        = cur_feed_balance_id
    WHERE id = in_pig_prod_id;
    
    
    /* This is now computed separately; Preferrably every weekend
    UPDATE feed_balance SET 
        num_days_since_birth    = cur_num_days_since_birth,
        num_weeks_since_birth   = cur_num_weeks_since_birth,
        
        consumed_kg_booster     = cur_consumed_kg_booster,
        consumed_kg_lactating   = cur_consumed_kg_lactating,
        consumed_kg_prestarter  = cur_consumed_kg_prestarter,
        consumed_kg_starter     = cur_consumed_kg_starter,
        consumed_kg_grower      = cur_consumed_kg_grower,
        consumed_kg_finisher    = cur_consumed_kg_finisher,
        
        consumed_kg_total       = curr_consumed_kg_total,
        diff_consumed_kg_total  = diff_consumed_kg_total,
        diff_consumption_per_pig = consumption_per_pig
        
    WHERE id = cur_feed_balance_id;
    */
    
    UPDATE feed_balance SET 
        num_days_since_birth    = cur_num_days_since_birth,
        num_weeks_since_birth   = cur_num_weeks_since_birth
    WHERE id = cur_feed_balance_id;
    
    
END IF;

IF in_pig_farm_id > 0 THEN 
    UPDATE pig_farm SET 
        data_ver_num_feed_balance = data_ver_num_feed_balance + 1
    WHERE id = in_pig_farm_id;

END IF;


IF in_pig_prod_id > 0 THEN 
    UPDATE pig_production SET  
        data_ver_num_feed_balance = data_ver_num_feed_balance + 1
    WHERE id = in_pig_prod_id;
    
    /** This needs to be updated too.*/
    UPDATE pig_farm SET 
        data_ver_num_feed_balance = data_ver_num_feed_balance + 1
    WHERE id = cur_pig_prod_pig_farm_id;
END IF;

IF in_prod_group_id > 0 THEN 
    UPDATE pig_production SET  
        data_ver_num_feed_balance = data_ver_num_feed_balance + 1
    WHERE id = in_prod_group_id;
END IF;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_balance_id                 AS feed_balance_id;

END $$

DELIMITER ;
