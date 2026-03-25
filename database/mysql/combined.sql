DELIMITER $$

DROP PROCEDURE IF EXISTS feed_balance_update $$
CREATE PROCEDURE feed_balance_update(
    in_user_id              INT,
    
    in_feed_balance_id      INT,
    
    in_date_balance         VARCHAR(10),
    
    in_num_pigs             INT,
    
    in_num_lactating        DECIMAL(5,1),
    in_num_booster          DECIMAL(5,1),
    in_num_prestarter       DECIMAL(5,1),
    in_num_starter          DECIMAL(5,1),
    in_num_grower           DECIMAL(5,1),
    in_num_finisher         DECIMAL(5,1)
)  

BEGIN

/** 
 * Will update feed_balance entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 25, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;

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


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_group_id                   INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;




DECLARE cur_pig_prod_feed_bal_id                INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  pig_prod_id,
        pig_prod_group_id

INTO    cur_pig_prod_id,
        cur_pig_prod_group_id

FROM    feed_balance 
WHERE   id = in_feed_balance_id;


IF cur_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production 
    WHERE id = cur_pig_prod_id;

ELSE
    SELECT 
        account_id,
        pig_prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production_group 
    WHERE id = cur_pig_prod_group_id;

END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BALANCE,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


UPDATE feed_balance SET 
    date_balance        = in_date_balance,
    
    num_pigs            = in_num_pigs,
    
    num_l_lactating     = in_num_lactating,
    num_l_booster       = in_num_booster,
    num_l_prestarter    = in_num_prestarter,
    num_l_starter       = in_num_starter,
    num_l_grower        = in_num_grower,
    num_l_finisher      = in_num_finisher,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_feed_balance_id;


IF cur_pig_prod_id > 0 THEN 
    UPDATE pig_production SET  
        data_ver_num_feed_balance = data_ver_num_feed_balance + 1
    WHERE id = cur_pig_prod_id;
END IF;

IF cur_pig_prod_group_id > 0 THEN
    UPDATE pig_production SET  
        data_ver_num_feed_balance = data_ver_num_feed_balance + 1
    WHERE id = cur_pig_prod_group_id;
END IF;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_feed_bal_id            AS pig_prod_feed_bal_id;

END $$

DELIMITER ;
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


IF in_pig_prod_id > 0 THEN 
    UPDATE pig_production SET  
        data_ver_num_feed_balance = data_ver_num_feed_balance + 1
    WHERE id = in_pig_prod_id;
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
DELIMITER $$

DROP PROCEDURE IF EXISTS feed_balance_update_feed_buy $$
CREATE PROCEDURE feed_balance_update_feed_buy()  

BEGIN

/** 
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 18, 2026
 *
 */

DECLARE FEED_TYPE_ID_GESTATING                  INT             DEFAULT 1;
DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;



DECLARE cur_feed_balance_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_feed_balance_date_balance           DATE;


DECLARE cur_feed_buy_gestating                  INT             DEFAULT 0;
DECLARE cur_feed_buy_lactating                  INT             DEFAULT 0;
DECLARE cur_feed_buy_booster                    INT             DEFAULT 0;
DECLARE cur_feed_buy_prestarter                 INT             DEFAULT 0;
DECLARE cur_feed_buy_starter                    INT             DEFAULT 0;
DECLARE cur_feed_buy_grower                     INT             DEFAULT 0;
DECLARE cur_feed_buy_finisher                   INT             DEFAULT 0;
    


DECLARE l_last_row_fetched TINYINT;
DECLARE c_feed_balance CURSOR FOR
    SELECT  id,
            pig_prod_id,
            date_balance
    FROM    feed_balance; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 

    
SET l_last_row_fetched=0;
OPEN c_feed_balance;   
    

loop_here: LOOP
    FETCH c_feed_balance INTO 
        cur_feed_balance_id,
        cur_pig_prod_id,
        cur_feed_balance_date_balance;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    
   
    /*
    Count all feed_buy before and on this cur_feed_balance_date_balance
    for every feed_type.
    */



    SELECT  SUM(quantity)
    INTO    cur_feed_buy_gestating
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_GESTATING AND
            date_buy <= cur_feed_balance_date_balance;

    SELECT  SUM(quantity)
    INTO    cur_feed_buy_lactating
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_LACTATING AND
            date_buy <= cur_feed_balance_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_booster
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_BOOSTER AND
            date_buy <= cur_feed_balance_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_prestarter
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_PRESTARTER AND
            date_buy <= cur_feed_balance_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_starter
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_STARTER AND
            date_buy <= cur_feed_balance_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_grower
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_GROWER AND
            date_buy <= cur_feed_balance_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_finisher
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_FINISHER AND
            date_buy <= cur_feed_balance_date_balance;

    
    UPDATE feed_balance SET 
        num_b_gestating     = cur_feed_buy_gestating,
        num_b_lactating     = cur_feed_buy_lactating,
        num_b_booster       = cur_feed_buy_booster,
        num_b_prestarter    = cur_feed_buy_prestarter,
        num_b_starter       = cur_feed_buy_starter,
        num_b_grower        = cur_feed_buy_grower,
        num_b_finisher      = cur_feed_buy_finisher
    WHERE id = cur_feed_balance_id;
    

END LOOP loop_here;
 
CLOSE c_feed_balance;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_update_update_prod_gestating $$
CREATE PROCEDURE account_pig_ops_update_update_prod_gestating(
    in_account_id           INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;

DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_date_insemination          DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;



DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_prod CURSOR FOR
    SELECT  id,
            date_insemination
    FROM    pig_production
    WHERE   account_id      = in_account_id AND 
            prod_status_id  = PRODUCTION_STATUS_ID_GESTATING
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


/* See account_pig_ops.sql Notes for this num_days_to_add adjustment.*/

SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;


IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_INSEM > 0 THEN 
    SET num_days_to_add = in_num_days_since - 1;
ELSE
    SET num_days_to_add = in_num_days_since;
END IF;
    


    
SET l_last_row_fetched=0;
OPEN c_account_pig_prod;   
    

loop_here: LOOP
    FETCH c_account_pig_prod INTO 
        cur_pig_prod_id,
        cur_pig_prod_date_insemination;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        date_target = DATE_ADD(cur_pig_prod_date_insemination, INTERVAL num_days_to_add DAY)
    WHERE pig_prod_id = cur_pig_prod_id AND account_pig_ops_id = in_account_pig_ops_id;
    

END LOOP loop_here;
 
CLOSE c_account_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_update_update_prod_lactating $$
CREATE PROCEDURE account_pig_ops_update_update_prod_lactating(
    in_account_id           INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;

DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_prod CURSOR FOR
    SELECT  id,
            date_actual_birth
    FROM    pig_production
    WHERE   account_id      = in_account_id AND 
            prod_status_id  = PRODUCTION_STATUS_ID_LACTATING
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


/* See account_pig_ops.sql Notes for this num_days_to_add adjustment.*/

SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;


IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH > 0 THEN 
    SET num_days_to_add = in_num_days_since - 1;
ELSE
    SET num_days_to_add = in_num_days_since;
END IF;
    
    
SET l_last_row_fetched=0;
OPEN c_account_pig_prod;   
    

loop_here: LOOP
    FETCH c_account_pig_prod INTO 
        cur_pig_prod_id,
        cur_pig_prod_date_actual_birth;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        date_target = DATE_ADD(cur_pig_prod_date_actual_birth, INTERVAL num_days_to_add DAY)
    WHERE pig_prod_id = cur_pig_prod_id AND account_pig_ops_id = in_account_pig_ops_id;


END LOOP loop_here;
 
CLOSE c_account_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_update_update_gilts $$
CREATE PROCEDURE account_pig_ops_update_update_gilts(
    in_account_id           INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE SOW_STATUS_GROWING                      INT             DEFAULT 1;

DECLARE cur_sow_id                              INT             DEFAULT 0;
DECLARE cur_sow_date_of_birth                   DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_gilts CURSOR FOR
    SELECT  id,
            date_of_birth
    FROM    sow_boar
    WHERE   account_id      = in_account_id AND 
            sex = 'F'                       AND
            date_of_birth IS NOT NULL       AND
            sow_status_id   = SOW_STATUS_GROWING AND
            mate_count      = 0
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


/* See account_pig_ops.sql Notes for this num_days_to_add adjustment.*/

SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;


IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH > 0 THEN 
    SET num_days_to_add = in_num_days_since - 1;
ELSE
    SET num_days_to_add = in_num_days_since;
END IF;
    
    
SET l_last_row_fetched=0;
OPEN c_account_gilts;   
    

loop_here: LOOP
    FETCH c_account_gilts INTO 
        cur_sow_id,
        cur_sow_date_of_birth;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        date_target = DATE_ADD(cur_sow_date_of_birth, INTERVAL num_days_to_add DAY)
    WHERE sow_boar_id = cur_sow_id AND account_pig_ops_id = in_account_pig_ops_id;


END LOOP loop_here;
 
CLOSE c_account_gilts;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_update_update_weaning_sows $$
CREATE PROCEDURE account_pig_ops_update_update_weaning_sows(
    in_account_id           INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE SOW_STATUS_WEANING                      INT             DEFAULT 4;

DECLARE cur_sow_id                              INT             DEFAULT 0;
DECLARE cur_sow_date_wean                       DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_weaning_sows CURSOR FOR
    SELECT  a.id,
            b.date_weaning
    FROM    sow_boar a
    LEFT OUTER JOIN pig_production b ON a.last_pig_production_id = b.id
    WHERE   a.account_id      = in_account_id       AND 
            a.sex             = 'F'                 AND
            a.sow_status_id   = SOW_STATUS_WEANING  AND 
            b.date_weaning IS NOT NULL
            
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


/* See account_pig_ops.sql Notes for this num_days_to_add adjustment.*/

/* unless needed
SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;
*/


SET num_days_to_add = in_num_days_since;
    
    
SET l_last_row_fetched=0;
OPEN c_account_weaning_sows;   
    

loop_here: LOOP
    FETCH c_account_weaning_sows INTO 
        cur_sow_id,
        cur_sow_date_wean;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        date_target = DATE_ADD(cur_sow_date_wean, INTERVAL num_days_to_add DAY)
    WHERE sow_boar_id = cur_sow_id AND account_pig_ops_id = in_account_pig_ops_id;


END LOOP loop_here;
 
CLOSE c_account_weaning_sows;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_update $$
CREATE PROCEDURE account_pig_ops_update(
    in_user_id              INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT,
    
    is_medvac               INT,
    
    in_name                 VARCHAR(50),
    in_short_name           VARCHAR(15),
    in_description          VARCHAR(160)
    
)

BEGIN

/** 
 * Will update account_pig_ops entry.
 * @author Jack Wong
 * @since August 10, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS   INT                   DEFAULT 10;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC      INT             DEFAULT 2;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_ver_num_gestating_ops       INT             DEFAULT 0;

DECLARE cur_pig_ops_operation_type              INT             DEFAULT 0;
DECLARE cur_pig_ops_num_days_since              INT             DEFAULT 0;
        
DECLARE cur_account_pig_ops_account_id          INT             DEFAULT 0;
DECLARE cur_account_pig_ops_flag                INT             DEFAULT 0;
DECLARE cur_account_pig_ops_name                VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_account_pig_ops_account_id
FROM    account_pig_ops
WHERE   id = in_account_pig_ops_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_pig_ops_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


SELECT  operation_type,
        num_days_since,
        version_num,
        flag 
        
INTO    cur_pig_ops_operation_type,
        cur_pig_ops_num_days_since,
        cur_account_ver_num_gestating_ops,
        cur_account_pig_ops_flag

FROM    account_pig_ops
WHERE   id = in_account_pig_ops_id;




SET cur_account_pig_ops_flag = cur_account_pig_ops_flag & ~FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC;
IF is_medvac > 0 THEN 
    SET cur_account_pig_ops_flag = cur_account_pig_ops_flag | FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC;
END IF;


UPDATE account_pig_ops SET
    num_days_since      = in_num_days_since,
    version_num         = cur_account_ver_num_gestating_ops,
    flag                = cur_account_pig_ops_flag,
    
    name                = in_name,
    short_name          = in_short_name,
    description         = in_description,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_account_pig_ops_id;



IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
    UPDATE account SET 
        ver_num_gestating_ops = ver_num_gestating_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
END IF;


IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS THEN
    UPDATE account SET 
        ver_num_lactating_piglets_ops = ver_num_lactating_piglets_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
END IF;


IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_SOW THEN 
    UPDATE account SET 
        ver_num_lactating_sow_ops = ver_num_lactating_sow_ops + 1
    WHERE id = cur_account_pig_ops_account_id;    
END IF;
    

IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_GILT_OPS THEN 
    UPDATE account SET 
        ver_num_gilt_ops = ver_num_gilt_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
END IF;


IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS THEN 
    UPDATE account SET 
        ver_num_weaning_sow_ops = ver_num_weaning_sow_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
END IF;



IF cur_pig_ops_num_days_since != in_num_days_since THEN 
    IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
        CALL account_pig_ops_update_update_prod_gestating(
            cur_user_account_id,
            in_account_pig_ops_id,
            in_num_days_since
        );
    END IF;

    IF  cur_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_SOW OR
        cur_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS  THEN 
        
        CALL account_pig_ops_update_update_prod_lactating(
            cur_user_account_id,
            in_account_pig_ops_id,
            in_num_days_since
        );
    END IF;
    
    
    IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_GILT_OPS THEN 
        CALL account_pig_ops_update_update_gilts(
            cur_user_account_id,
            in_account_pig_ops_id,
            in_num_days_since
        );
    END IF;
    
    
    IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS THEN
        CALL account_pig_ops_update_update_weaning_sows(
            cur_user_account_id,
            in_account_pig_ops_id,
            in_num_days_since
        );
    END IF; 
END IF;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_ops_flag,
    cur_account_pig_ops_name
FROM account_pig_ops
WHERE id = in_account_pig_ops_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_pig_ops_id               AS account_pig_ops_id,
    cur_account_pig_ops_flag            AS account_pig_ops_flag,
    cur_account_pig_ops_name            AS account_pig_ops_name;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_add_update_prod_gestating $$
CREATE PROCEDURE account_pig_ops_add_update_prod_gestating(
    in_account_id           INT,
    in_operation_type       INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;

DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_date_insemination          DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;



DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_prod CURSOR FOR
    SELECT  id,
            date_insemination
    FROM    pig_production
    WHERE   account_id      = in_account_id AND 
            prod_status_id  = PRODUCTION_STATUS_ID_GESTATING
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


/* See account_pig_ops.sql Notes for this num_days_to_add adjustment.*/

SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;


IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_INSEM > 0 THEN 
    SET num_days_to_add = in_num_days_since - 1;
ELSE
    SET num_days_to_add = in_num_days_since;
END IF;
    

    
SET l_last_row_fetched=0;
OPEN c_account_pig_prod;   
    

loop_here: LOOP
    FETCH c_account_pig_prod INTO 
        cur_pig_prod_id,
        cur_pig_prod_date_insemination;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;
    
    
    

    INSERT INTO pig_prod_pig_ops(
        pig_prod_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        cur_pig_prod_id,
        in_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(cur_pig_prod_date_insemination, INTERVAL num_days_to_add DAY)
    );
    

END LOOP loop_here;
 
CLOSE c_account_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_add $$
CREATE PROCEDURE account_pig_ops_add(
    in_user_id              INT,
    in_operation_type       INT,
    in_num_days_since       INT,
    
    is_medvac               INT,
    
    in_name                 VARCHAR(50),
    in_short_name           VARCHAR(15),
    in_description          VARCHAR(160)
)  

BEGIN

/** 
 * Will add account_pig_ops entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

/**
Account Pig Operation Notes.

1.) For practical pig management purposes, the pig's age is typically counted
starting from day of its birth as DAY ONE. This convention is used in tracking 
developmental miles stones, health protocols, and managing production cycle.

But the computers always count day 1 on the next day of the event, after 24 
hours. 

To prevent confusion, the number of days settings displayed in the UI
will be also be saved in the database.

To add flexibility, this feature is saved in 

account.flag_settings FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH flag.

This flag is defaulted to 1 during account creation. 


2.) Tracking gestation may refer the day of breeding or insemination
as DAY 0.  

To add flexibility, this can be also be change as DAY 1. This is saved in 
account.flag_settings FLAG_BIT_DAY_1_ON_DATE_OF_INSEM flag.

This flag is defaulted to 0 during account creation. 

3.) The is_medvac flag is is short for medicine/vaccine flag.
*/


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 8;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;



/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC      INT             DEFAULT 2;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_ver_num_gestating_ops       INT             DEFAULT 0;

DECLARE cur_account_pig_ops_id                  INT             DEFAULT 0;
DECLARE cur_account_pig_ops_flag                INT             DEFAULT 0;
DECLARE cur_account_pig_ops_name                VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS,
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


/* Check for duplicate entry */
SELECT  id
INTO    cur_account_pig_ops_id
FROM    account_pig_ops
WHERE   account_id      = cur_user_account_id   AND 
        operation_type  = in_operation_type     AND
        UPPER(name)     = UPPER(in_name)
LIMIT   1;

IF cur_account_pig_ops_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;





SET cur_account_pig_ops_flag = 0;

IF is_medvac > 0 THEN
    SET cur_account_pig_ops_flag = FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC;
END IF;


INSERT INTO account_pig_ops(
    account_id,
    operation_type,
    num_days_since,
    flag,
    
    name,
    short_name,
    description,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_operation_type,
    in_num_days_since,
    cur_account_pig_ops_flag,
    
    in_name,
    in_short_name,
    in_description,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_pig_ops_id;




IF in_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
    UPDATE account SET 
        ver_num_gestating_ops = ver_num_gestating_ops + 1
    WHERE id = cur_user_account_id;

    
    CALL account_pig_ops_add_update_prod_gestating(
        cur_user_account_id,
        in_operation_type,
        cur_account_pig_ops_id,
        in_num_days_since
    );
END IF;


IF in_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS  THEN 
    UPDATE account SET 
        ver_num_lactating_piglets_ops = ver_num_lactating_piglets_ops + 1
    WHERE id = cur_user_account_id;
    
    
    CALL account_pig_ops_add_update_prod_lactating(
        cur_user_account_id,
        in_operation_type,
        cur_account_pig_ops_id,
        in_num_days_since
    );
END IF;



IF  in_operation_type = PIG_OPERATION_TYPE_LACTATING_SOW THEN 
    UPDATE account SET 
        ver_num_lactating_sow_ops = ver_num_lactating_sow_ops + 1
    WHERE id = cur_user_account_id;
    
    
    CALL account_pig_ops_add_update_prod_lactating(
        cur_user_account_id,
        in_operation_type,
        cur_account_pig_ops_id,
        in_num_days_since
    );
END IF;



IF in_operation_type = PIG_OPERATION_TYPE_GILT_OPS THEN 
    UPDATE account SET 
        ver_num_gilt_ops = ver_num_gilt_ops + 1
    WHERE id = cur_user_account_id;
    
    CALL account_pig_ops_add_update_gilts(
        cur_user_account_id,
        in_operation_type,
        cur_account_pig_ops_id,
        in_num_days_since
    );
END IF;



IF in_operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS THEN 
    UPDATE account SET 
        ver_num_weaning_sow_ops = ver_num_weaning_sow_ops + 1
    WHERE id = cur_user_account_id;
    
    CALL account_pig_ops_add_update_gilts(
        cur_user_account_id,
        in_operation_type,
        cur_account_pig_ops_id,
        in_num_days_since
    );
END IF;


 

END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_ops_flag,
    cur_account_pig_ops_name
FROM account_pig_ops
WHERE id = cur_account_pig_ops_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_pig_ops_id              AS account_pig_ops_id,
    cur_account_pig_ops_flag            AS account_pig_ops_flag,
    cur_account_pig_ops_name            AS account_pig_ops_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_add_update_weaning_sows $$
CREATE PROCEDURE account_pig_ops_add_update_weaning_sows(
    in_account_id           INT,
    in_operation_type       INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 8, 2026
 *
 */

DECLARE SOW_STATUS_WEANING                      INT             DEFAULT 4;

DECLARE cur_sow_id                              INT             DEFAULT 0;
DECLARE cur_sow_date_wean                       DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_sows CURSOR FOR
    SELECT  a.id,
            b.date_weaning
    FROM    sow_boar a
    LEFT OUTER JOIN pig_production b ON a.last_pig_production_id = b.id
    WHERE   a.account_id      = in_account_id       AND 
            a.sex             = 'F'                 AND
            a.sow_status_id   = SOW_STATUS_WEANING  AND 
            b.date_weaning IS NOT NULL
            
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 



/* unless needed
SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;
*/


SET num_days_to_add = in_num_days_since;
    

    
SET l_last_row_fetched=0;
OPEN c_account_sows;   
    

loop_here: LOOP
    FETCH c_account_sows INTO 
        cur_sow_id,
        cur_sow_date_wean;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    INSERT INTO pig_prod_pig_ops(
        sow_boar_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        cur_sow_id,
        in_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(cur_sow_date_wean, INTERVAL num_days_to_add DAY)
    );
    

END LOOP loop_here;
 
CLOSE c_account_sows;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_add_update_gilts $$
CREATE PROCEDURE account_pig_ops_add_update_gilts(
    in_account_id           INT,
    in_operation_type       INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 12, 2025
 *
 */

DECLARE SOW_STATUS_GROWING                      INT             DEFAULT 1;

DECLARE cur_sow_id                              INT             DEFAULT 0;
DECLARE cur_sow_date_of_birth                   DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_gilts CURSOR FOR
    SELECT  id,
            date_of_birth
    FROM    sow_boar
    WHERE   account_id      = in_account_id AND 
            sex = 'F'                       AND
            date_of_birth IS NOT NULL       AND
            sow_status_id   = SOW_STATUS_GROWING
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 




SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;


IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH > 0 THEN 
    SET num_days_to_add = in_num_days_since - 1;
ELSE
    SET num_days_to_add = in_num_days_since;
END IF;
    

    
SET l_last_row_fetched=0;
OPEN c_account_gilts;   
    

loop_here: LOOP
    FETCH c_account_gilts INTO 
        cur_sow_id,
        cur_sow_date_of_birth;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    INSERT INTO pig_prod_pig_ops(
        sow_boar_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        cur_sow_id,
        in_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(cur_sow_date_of_birth, INTERVAL num_days_to_add DAY)
    );
    

END LOOP loop_here;
 
CLOSE c_account_gilts;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_add_update_prod_lactating $$
CREATE PROCEDURE account_pig_ops_add_update_prod_lactating(
    in_account_id           INT,
    in_operation_type       INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;

DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_prod CURSOR FOR
    SELECT  id,
            date_actual_birth
    FROM    pig_production
    WHERE   account_id      = in_account_id AND 
            prod_status_id  = PRODUCTION_STATUS_ID_LACTATING
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


/* See account_pig_ops.sql Notes for this num_days_to_add adjustment.*/

SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;


IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH > 0 THEN 
    SET num_days_to_add = in_num_days_since - 1;
ELSE
    SET num_days_to_add = in_num_days_since;
END IF;
    

    
SET l_last_row_fetched=0;
OPEN c_account_pig_prod;   
    

loop_here: LOOP
    FETCH c_account_pig_prod INTO 
        cur_pig_prod_id,
        cur_pig_prod_date_actual_birth;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    INSERT INTO pig_prod_pig_ops(
        pig_prod_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        cur_pig_prod_id,
        in_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(cur_pig_prod_date_actual_birth, INTERVAL num_days_to_add DAY)
    );
    

END LOOP loop_here;
 
CLOSE c_account_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_delete_update_gilts $$
CREATE PROCEDURE account_pig_ops_delete_update_gilts(
    in_account_id           INT,
    
    in_account_pig_ops_id   INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;


/* pig_prod_pig_ops.flag bits*/
DECLARE FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED    INT             DEFAULT 1;


DECLARE cur_sow_id                              INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_gilts CURSOR FOR
    SELECT  id
    FROM    sow_boar
    WHERE   account_id      = in_account_id AND 
            sex = 'F'                       AND
            date_of_birth IS NOT NULL       AND
            sow_status_id   = SOW_STATUS_GROWING AND
            mate_count      = 0
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


    
SET l_last_row_fetched=0;
OPEN c_account_gilts;   
    

loop_here: LOOP
    FETCH c_account_gilts INTO 
        cur_sow_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        flag = flag | FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED
    WHERE sow_boar_id = cur_sow_id AND account_pig_ops_id = in_account_pig_ops_id;
    

END LOOP loop_here;
 
CLOSE c_account_gilts;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_delete_update_prod_lactating $$
CREATE PROCEDURE account_pig_ops_delete_update_prod_lactating(
    in_account_id           INT,
    
    in_account_pig_ops_id   INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;

/* pig_prod_pig_ops.flag bits*/
DECLARE FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED    INT             DEFAULT 1;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_prod CURSOR FOR
    SELECT  id,
            date_actual_birth
    FROM    pig_production
    WHERE   account_id      = in_account_id AND 
            prod_status_id  = PRODUCTION_STATUS_ID_LACTATING
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


    
SET l_last_row_fetched=0;
OPEN c_account_pig_prod;   
    

loop_here: LOOP
    FETCH c_account_pig_prod INTO 
        cur_pig_prod_id,
        cur_pig_prod_date_actual_birth;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        flag = flag | FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED
    WHERE pig_prod_id = cur_pig_prod_id AND account_pig_ops_id = in_account_pig_ops_id;


END LOOP loop_here;
 
CLOSE c_account_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_delete_update_prod_gestating $$
CREATE PROCEDURE account_pig_ops_delete_update_prod_gestating(
    in_account_id           INT,
    
    in_account_pig_ops_id   INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;


/* pig_prod_pig_ops.flag bits*/
DECLARE FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED    INT             DEFAULT 1;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_date_insemination          DATE            DEFAULT NULL;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_prod CURSOR FOR
    SELECT  id,
            date_insemination
    FROM    pig_production
    WHERE   account_id      = in_account_id AND 
            prod_status_id  = PRODUCTION_STATUS_ID_GESTATING
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


    
SET l_last_row_fetched=0;
OPEN c_account_pig_prod;   
    

loop_here: LOOP
    FETCH c_account_pig_prod INTO 
        cur_pig_prod_id,
        cur_pig_prod_date_insemination;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        flag = flag | FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED
    WHERE pig_prod_id = cur_pig_prod_id AND account_pig_ops_id = in_account_pig_ops_id;
    

END LOOP loop_here;
 
CLOSE c_account_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_delete_update_weaning_sows $$
CREATE PROCEDURE account_pig_ops_delete_update_weaning_sows(
    in_account_id           INT,
    
    in_account_pig_ops_id   INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE SOW_STATUS_WEANING                      INT             DEFAULT 4;


/* pig_prod_pig_ops.flag bits*/
DECLARE FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED    INT             DEFAULT 1;


DECLARE cur_sow_id                              INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_weaning_sows CURSOR FOR
    SELECT  a.id,
            b.date_weaning
    FROM    sow_boar a
    LEFT OUTER JOIN pig_production b ON a.last_pig_production_id = b.id
    WHERE   a.account_id      = in_account_id       AND 
            a.sex             = 'F'                 AND
            a.sow_status_id   = SOW_STATUS_WEANING  AND 
            b.date_weaning IS NOT NULL
            
    ORDER BY id ASC; 


DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


    
SET l_last_row_fetched=0;
OPEN c_account_weaning_sows;   
    

loop_here: LOOP
    FETCH c_account_weaning_sows INTO 
        cur_sow_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        flag = flag | FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED
    WHERE sow_boar_id = cur_sow_id AND account_pig_ops_id = in_account_pig_ops_id;
    

END LOOP loop_here;
 
CLOSE c_account_weaning_sows;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_delete $$
CREATE PROCEDURE account_pig_ops_delete(
    in_user_id              INT,
    
    in_account_pig_ops_id   INT
)  

BEGIN

/** 
 * Will delete account_pig_ops entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 21, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 10;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC     	INT             DEFAULT 2;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_pig_ops_account_id          INT             DEFAULT 0;
DECLARE cur_account_pig_ops_operation_type      INT             DEFAULT 0;
DECLARE cur_account_pig_ops_flag                INT             DEFAULT 0;
DECLARE cur_account_pig_ops_name                VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        operation_type
        
INTO    cur_account_pig_ops_account_id,
        cur_account_pig_ops_operation_type
FROM    account_pig_ops
WHERE   id = in_account_pig_ops_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_pig_ops_account_id, /* compare user.account_id to this account_id*/
    
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



UPDATE account_pig_ops SET
    flag                = flag | FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_account_pig_ops_id;


IF cur_account_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
    UPDATE account SET 
        ver_num_gestating_ops = ver_num_gestating_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
    
    
    CALL account_pig_ops_delete_update_prod_gestating(
        cur_user_account_id,
        in_account_pig_ops_id
    );
END IF;


IF  cur_account_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS  THEN 
    UPDATE account SET 
        ver_num_lactating_piglets_ops = ver_num_lactating_piglets_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
    
    
    CALL account_pig_ops_delete_update_prod_lactating(
        cur_user_account_id,
        in_account_pig_ops_id
    );
END IF;


IF  cur_account_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_SOW  THEN 
    UPDATE account SET 
        ver_num_lactating_sow_ops = ver_num_lactating_sow_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
    
    CALL account_pig_ops_delete_update_prod_lactating(
        cur_user_account_id,
        in_account_pig_ops_id
    );
END IF;


IF  cur_account_pig_ops_operation_type = PIG_OPERATION_TYPE_GILT_OPS  THEN 
    UPDATE account SET 
        ver_num_gilt_ops = ver_num_gilt_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
    
    CALL account_pig_ops_delete_update_gilts(
        cur_user_account_id,
        in_account_pig_ops_id
    );
END IF;


IF  cur_account_pig_ops_operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS  THEN 
    UPDATE account SET 
        ver_num_weaning_sow_ops = ver_num_weaning_sow_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
    
    CALL account_pig_ops_delete_update_weaning_sows(
        cur_user_account_id,
        in_account_pig_ops_id
    );
END IF;





END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_ops_flag,
    cur_account_pig_ops_name
FROM account_pig_ops
WHERE id = in_account_pig_ops_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_pig_ops_id               AS account_pig_ops_id,
    cur_account_pig_ops_flag            AS account_pig_ops_flag,
    cur_account_pig_ops_name            AS account_pig_ops_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_buyer_update $$
CREATE PROCEDURE account_pig_buyer_update(
    in_user_id              INT,
    
    in_account_pig_buyer_id INT,
    
    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5),
    
    in_is_boar_customer     INT,
    
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50),
    
    in_description          VARCHAR(160)
)  

BEGIN

/** 
 * Will add account_pig_buyer entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER       INT             DEFAULT 7;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* account_pig_buyer.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED   INT             DEFAULT 1;
DECLARE FLAG_BIT_PIG_BUYER_IS_BOAR_CUSTOMER     INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_pig_buyer_id                INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_account_id        INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_flag              INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_name              VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        flag

INTO    cur_account_pig_buyer_account_id,
        cur_account_pig_buyer_flag
        
FROM    account_pig_buyer
WHERE   id = in_account_pig_buyer_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_pig_buyer_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/*CLEAR FLAG_BIT_PIG_BUYER_IS_BOAR_CUSTOMER*/
SET cur_account_pig_buyer_flag = cur_account_pig_buyer_flag & ~FLAG_BIT_PIG_BUYER_IS_BOAR_CUSTOMER;

IF in_is_boar_customer > 0 THEN 
    SET cur_account_pig_buyer_flag = cur_account_pig_buyer_flag | FLAG_BIT_PIG_BUYER_IS_BOAR_CUSTOMER;
END IF;




UPDATE account_pig_buyer SET 
    country_id              = in_country_id,
    address_level_1_id      = in_address_level_1_id,
    address_level_2_id      = in_address_level_2_id,
    address_level_3_id      = in_address_level_3_id,
    
    flag                    = cur_account_pig_buyer_flag,
    
    name                    = in_name,    
    contact_number          = in_contact_number,
    whatsapp                = in_whatsapp,
    messenger               = in_messenger,
    
    description             = in_description,
    
    last_update_user_id     = in_user_id,
    dt_last_update          = CURRENT_TIMESTAMP
    
WHERE id =  in_account_pig_buyer_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_buyer_flag,
    cur_account_pig_buyer_name
FROM account_pig_buyer
WHERE id = cur_account_pig_buyer_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_pig_buyer_id            AS account_pig_buyer_id,
    cur_account_pig_buyer_flag          AS account_pig_buyer_flag,
    cur_account_pig_buyer_name          AS account_pig_buyer_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_buyer_delete $$
CREATE PROCEDURE account_pig_buyer_delete(
    in_user_id                  INT,
    
    in_account_pig_buyer_id     INT
)  

BEGIN

/** 
 * Will delete account_pig_buyer entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER      	INT             DEFAULT 12;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";

/* account_pig_buyer.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED   INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_pig_buyer_account_id        INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_flag              INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_name              VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_account_pig_buyer_account_id
FROM    account_pig_buyer
WHERE   id = in_account_pig_buyer_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_pig_buyer_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER,
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



UPDATE account_pig_buyer SET
    flag                = flag | FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_account_pig_buyer_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_buyer_flag,
    cur_account_pig_buyer_name
FROM account_pig_buyer
WHERE id = in_account_pig_buyer_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_pig_buyer_id             AS account_pig_buyer_id,
    cur_account_pig_buyer_flag          AS account_pig_buyer_flag,
    cur_account_pig_buyer_name          AS account_pig_buyer_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_buyer_add $$
CREATE PROCEDURE account_pig_buyer_add(
    in_user_id              INT,
    
    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5),
    
    in_is_boar_customer     INT,
    
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50),
    in_description          VARCHAR(160)
)  

BEGIN

/** 
 * Will add account_pig_buyer entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER       INT             DEFAULT 7;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* account_pig_buyer.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED   INT             DEFAULT 1;
DECLARE FLAG_BIT_PIG_BUYER_IS_BOAR_CUSTOMER     INT             DEFAULT 2;


DECLARE cur_user_account_check_id               INT             DEFAULT 0;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_pig_buyer_id                INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_flag              INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_name              VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_user_account_check_id
FROM    user
WHERE   id = in_user_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_user_account_check_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER,
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


/* Check for duplicate entry */
SELECT  id
INTO    cur_account_pig_buyer_id
FROM    account_pig_buyer
WHERE   account_id          = cur_user_account_id AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_account_pig_buyer_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


SET cur_account_pig_buyer_flag  = 0;
IF in_is_boar_customer > 0 THEN
    SET cur_account_pig_buyer_flag  = FLAG_BIT_PIG_BUYER_IS_BOAR_CUSTOMER;
END IF;

INSERT INTO account_pig_buyer(
    account_id,
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    latitude,
    longitude,
    
    flag, 
    
    name,
    
    contact_number,
    whatsapp,
    messenger,
    
    description,
    
    added_by_user_id
    
) VALUES (
    cur_user_account_id,
    in_country_id,
    in_address_level_1_id,
    in_address_level_2_id,
    in_address_level_3_id,
    
    in_latitude,
    in_longitude,
    
    
    cur_account_pig_buyer_flag,
   
    in_name,
   
    in_contact_number,
    in_whatsapp,
    in_messenger,
    
    in_description,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_pig_buyer_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_buyer_flag,
    cur_account_pig_buyer_name
FROM account_pig_buyer
WHERE id = cur_account_pig_buyer_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_pig_buyer_id            AS account_pig_buyer_id,
    cur_account_pig_buyer_flag          AS account_pig_buyer_flag,
    cur_account_pig_buyer_name          AS account_pig_buyer_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS feed_buy_update $$
CREATE PROCEDURE feed_buy_update(
    in_user_id              INT,
    in_feed_buy_id          INT,
    
    in_date_buy             VARCHAR(10),
    in_feed_type_id         INT,
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    in_quantity             INT,
    in_kg_per_unit          DECIMAL(5,1),
    
    in_unit_cost            DECIMAL(8,2),
    in_total_cost           DECIMAL(8,2)
)  

BEGIN

/** 
 * Will update feed_buy entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 31, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_feed_buy_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_feed_buy_pig_prod_id                INT             DEFAULT 0;
DECLARE cur_feed_buy_pig_prod_group_id          INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_feed_quantity_lactating             INT             DEFAULT 0;
DECLARE cur_feed_quantity_booster               INT             DEFAULT 0;
DECLARE cur_feed_quantity_prestarter            INT             DEFAULT 0;
DECLARE cur_feed_quantity_starter               INT             DEFAULT 0;
DECLARE cur_feed_quantity_grower                INT             DEFAULT 0;
DECLARE cur_feed_quantity_finisher              INT             DEFAULT 0;


DECLARE cur_feed_weight_kg_lactating            INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_booster              INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_prestarter           INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_starter              INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_grower               INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_finisher             INT             DEFAULT 0;




DECLARE cur_total_cost_lactating                 DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_total_cost_booster                   DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_total_cost_prestarter                DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_total_cost_starter                   DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_total_cost_grower                    DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_total_cost_finisher                  DECIMAL(8,2)    DEFAULT 0;


DECLARE cur_feed_buy_id                         INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT 
    pig_farm_id,
    pig_prod_id,
    pig_prod_group_id
INTO 
    cur_feed_buy_pig_farm_id,
    cur_feed_buy_pig_prod_id,
    cur_feed_buy_pig_prod_group_id
FROM feed_buy
WHERE id = in_feed_buy_id;


IF cur_feed_buy_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production  
    WHERE id = cur_feed_buy_pig_prod_id;

ELSE

    IF cur_feed_buy_pig_prod_group_id > 0 THEN 
        SELECT 
            account_id,
            prod_status_id

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM production_group  
        WHERE id = cur_feed_buy_pig_prod_group_id;
    
    ELSE
        SELECT 
            account_id,
            1

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM pig_farm 
        WHERE id = in_pig_farm_id;
    
    END IF;
END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


UPDATE feed_buy  SET
    date_buy            = in_date_buy,
    
    feed_type_id        = in_feed_type_id,
    feed_brand_id       = in_feed_brand_id,
    feed_supplier_id    = in_feed_supplier_id,
    
    quantity            = in_quantity,
    kg_per_unit         = in_kg_per_unit,
    kg_total            = in_quantity * in_kg_per_unit,
    
    unit_cost           = in_unit_cost,
    total_cost          = in_total_cost,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_feed_buy_id;



/* It is difficult to know which feed is updated; so update all;*/
IF cur_feed_buy_pig_prod_id > 0 THEN 
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_lactating,
            cur_feed_weight_kg_lactating,
            cur_total_cost_lactating
    FROM    feed_buy
    WHERE   pig_prod_id     = cur_feed_buy_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_LACTATING;
        
        
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_booster,
            cur_feed_weight_kg_booster,
            cur_total_cost_booster
    FROM    feed_buy
    WHERE   pig_prod_id     = cur_feed_buy_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_BOOSTER;
        
        
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_prestarter,
            cur_feed_weight_kg_prestarter,
            cur_total_cost_prestarter
    FROM    feed_buy
    WHERE   pig_prod_id     = cur_feed_buy_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_PRESTARTER;
        

    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_starter,
            cur_feed_weight_kg_starter,
            cur_total_cost_starter
    FROM    feed_buy
    WHERE   pig_prod_id     = cur_feed_buy_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_STARTER;


    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_grower,
            cur_feed_weight_kg_grower,
            cur_total_cost_grower
    FROM    feed_buy
    WHERE   pig_prod_id     = cur_feed_buy_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_GROWER;


    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_finisher,
            cur_feed_weight_kg_finisher,
            cur_total_cost_finisher
    FROM    feed_buy
    WHERE   pig_prod_id     = cur_feed_buy_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_FINISHER;

    
    /* Convert zero values to NULL*/
    IF cur_feed_quantity_lactating = 0 THEN 
        SET cur_feed_quantity_lactating     = NULL;
        SET cur_feed_weight_kg_lactating    = NULL;
        SET cur_total_cost_lactating        = NULL;
    END IF;
    
    IF cur_feed_quantity_booster = 0 THEN 
        SET cur_feed_quantity_booster       = NULL;
        SET cur_feed_weight_kg_booster      = NULL;
        SET cur_total_cost_booster          = NULL;
    END IF;
    
    IF cur_feed_quantity_prestarter = 0 THEN 
        SET cur_feed_quantity_prestarter    = NULL;
        SET cur_feed_weight_kg_prestarter   = NULL;
        SET cur_total_cost_prestarter       = NULL; 
    END IF;
    
    IF cur_feed_quantity_starter = 0 THEN 
        SET cur_feed_quantity_starter       = NULL;
        SET cur_feed_weight_kg_starter      = NULL;
        SET cur_total_cost_starter          = NULL;
    END IF;
    
    IF cur_feed_quantity_grower = 0 THEN 
        SET cur_feed_quantity_grower        = NULL;
        SET cur_feed_weight_kg_grower       = NULL;
        SET cur_total_cost_grower           = NULL;
    END IF;
    
    IF cur_feed_quantity_finisher = 0 THEN 
        SET cur_feed_quantity_finisher      = NULL;
        SET cur_feed_weight_kg_finisher     = NULL;
        SET cur_total_cost_finisher         = NULL;
    END IF;
    
        
    UPDATE pig_production SET 
        num_b_lactating     = cur_feed_quantity_lactating,
        num_b_booster       = cur_feed_quantity_booster,
        num_b_prestarter    = cur_feed_quantity_prestarter,
        num_b_starter       = cur_feed_quantity_starter,
        num_b_grower        = cur_feed_quantity_grower,
        num_b_finisher      = cur_feed_quantity_finisher,
        
        
        num_b_kg_lactating  = cur_feed_weight_kg_lactating,
        num_b_kg_booster    = cur_feed_weight_kg_booster,
        num_b_kg_prestarter = cur_feed_weight_kg_prestarter,
        num_b_kg_starter    = cur_feed_weight_kg_starter,
        num_b_kg_grower     = cur_feed_weight_kg_grower,
        num_b_kg_finisher   = cur_feed_weight_kg_finisher,
        
        
        cost_lactating      = cur_total_cost_lactating,
        cost_booster        = cur_total_cost_booster,
        cost_prestarter     = cur_total_cost_prestarter,
        cost_starter        = cur_total_cost_starter,
        cost_grower         = cur_total_cost_grower,
        cost_finisher       = cur_total_cost_finisher,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP
    WHERE id = cur_feed_buy_pig_prod_id;

END IF;




IF cur_feed_buy_pig_prod_group_id > 0 THEN 

    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_lactating,
            cur_total_cost_lactating
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_LACTATING;
        
        
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_booster,
            cur_total_cost_booster
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_BOOSTER;
        
        
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_prestarter,
            cur_total_cost_prestarter
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_PRESTARTER;
        

    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_starter,
            cur_total_cost_starter
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_STARTER;


    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_grower,
            cur_total_cost_grower
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_GROWER;


    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_finisher,
            cur_total_cost_finisher
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_FINISHER;

        
        
    UPDATE production_group SET 
        num_b_lactating     = cur_feed_quantity_lactating,
        num_b_booster       = cur_feed_quantity_booster,
        num_b_prestarter    = cur_feed_quantity_prestarter,
        num_b_starter       = cur_feed_quantity_starter,
        num_b_grower        = cur_feed_quantity_grower,
        num_b_finisher      = cur_feed_quantity_finisher,
        
        cost_lactating      = cur_total_cost_lactating,
        cost_booster        = cur_total_cost_booster,
        cost_prestarter     = cur_total_cost_prestarter,
        cost_starter        = cur_total_cost_starter,
        cost_grower         = cur_total_cost_grower,
        cost_finisher       = cur_total_cost_finisher,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP
    WHERE id = in_pig_prod_group_id;


END IF;



IF cur_feed_buy_pig_farm_id > 0 THEN 
    UPDATE pig_farm SET
        data_ver_num_feed_buy = data_ver_num_feed_buy + 1
    WHERE id = cur_feed_buy_pig_farm_id; 
END IF;


IF cur_feed_buy_pig_prod_id > 0 THEN 
    UPDATE pig_production SET
        data_ver_num_prod_feed = data_ver_num_prod_feed + 1
    WHERE id = cur_feed_buy_pig_prod_id;
END IF;

 
IF cur_feed_buy_pig_prod_group_id > 0 THEN 
    UPDATE pig_production SET
        data_ver_num_prod_feed = data_ver_num_prod_feed + 1
    WHERE id = cur_feed_buy_pig_prod_group_id;
END IF;




END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_feed_buy_id                      AS feed_buy_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS feed_buy_add $$
CREATE PROCEDURE feed_buy_add(
    in_user_id              INT,
    
    in_pig_farm_id          INT,
    in_pig_prod_id          INT,
    in_prod_group_id        INT,
    
    in_date_buy             VARCHAR(10),
    in_feed_type_id         INT,
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    in_quantity             INT,
    in_kg_per_unit          DECIMAL(5,1),
    
    in_unit_cost            DECIMAL(8,2),
    in_total_cost           DECIMAL(8,2)
)  

BEGIN

/** 
 * Will add feed_buy entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 31, 2025
 *
 */

/** 
20260214 Notes
1.) As of this writing the feed_buy is created like this.


CREATE TABLE `feed_buy` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pig_farm_id` int(11) DEFAULT NULL,
  `pig_prod_id` int(11) DEFAULT NULL,
  `pig_prod_group_id` int(11) DEFAULT NULL,
  `date_buy` date DEFAULT NULL,
  `feed_type_id` int(11) DEFAULT NULL,
  `feed_brand_id` int(11) DEFAULT NULL,
  `feed_supplier_id` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `kg_per_unit` decimal(5,1) DEFAULT NULL,
  `kg_total` decimal(6,1) DEFAULT NULL,
  `unit_cost` decimal(8,2) DEFAULT NULL,
  `total_cost` decimal(8,2) DEFAULT NULL,
  `added_by_user_id` int(11) DEFAULT NULL,
  `last_update_user_id` int(11) DEFAULT NULL,
  `dt_last_update` datetime DEFAULT NULL,
  `dt_entry` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `INDEX_PIG_FARM_ID` (`pig_farm_id`),
  KEY `INDEX_PIG_PROD_ID` (`pig_prod_id`),
  KEY `INDEX_PIG_PROD_GROUP_ID` (`pig_prod_group_id`)
) ENGINE=InnoDB



2.) Two additional tables will be created in addition to feed_buy.

CREATE TABLE `pig_prod_feed` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pig_prod_id` int(10) unsigned NOT NULL DEFAULT 0,
  `date_add` date DEFAULT NULL,
  `added_by_user_id` int(11) DEFAULT NULL,
  `last_update_user_id` int(11) DEFAULT NULL,
  `dt_last_update` datetime DEFAULT NULL,
  `dt_entry` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `INDEX_PIG_PROD_ID` (`pig_prod_id`)
) ENGINE=InnoDB


CREATE TABLE `pig_farm_feed_buy` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int(10) unsigned NOT NULL DEFAULT 0,
  `pig_farm_id` int(10) unsigned DEFAULT NULL,
  `date_buy` date DEFAULT NULL,
  `feed_supplier_id` int(11) DEFAULT NULL,
  `total_feed_cost` decimal(10,2) DEFAULT NULL,
  `other_cost` decimal(8,2) DEFAULT NULL,
  `added_by_user_id` int(11) DEFAULT NULL,
  `last_update_user_id` int(11) DEFAULT NULL,
  `dt_last_update` datetime DEFAULT NULL,
  `dt_entry` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `INDEX_PIG_FARM` (`pig_farm_id`)
) ENGINE=InnoDB


And the feed_buy table will add two additional keys


ALTER TABLE feed_buy ADD COLUMN pig_prod_feed_id  INT UNSIGNED 
AFTER pig_prod_group_id;


ALTER TABLE feed_buy ADD COLUMN pig_farm_feed_buy_id  INT UNSIGNED 
AFTER pig_prod_group_id;


The feed_buy will look like this now:

CREATE TABLE `feed_buy` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pig_farm_id` int(11) DEFAULT NULL,
  `pig_prod_id` int(11) DEFAULT NULL,
  `pig_prod_group_id` int(11) DEFAULT NULL,
  `pig_prod_feed_id` int(10) unsigned DEFAULT NULL,
  `pig_farm_feed_buy_id` int(10) unsigned DEFAULT NULL,
  `flag` int(10) unsigned DEFAULT NULL,
  `date_buy` date DEFAULT NULL,
  `feed_type_id` int(11) DEFAULT NULL,
  `feed_brand_id` int(11) DEFAULT NULL,
  `feed_supplier_id` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `kg_per_unit` decimal(5,1) DEFAULT NULL,
  `kg_total` decimal(6,1) DEFAULT NULL,
  `unit_cost` decimal(8,2) DEFAULT NULL,
  `total_cost` decimal(8,2) DEFAULT NULL,
  `added_by_user_id` int(11) DEFAULT NULL,
  `last_update_user_id` int(11) DEFAULT NULL,
  `dt_last_update` datetime DEFAULT NULL,
  `dt_entry` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `INDEX_PIG_FARM_ID` (`pig_farm_id`),
  KEY `INDEX_PIG_PROD_ID` (`pig_prod_id`),
  KEY `INDEX_PIG_PROD_GROUP_ID` (`pig_prod_group_id`),
  KEY `INDEX_PIG_PROD_FEED_ID` (`pig_prod_feed_id`),
  KEY `INDEX_PIG_FARM_FEED_BUY_ID` (`pig_farm_feed_buy_id`)
) ENGINE=InnoDB


4.) In feed_buy, the feed items per pig_production are directly saved,
and the remainder of the non-production feeds are save in pig_farm_id keys;

This is time consuming at the user side because it needs to populate
the feed_item details per pig_production.

5.) In actual pig_operations, the feeds are bought at the pig_farm level not at 
pig_production level. Then the feeds are distributed to pig_production 
and the remainder are for gestating sows and boars. The adding of feeds to 
feed production can be done by farm_staff and no need to input the details of 
feed_items like the unit_price, unit_weight, feed_brand or feed_supplier.


6.) This buying of feeds at the pig_farm level and distributing to pig_production
is abstracted using pig_farm_feed_buy table and the feed_item details
is still will be saved in feed_buy table but relating to key pig_farm_feed_buy_id;


7.) The distribution of feeds to pig_production is saved at pig_prod_feed table;
and the feed items distributed to pig_production will still be saved in feed_buy 
buy using key pig_prod_feed_id;


In this way there is little change in the feed_buy table and still recycled.




*/



DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_FEED_BUY  INT        DEFAULT 20;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

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


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


/* feed_brand.flag bits*/
DECLARE FLAG_BIT_FEED_BRAND_IS_DELETED          INT             DEFAULT 1;
DECLARE FLAG_BIT_FEED_BRAND_IS_VERIFIED         INT             DEFAULT 2;


/* feed_supplier.flag bits*/
DECLARE FLAG_BIT_FEED_SUPPLIER_IS_DELETED       INT             DEFAULT 1;
DECLARE FLAG_BIT_FEED_SUPPLIER_IS_VERIFIED      INT             DEFAULT 2;


DECLARE MIN_COUNT_ACCOUNT_FEED_BRAND_IS_VERIFIED    INT         DEFAULT 3;
DECLARE MIN_COUNT_ACCOUNT_FEED_SUPPLIER_IS_VERIFIED INT         DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_feed_quantity                       INT             DEFAULT 0;
DECLARE cur_feed_weight_kg                      INT             DEFAULT 0;
DECLARE cur_total_cost                          DECIMAL(8,2)    DEFAULT 0;


DECLARE cur_feed_quantity_b4                    INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_b4                   INT             DEFAULT 0;
DECLARE cur_total_cost_b4                       DECIMAL(8,2)    DEFAULT 0;




DECLARE cur_feed_buy_id                         INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production 
    WHERE id = in_pig_prod_id;

ELSE 
    IF in_prod_group_id > 0 THEN 
        SELECT 
            account_id,
            prod_status_id

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM production_group 
        WHERE id = in_prod_group_id;
        
    ELSE
        SELECT 
            account_id,
            1

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM pig_farm 
        WHERE id = in_pig_farm_id;
    END IF;

END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
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
        SET res_num     = RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_FEED_BUY;
        SET res_code    = "RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_FEED_BUY";
        
        LEAVE process_user;
    END IF;
END IF;


/* Check for duplicate entry */
IF in_pig_prod_id > 0 THEN 
    SELECT  id
    INTO    cur_feed_buy_id
    FROM    feed_buy
    WHERE   pig_prod_id         = in_pig_prod_id    AND
            date_buy            = in_date_buy       AND
            feed_type_id        = in_feed_type_id   AND 
            feed_supplier_id    = in_feed_supplier_id
    LIMIT   1;
    
ELSE 

    IF in_prod_group_id > 0 THEN 
        SELECT  id
        INTO    cur_feed_buy_id
        FROM    feed_buy
        WHERE   pig_prod_group_id   = in_prod_group_id  AND
                date_buy            = in_date_buy       AND
                feed_type_id        = in_feed_type_id   AND 
                feed_supplier_id    = in_feed_supplier_id
        LIMIT   1;

    ELSE
        SELECT  id
        INTO    cur_feed_buy_id
        FROM    feed_buy
        WHERE   pig_farm_id         = in_pig_farm_id  AND
                date_buy            = in_date_buy     AND
                feed_type_id        = in_feed_type_id AND 
                feed_supplier_id    = in_feed_supplier_id
        LIMIT   1;
    END IF;
    
END IF;

IF cur_feed_buy_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO feed_buy(
    pig_farm_id,
    pig_prod_id,
    pig_prod_group_id,
    
    date_buy,
    
    feed_type_id,
    feed_brand_id,
    feed_supplier_id,
    
    quantity,
    kg_per_unit,
    kg_total,
    
    unit_cost,
    total_cost,
    
    added_by_user_id

) VALUES (
    in_pig_farm_id,
    in_pig_prod_id,
    in_prod_group_id,
    
    in_date_buy,
    
    in_feed_type_id,
    in_feed_brand_id,
    in_feed_supplier_id,
    
    in_quantity,
    in_kg_per_unit,
    in_quantity * in_kg_per_unit,
    
    in_unit_cost,
    in_total_cost,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_buy_id;


IF in_pig_prod_id > 0 THEN
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity,
            cur_feed_weight_kg,
            cur_total_cost
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = in_feed_type_id;

    
    IF in_feed_type_id = FEED_TYPE_ID_GESTATING THEN
        UPDATE pig_production SET 
            num_b_gestating     = cur_feed_quantity,
            num_b_kg_gestating  = cur_feed_weight_kg,
            cost_gestating      = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;


    IF in_feed_type_id = FEED_TYPE_ID_LACTATING THEN
        UPDATE pig_production SET 
            num_b_lactating     = cur_feed_quantity,
            num_b_kg_lactating  = cur_feed_weight_kg,
            cost_lactating      = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;

    
    IF in_feed_type_id = FEED_TYPE_ID_BOOSTER THEN
        UPDATE pig_production SET 
            num_b_booster       = cur_feed_quantity,
            num_b_kg_booster    = cur_feed_weight_kg,
            cost_booster        = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;

    
    IF in_feed_type_id = FEED_TYPE_ID_PRESTARTER THEN 
        UPDATE pig_production SET 
            num_b_prestarter    = cur_feed_quantity,
            num_b_kg_prestarter = cur_feed_weight_kg,
            cost_prestarter     = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_STARTER THEN 
        UPDATE pig_production SET 
            num_b_starter       = cur_feed_quantity,
            num_b_kg_starter    = cur_feed_weight_kg,
            cost_starter        = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 
         UPDATE pig_production SET 
            num_b_grower        = cur_feed_quantity,
            num_b_kg_grower     = cur_feed_weight_kg,
            cost_grower         = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_FINISHER THEN 
        UPDATE pig_production SET 
            num_b_finisher      = cur_feed_quantity,
            num_b_kg_finisher   = cur_feed_weight_kg,
            cost_finisher       = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;
    
END IF;



IF in_prod_group_id > 0 THEN 

    /* Sum for the group.*/   
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity,
            cur_feed_weight_kg,
            cur_total_cost
    FROM    feed_buy
    WHERE   pig_prod_group_id = in_prod_group_id AND feed_type_id = in_feed_type_id;
        
    
    /* Sum for for each pig prod when not yet in group.*/
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_b4,
            cur_feed_weight_kg_b4,
            cur_total_cost_b4
    FROM    feed_buy
    WHERE   pig_prod_id IN (SELECT pig_prod_id 
                            FROM production_group_pig_prod 
                            WHERE production_group_id = in_prod_group_id) AND feed_type_id = in_feed_type_id;
    
        
    IF in_feed_type_id = FEED_TYPE_ID_LACTATING THEN
        UPDATE pig_production SET 
            num_b_lactating     = cur_feed_quantity,
            num_b_kg_lactating  = cur_feed_weight_kg,
            cost_lactating      = cur_total_cost
        WHERE id = in_prod_group_id;        
    END IF;

    
    IF in_feed_type_id = FEED_TYPE_ID_BOOSTER THEN
        UPDATE pig_production SET 
            num_b_booster       = cur_feed_quantity,
            num_b_kg_booster    = cur_feed_weight_kg,
            cost_booster        = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;

    
    IF in_feed_type_id = FEED_TYPE_ID_PRESTARTER THEN 
        UPDATE pig_production SET 
            num_b_prestarter    = cur_feed_quantity,
            num_b_kg_prestarter = cur_feed_weight_kg,
            cost_prestarter     = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_STARTER THEN 
        UPDATE production_group SET 
            num_b_starter       = cur_feed_quantity,
            num_b_kg_starter    = cur_feed_weight_kg,
            cost_starter        = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 
         UPDATE pig_production SET 
            num_b_grower        = cur_feed_quantity,
            num_b_kg_grower     = cur_feed_weight_kg,
            cost_grower         = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 
         UPDATE pig_production SET 
            num_b_grower        = cur_feed_quantity,
            num_b_kg_grower     = cur_feed_weight_kg,
            cost_grower         = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_FINISHER THEN 
        UPDATE pig_production SET 
            num_b_finisher      = cur_feed_quantity,
            num_b_kg_finisher   = cur_feed_weight_kg,
            cost_finisher       = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;
    

END IF;




/* Nothing to do yet if added by pig_farm_id*/

/* Insert INTO account_selection*/
SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_pig_prod_account_id AND 
        feed_brand_id = in_feed_brand_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        feed_brand_id
    ) VALUES (
        cur_pig_prod_account_id,
        in_feed_brand_id
    );
END IF;


SET cur_count = 0;

SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_pig_prod_account_id AND 
        feed_supplier_id = in_feed_supplier_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        feed_supplier_id
    ) VALUES (
        cur_pig_prod_account_id,
        in_feed_supplier_id
    );
END IF;


/* Update feed_brand counter. */
SELECT  COUNT(*)
INTO    cur_count
FROM    account_selection
WHERE   feed_brand_id = in_feed_brand_id;

UPDATE  feed_brand SET
    account_counter = cur_count
WHERE id = in_feed_brand_id;


/* Update feed_brand.flag.FLAG_BIT_FEED_BRAND_IS_VERIFIED*/
IF cur_count >= MIN_COUNT_ACCOUNT_FEED_BRAND_IS_VERIFIED THEN 
    UPDATE feed_brand SET
        flag = flag | FLAG_BIT_FEED_BRAND_IS_VERIFIED
    WHERE id = in_feed_brand_id;

END IF;


/* Update feed_supplier counter*/
SELECT  COUNT(*)
INTO    cur_count
FROM    account_selection
WHERE   feed_supplier_id = in_feed_supplier_id;

UPDATE  feed_supplier SET
    account_counter = cur_count
WHERE id = in_feed_supplier_id;


/* Update feed_supplier.flag.FLAG_BIT_FEED_SUPLIER_IS_VERIFIED*/
IF cur_count >= MIN_COUNT_ACCOUNT_FEED_SUPPLIER_IS_VERIFIED THEN 
    UPDATE feed_supplier SET
        flag = flag | FLAG_BIT_FEED_SUPPLIER_IS_VERIFIED
    WHERE id = in_feed_supplier_id;

END IF;


IF in_pig_farm_id > 0 THEN 
    UPDATE pig_farm SET
        data_ver_num_feed_buy = data_ver_num_feed_buy + 1
    WHERE id = in_pig_farm_id; 
END IF;


IF in_pig_prod_id > 0 THEN 
    UPDATE pig_production SET
        data_ver_num_prod_feed = data_ver_num_prod_feed + 1
    WHERE id = in_pig_prod_id;
END IF;

 
IF in_prod_group_id > 0 THEN 
    UPDATE pig_production SET
        data_ver_num_prod_feed = data_ver_num_prod_feed + 1
    WHERE id = in_pig_prod_id;
END IF;





END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_buy_id                     AS feed_buy_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS public_report_add $$
CREATE PROCEDURE public_report_add(
    in_user_id              INT,

    in_supplier_id          INT,
    in_report_type          INT,
    
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will add public_report entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_report_id                           INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    0, /* public business object*/
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* Check for duplicate entry */

/* Allow duplicates as there are no keys to duplicate check*/


INSERT INTO public_report(
    supplier_id,
    report_type_id,
    
    notes,
    added_by_user_id
    
) VALUES (
    in_supplier_id,
    in_report_type_id,
    
    in_notes,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_report_id;



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_report_id                       AS report_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS common_supplier_add $$
CREATE PROCEDURE common_supplier_add(
    in_user_id              INT,

    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_is_feed_supplier     INT,
    in_is_gilt_supplier     INT,
    in_is_semen_supplier   	INT,
    
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5),
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will add common_supplier entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 21, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD                      INT             DEFAULT 21;



/* common_supplier.flag bits*/
DECLARE FLAG_BIT_COMMON_SUPPLIER_IS_DELETED      INT            DEFAULT 1;
DECLARE FLAG_BIT_COMMON_SUPPLIER_IS_VERIFIED     INT            DEFAULT 2;


DECLARE MAX_UNVERIFIED_ENTRIES_PER_USER         INT             DEFAULT 3;
DECLARE MAX_DELETED_INVALID_ENTRIES_PER_USER    INT             DEFAULT 3;


DECLARE USER_AUDIT_ACTION_ADD                   VARCHAR(3)      DEFAULT 'ADD';
DECLARE USER_AUDIT_ACTION_UPDATE                VARCHAR(3)      DEFAULT 'UPD';
DECLARE USER_AUDIT_ACTION_DELETE                VARCHAR(3)      DEFAULT 'DEL';




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_common_supplier_id                  INT             DEFAULT 0;
DECLARE cur_common_supplier_flag                INT             DEFAULT 0;
DECLARE cur_common_supplier_name                VARCHAR(50)     DEFAULT '';

DECLARE in_name_upper                           VARCHAR(50)     DEFAULT '';

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
    
    0, /* public business object*/
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* All public object names are in UPPER case. Except address names.*/
SET in_name_upper = UPPER(in_name);


/* Check for duplicate entry */
IF in_address_level_3_id IS NULL THEN  
    SELECT  id
    INTO    cur_common_supplier_id
    FROM    common_supplier
    WHERE   country_id          = in_country_id             AND
            address_level_1_id  = in_address_level_1_id     AND
            address_level_2_id  = in_address_level_2_id     AND
            flag & FLAG_BIT_COMMON_SUPPLIER_IS_DELETED = 0  AND 
            UPPER(name)         = in_name_upper
    LIMIT   1;
ELSE
    SELECT  id
    INTO    cur_common_supplier_id
    FROM    common_supplier
    WHERE   country_id          = in_country_id             AND
            address_level_1_id  = in_address_level_1_id     AND
            address_level_2_id  = in_address_level_2_id     AND
            address_level_3_id  = in_address_level_3_id     AND
            flag & FLAG_BIT_COMMON_SUPPLIER_IS_DELETED = 0  AND 
            UPPER(name)         = in_name_upper
    LIMIT   1;
END IF;

IF cur_common_supplier_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* common_supplier can be added by any user. To prevent abuse of entering
invalid common_supplier, unverified entries will be counted and 
deleted entries against the user wil be counted.*/

SELECT  COUNT(*)
INTO    cur_count
FROM    common_supplier
WHERE   added_by_user_id = in_user_id AND 
        (flag & 3) = 0;

IF cur_count >= MAX_UNVERIFIED_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many unverified entries entered by user.";
    
    LEAVE process_user;

END IF;


SELECT  COUNT(*) 
INTO    cur_count
FROM    common_supplier
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_COMMON_SUPPLIER_IS_DELETED) > 0 AND 
        deleted_by_user_id IS NOT NULL AND 
        deleted_by_user_id != in_user_id; 
        
IF cur_count >= MAX_DELETED_INVALID_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many invalid entries entered by user.";
    
    LEAVE process_user;

END IF;




INSERT INTO common_supplier(
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    is_feed_supplier,
    is_gilt_supplier,
    is_semen_supplier,
    
    latitude,
    longitude,
    
    name,
    contact_number,
    whatsapp,
    messenger,
    
    added_by_user_id
    
) VALUES (
   in_country_id,
   in_address_level_1_id,
   in_address_level_2_id,
   in_address_level_3_id,
   
   in_is_feed_supplier,
   in_is_gilt_supplier,
   in_is_semen_supplier,
   
   in_latitude,
   in_longitude,
   
   in_name_upper,
   in_contact_number,
   in_whatsapp,
   in_messenger,
   
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_common_supplier_id;



/* Insert into account_selection.*/

SET cur_count = 0;
IF in_is_feed_supplier > 0 THEN
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id =  cur_user_account_id AND 
            feed_supplier_id = cur_common_supplier_id;
            

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            feed_supplier_id
        ) VALUES (
            cur_user_account_id,
            cur_common_supplier_id
        );
    END IF;
END IF;


SET cur_count = 0;
IF in_is_gilt_supplier > 0 THEN
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id =  cur_user_account_id AND 
            gilt_supplier_id = cur_common_supplier_id;
            

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            gilt_supplier_id
        ) VALUES (
            cur_user_account_id,
            cur_common_supplier_id
        );
    END IF;
END IF;


SET cur_count = 0;
IF in_is_semen_supplier > 0 THEN
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id =  cur_user_account_id AND 
            semen_supplier_id = cur_common_supplier_id;
            

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            semen_supplier_id
        ) VALUES (
            cur_user_account_id,
            cur_common_supplier_id
        );
    END IF;
END IF;



/* Add user audit trail, since this is a public record to easily identify
who changes what. */
INSERT INTO common_supplier_audit(
    common_supplier_id,
    audit_user_id,
    audit_action,

    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    is_feed_supplier,
    is_gilt_supplier,
    is_semen_supplier,
    
    latitude,
    longitude,
    
    name,
    contact_number,
    whatsapp,
    messenger
    
) VALUES (
    cur_common_supplier_id,
    in_user_id,
    USER_AUDIT_ACTION_ADD,

    in_country_id,
    in_address_level_1_id,
    in_address_level_2_id,
    in_address_level_3_id,
    
    in_is_feed_supplier,
    in_is_gilt_supplier,
    in_is_semen_supplier,

    in_latitude,
    in_longitude,

    in_name_upper,
    in_contact_number,
    in_whatsapp,
    in_messenger
);



END process_user;


SELECT
    flag,
    name
INTO 
    cur_common_supplier_flag,
    cur_common_supplier_name
FROM common_supplier
WHERE id = cur_common_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_common_supplier_id              AS common_supplier_id,
    cur_common_supplier_flag            AS common_supplier_flag,
    cur_common_supplier_name            AS common_supplier_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS common_supplier_update $$
CREATE PROCEDURE common_supplier_update(
    in_user_id              INT,
    
    in_common_supplier_id   INT, 
    
    in_address_level_3_id   INT,
    
    in_is_feed_supplier     INT,
    in_is_gilt_supplier     INT,
    in_is_semen_supplier    INT,
    
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5),

    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will update common_supplier entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;

DECLARE RES_NUM_NOT_ALLOWED_TO_UPDATE           INT             DEFAULT 21;



/* common_supplier.flag bits*/
DECLARE FLAG_BIT_COMMON_SUPPLIER_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_COMMON_SUPPLIER_IS_VERIFIED    INT             DEFAULT 2;


/* user.flag bits*/
DECLARE FLAG_BIT_SYSTEM_SUPER_USER              INT             DEFAULT 131072;

DECLARE USER_AUDIT_ACTION_ADD                   VARCHAR(3)      DEFAULT 'ADD';
DECLARE USER_AUDIT_ACTION_UPDATE                VARCHAR(3)      DEFAULT 'UPD';
DECLARE USER_AUDIT_ACTION_DELETE                VARCHAR(3)      DEFAULT 'DEL';


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


DECLARE cur_added_by_user_id                    INT             DEFAULT 0;
DECLARE cur_user_orig_account_id                INT             DEFAULT 0;


DECLARE in_name_upper                           VARCHAR(50)     DEFAULT '';


DECLARE cur_common_supplier_id                  INT             DEFAULT 0;
DECLARE cur_common_supplier_country_id          INT             DEFAULT 0;
DECLARE cur_common_supplier_address_level_1_id  INT             DEFAULT 0;
DECLARE cur_common_supplier_address_level_2_id  INT             DEFAULT 0;
DECLARE cur_common_supplier_address_level_3_id  INT             DEFAULT 0;
DECLARE cur_common_supplier_is_feed_supplier    INT             DEFAULT 0;
DECLARE cur_common_supplier_is_gilt_supplier    INT             DEFAULT 0;
DECLARE cur_common_supplier_is_semen_supplier   INT             DEFAULT 0;
DECLARE cur_common_supplier_latitude            DECIMAL(10,5)   DEFAULT NULL;
DECLARE cur_common_supplier_longitude           DECIMAL(10,5)   DEFAULT NULL;



DECLARE cur_common_supplier_flag                INT             DEFAULT 0;
DECLARE cur_common_supplier_name                VARCHAR(50)     DEFAULT '';
DECLARE cur_common_supplier_contact_number      VARCHAR(20)     DEFAULT NULL;
DECLARE cur_common_supplier_whatsapp            VARCHAR(20)     DEFAULT NULL;
DECLARE cur_common_supplier_messenger           VARCHAR(50)     DEFAULT NULL;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    0, /* public business object*/
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/*
2026-01-24 Notes:
1.) The supplier flags 

is_feed_supplier,
is_gilt_supplier,
is_semen_supplier,


can be SET by any user;

TODO: still thinking the restrictions who can CLEAR the flags.


2.) The supplier name is editable only by the account owner  
of the user who created it. This is to prevent abuse as this is a public data.

3.) The address level_3_id is editable by any account owner who has a 
account_selection of this supplier.

This action difers from the supplier_flag update since 

 

*/


/* Read updatable data entered by user before update*/
SELECT  country_id,
        address_level_1_id,
        address_level_2_id,
        address_level_3_id,
        
        is_feed_supplier,
        is_gilt_supplier,
        is_semen_supplier,
        
        latitude,
        longitude,
        
        name,
        contact_number,
        whatsapp,
        messenger,
        
        flag,
        added_by_user_id
        
INTO    cur_common_supplier_country_id,
        cur_common_supplier_address_level_1_id,
        cur_common_supplier_address_level_2_id,
        cur_common_supplier_address_level_3_id,
        
        cur_common_supplier_is_feed_supplier,
        cur_common_supplier_is_gilt_supplier,
        cur_common_supplier_is_semen_supplier,
    
        cur_common_supplier_latitude,
        cur_common_supplier_longitude,
    
        cur_common_supplier_name,
        cur_common_supplier_contact_number,
        cur_common_supplier_whatsapp,
        cur_common_supplier_messenger,
        
        cur_common_supplier_flag,
        cur_added_by_user_id
        
FROM    common_supplier
WHERE   id = in_common_supplier_id;

SELECT  account_id
INTO    cur_user_orig_account_id
FROM    user
WHERE   id = cur_added_by_user_id;


/* Get user flag*/
SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id = in_user_id;


SET in_name_upper = UPPER(in_name);


/* Check for duplicate entry */
IF in_address_level_3_id IS NULL THEN 
    SELECT  id
    INTO    cur_common_supplier_id
    FROM    common_supplier
    WHERE   country_id          = cur_common_supplier_country_id AND 
            address_level_1_id  = cur_common_supplier_address_level_1_id    AND
            address_level_2_id  = cur_common_supplier_address_level_2_id    AND
            id                  != in_common_supplier_id AND 
            UPPER(name)         = in_name_upper
    LIMIT   1;
ELSE
    SELECT  id
    INTO    cur_common_supplier_id
    FROM    common_supplier
    WHERE   country_id          = cur_common_supplier_country_id AND 
            address_level_1_id  = cur_common_supplier_address_level_1_id    AND
            address_level_2_id  = cur_common_supplier_address_level_2_id    AND
            address_level_3_id  = cur_common_supplier_address_level_3_id    AND
            id                  != in_common_supplier_id AND 
            UPPER(name)         = in_name_upper
    LIMIT   1;
END IF;

IF cur_common_supplier_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;





/* Only users of the account who added this entry can update.
Or a SYSTEM_SUPER_USER.
*/
IF cur_user_orig_account_id != cur_user_account_id THEN 
    IF cur_user_flag & FLAG_BIT_SYSTEM_SUPER_USER = 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        
        LEAVE process_user;
    END IF;
    
    /* Will allow update only if user.flag.FLAG_BIT_SYSTEM_SUPER_USER is SET*/

ELSE
    IF (cur_common_supplier_flag & FLAG_BIT_COMMON_SUPPLIER_IS_VERIFIED) > 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        SET res_code    = "Supplier is already verified";
        
        LEAVE process_user;
    END IF;
    
    /* Will allow update only if common_supplier.flag.FLAG_BIT_COMMON_SUPPLIER_IS_VERIFIED 
    is CLEAR*/


END IF;



UPDATE common_supplier SET
    address_level_3_id  = in_address_level_3_id,
    
    is_feed_supplier    = in_is_feed_supplier,
    is_gilt_supplier    = in_is_gilt_supplier,
    is_semen_supplier   = in_is_semen_supplier,
    
    latitude            = in_latitude,
    longitude           = in_longitude,

    name                = in_name_upper,
    contact_number      = in_contact_number,
    whatsapp            = in_whatsapp,
    messenger           = in_messenger,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_common_supplier_id;


/* Add audit trail*/
INSERT INTO common_supplier_audit(
    common_supplier_id,
    audit_user_id,
    audit_action,

    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    is_feed_supplier,
    is_gilt_supplier,
    is_semen_supplier,
    
    latitude,
    longitude,
    
    name,
    contact_number,
    whatsapp,
    messenger
    
) VALUES (
    in_common_supplier_id,
    in_user_id,
    USER_AUDIT_ACTION_UPDATE,

    cur_common_supplier_country_id,
    cur_common_supplier_address_level_1_id,
    cur_common_supplier_address_level_2_id,
    cur_common_supplier_address_level_3_id,
    
    cur_common_supplier_is_feed_supplier,
    cur_common_supplier_is_gilt_supplier,
    cur_common_supplier_is_semen_supplier,

    cur_common_supplier_latitude,
    cur_common_supplier_longitude,

    cur_common_supplier_name,
    cur_common_supplier_contact_number,
    cur_common_supplier_whatsapp,
    cur_common_supplier_messenger
        
);



END process_user;


SELECT
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    latitude,
    longitude,
    
    is_feed_supplier,
    is_gilt_supplier,
    is_semen_supplier,
    
    flag,
    name,
    contact_number,
    whatsapp,
    messenger
    
INTO 
    cur_common_supplier_country_id,
    cur_common_supplier_address_level_1_id,
    cur_common_supplier_address_level_2_id,
    cur_common_supplier_address_level_3_id,
    
    cur_common_supplier_latitude,
    cur_common_supplier_longitude,
    
    cur_common_supplier_is_feed_supplier,
    cur_common_supplier_is_gilt_supplier,
    cur_common_supplier_is_semen_supplier,
    
    cur_common_supplier_flag,
    cur_common_supplier_name,
    cur_common_supplier_contact_number,
    cur_common_supplier_whatsapp,
    cur_common_supplier_messenger
    
FROM common_supplier
WHERE id = in_common_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    
    in_common_supplier_id                AS common_supplier_id,
    cur_common_supplier_flag             AS flag,
    cur_common_supplier_name             AS name,
    cur_common_supplier_contact_number   AS contact_number,
    cur_common_supplier_whatsapp         AS whatsapp,
    cur_common_supplier_messenger        AS messenger,
    
    cur_common_supplier_is_feed_supplier AS is_feed_supplier,
    cur_common_supplier_is_gilt_supplier AS is_gilt_supplier,
    cur_common_supplier_is_semen_supplier AS is_semen_supplier,
    
    cur_common_supplier_country_id           AS country_id,
    cur_common_supplier_address_level_1_id   AS level_1_id,
    cur_common_supplier_address_level_2_id   AS level_2_id,
    cur_common_supplier_address_level_3_id   AS level_3_id,
    
    cur_common_supplier_latitude        AS latitude,
    cur_common_supplier_longitude       AS longitude;
    
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS feed_brand_add $$
CREATE PROCEDURE feed_brand_add(
    in_user_id              INT,

    in_country_id           INT,
    
    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will add feed_brand entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD                      INT             DEFAULT 21;




/* feed_brand.flag bits*/
DECLARE FLAG_BIT_FEED_BRAND_IS_DELETED          INT             DEFAULT 1;
DECLARE FLAG_BIT_FEED_BRAND_IS_VERIFIED         INT             DEFAULT 2;


DECLARE MAX_UNVERIFIED_ENTRIES_PER_USER         INT             DEFAULT 3;
DECLARE MAX_DELETED_INVALID_ENTRIES_PER_USER    INT             DEFAULT 3;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_feed_brand_id                       INT             DEFAULT 0;
DECLARE cur_feed_brand_flag                     INT             DEFAULT 0;
DECLARE cur_feed_brand_name                     VARCHAR(50)     DEFAULT '';

DECLARE in_name_upper                         	VARCHAR(50)     DEFAULT '';

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
    
    0, /* public business object*/
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* All public object names are in UPPER case. Except address names.*/
SET in_name_upper = UPPER(in_name);



/* Check for duplicate entry */
SELECT  id
INTO    cur_feed_brand_id
FROM    feed_brand
WHERE   country_id          = in_country_id   AND
        name                = in_name_upper
LIMIT   1;

IF cur_feed_brand_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* feed_brand can be added by any user. To prevent abuse of entering
invalid feed_brand, unverified entries will be counted and 
deleted entries against the user wil be counted.*/

SELECT  COUNT(*)
INTO    cur_count
FROM    feed_brand
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_FEED_BRAND_IS_VERIFIED) = 0;

IF cur_count >= MAX_UNVERIFIED_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many unverified entries entered by user.";
    
    LEAVE process_user;

END IF;


SELECT  COUNT(*) 
INTO    cur_count
FROM    feed_brand
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_FEED_BRAND_IS_DELETED) > 0;
        
IF cur_count >= MAX_DELETED_INVALID_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many invalid entries entered by user.";
    
    LEAVE process_user;

END IF;
        

INSERT INTO feed_brand(
    country_id,
    
    name,
    added_by_user_id
    
) VALUES (
   in_country_id,
  
   in_name_upper,
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_brand_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_feed_brand_flag,
    cur_feed_brand_name
FROM feed_brand
WHERE id = cur_feed_brand_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_brand_id                   AS feed_brand_id,
    cur_feed_brand_flag                 AS feed_brand_flag,
    cur_feed_brand_name                 AS feed_brand_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS semen_supplier_semen_add $$
CREATE PROCEDURE semen_supplier_semen_add(
    in_user_id              INT,

    in_semen_supplier_id    INT,
    in_name                 VARCHAR(50)
    
)  

BEGIN

/** 
 * Will add semen_supplier semen entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 17, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD                      INT             DEFAULT 21;




/* semen_supplier_semen.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_DELETED      INT       DEFAULT 1;
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED     INT       DEFAULT 2;


DECLARE MAX_UNVERIFIED_ENTRIES_PER_USER         INT             DEFAULT 3;
DECLARE MAX_DELETED_INVALID_ENTRIES_PER_USER    INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE in_name_upper                           VARCHAR(50)     DEFAULT '';


DECLARE cur_semen_supplier_semen_id             INT             DEFAULT 0;
DECLARE cur_semen_supplier_semen_flag           INT             DEFAULT 0;
DECLARE cur_semen_supplier_semen_name           VARCHAR(50)     DEFAULT '';


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
    
    0, /* public business object*/
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* All public object names are in UPPER case. Except address names.*/
SET in_name_upper = UPPER(in_name);


/* Check for duplicate entry */

SELECT  id
INTO    cur_semen_supplier_semen_id
FROM    semen_supplier_semen
WHERE   semen_supplier_id   = in_semen_supplier_id AND 
        UPPER(name)         = in_name_upper
LIMIT   1;

IF cur_semen_supplier_semen_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* semen_supplier_semen can be added by any user. To prevent abuse of entering
invalid semen_supplier_semen, unverified entries will be counted and 
deleted entries against the user wil be counted.*/

SELECT  COUNT(*)
INTO    cur_count
FROM    semen_supplier_semen 
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED) = 0;

IF cur_count >= MAX_UNVERIFIED_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many unverified entries entered by user.";
    
    LEAVE process_user;

END IF;


SELECT  COUNT(*) 
INTO    cur_count
FROM    semen_supplier_semen
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_DELETED) > 0;
        
IF cur_count >= MAX_DELETED_INVALID_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many invalid entries entered by user.";
    
    LEAVE process_user;

END IF;




INSERT INTO semen_supplier_semen(
    semen_supplier_id,
    name,
    
    added_by_user_id
    
) VALUES (
   in_semen_supplier_id,
   in_name_upper,
   
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_semen_supplier_semen_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_supplier_semen_flag,
    cur_semen_supplier_semen_name
FROM semen_supplier_semen
WHERE id = cur_semen_supplier_semen_id;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_semen_supplier_semen_id         AS semen_supplier_semen_id,
    cur_semen_supplier_semen_flag       AS semen_supplier_semen_flag,
    cur_semen_supplier_semen_name       AS semen_supplier_semen_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS semen_supplier_semen_update $$
CREATE PROCEDURE semen_supplier_semen_update(
    in_user_id              INT,
    
    in_semen_sup_semen_id   INT, 

    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will update semen_supplier semen entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 17, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;

DECLARE RES_NUM_NOT_ALLOWED_TO_UPDATE           INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_SEMEN_SUPPLIER          INT             DEFAULT 13;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* semen_supplier_semen.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_DELETED      INT             DEFAULT 1;
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED     INT             DEFAULT 2;


/* user.flag bits*/
DECLARE FLAG_BIT_SYSTEM_SUPER_USER              INT             DEFAULT 131072;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


DECLARE in_name_upper                           VARCHAR(50)     DEFAULT '';


DECLARE cur_added_by_user_id                    INT             DEFAULT 0;
DECLARE cur_user_orig_account_id                INT             DEFAULT 0;


DECLARE cur_semen_supplier_id                   INT             DEFAULT 0;
DECLARE cur_semen_supplier_semen_id             INT             DEFAULT 0;
DECLARE cur_semen_supplier_semen_flag           INT             DEFAULT 0;
DECLARE cur_semen_supplier_semen_name           VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_SEMEN_SUPPLIER,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



/* Get the account_id of the user who originally entered this entry. */
SELECT  semen_supplier_id,
        flag,
        added_by_user_id
        
INTO    cur_semen_supplier_id,
        cur_semen_supplier_semen_flag,
        cur_added_by_user_id
        
FROM    semen_supplier_semen
WHERE   id = in_semen_sup_semen_id;

SELECT  account_id
INTO    cur_user_orig_account_id
FROM    user
WHERE   id = cur_added_by_user_id;


/* All public object names are in UPPER case. Except address names.*/
SET in_name_upper = UPPER(in_name);


/* Check for duplicate entry */

SELECT  id
INTO    cur_semen_supplier_semen_id
FROM    semen_supplier_semen
WHERE   semen_supplier_id   = cur_semen_supplier_id AND 
        id                  != in_semen_sup_semen_id AND 
        UPPER(name)         = in_name_upper
LIMIT   1;


IF cur_semen_supplier_semen_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



/* Get user flag*/
SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id = in_user_id;


/* Only users of the account who added this entry can update.
Or a SYSTEM_SUPER_USER.
*/
IF cur_user_orig_account_id != cur_user_account_id THEN 
    IF cur_user_flag & FLAG_BIT_SYSTEM_SUPER_USER = 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        
        LEAVE process_user;
    END IF;
    
    /* Will allow update only if user.flag.FLAG_BIT_SYSTEM_SUPER_USER is SET*/

ELSE
    IF (cur_semen_supplier_semen_flag & FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED) > 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        SET res_code    = "Semen supplier semen is already verified";
        
        LEAVE process_user;
    END IF;
    
    /* Will allow update only if feed_supplier.flag.FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED 
    is CLEAR*/


END IF;



UPDATE semen_supplier_semen SET    
    name                = in_name,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_semen_sup_semen_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_supplier_semen_flag,
    cur_semen_supplier_semen_name
FROM semen_supplier_semen
WHERE id = in_semen_sup_semen_id;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_semen_sup_semen_id               AS semen_supplier_semen_id,
    cur_semen_supplier_semen_flag       AS semen_supplier_semen_flag,
    cur_semen_supplier_semen_name       AS semen_supplier_semen_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS medvac_type_add $$
CREATE PROCEDURE medvac_type_add(
    in_user_id              INT,

    in_name                 VARCHAR(50)
    
)  

BEGIN

/** 
 * Will add medvac_type entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD                      INT             DEFAULT 21;




/* medvac_type.flag bits*/
DECLARE FLAG_BIT_MEDVAC_TYPE_IS_DELETED         INT             DEFAULT 1;
DECLARE FLAG_BIT_MEDVAC_TYPE_IS_VERIFIED        INT             DEFAULT 2;


DECLARE MAX_UNVERIFIED_ENTRIES_PER_USER         INT             DEFAULT 3;
DECLARE MAX_DELETED_INVALID_ENTRIES_PER_USER    INT             DEFAULT 3;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_medvac_type_id                      INT             DEFAULT 0;
DECLARE cur_medvac_type_flag                    INT             DEFAULT 0;
DECLARE cur_medvac_type_name                    VARCHAR(50)     DEFAULT '';
    
DECLARE in_name_upper                           VARCHAR(50)     DEFAULT '';

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
    
    0, /* public business object*/
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* All public object names are in UPPER case. Except address names.*/
SET in_name_upper = UPPER(in_name);



/* Check for duplicate entry */
SELECT  id
INTO    cur_medvac_type_id
FROM    medvac_type
WHERE   name                = in_name_upper
LIMIT   1;

IF cur_medvac_type_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* medvac_type can be added by any user. To prevent abuse of entering
invalid medvac_type, unverified entries will be counted and 
deleted entries against the user will be counted.*/

SELECT  COUNT(*)
INTO    cur_count
FROM    medvac_type
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_MEDVAC_TYPE_IS_VERIFIED) = 0;

IF cur_count >= MAX_UNVERIFIED_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many unverified entries entered by user.";
    
    LEAVE process_user;

END IF;


SELECT  COUNT(*) 
INTO    cur_count
FROM    medvac_type
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_MEDVAC_TYPE_IS_DELETED) > 0;
        
IF cur_count >= MAX_DELETED_INVALID_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many invalid entries entered by user.";
    
    LEAVE process_user;

END IF;
        

INSERT INTO medvac_type(
    name,
    added_by_user_id
    
) VALUES (
    in_name_upper,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_medvac_type_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_medvac_type_flag,
    cur_medvac_type_name
FROM medvac_type
WHERE id = cur_medvac_type_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_medvac_type_id                  AS medvac_type_id,
    cur_medvac_type_flag                AS medvac_type_flag,
    cur_medvac_type_name                AS medvac_type_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS medvac_brand_add $$
CREATE PROCEDURE medvac_brand_add(
    in_user_id              INT,

    in_country_id           INT,
    
    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will add medvac_brand entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD                      INT             DEFAULT 21;




/* medvac_brand.flag bits*/
DECLARE FLAG_BIT_MEDVAC_BRAND_IS_DELETED     	INT             DEFAULT 1;
DECLARE FLAG_BIT_MEDVAC_BRAND_IS_VERIFIED       INT             DEFAULT 2;


DECLARE MAX_UNVERIFIED_ENTRIES_PER_USER         INT             DEFAULT 3;
DECLARE MAX_DELETED_INVALID_ENTRIES_PER_USER    INT             DEFAULT 3;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_medvac_brand_id                   	INT             DEFAULT 0;
DECLARE cur_medvac_brand_flag                 	INT             DEFAULT 0;
DECLARE cur_medvac_brand_name                 	VARCHAR(50)     DEFAULT '';

DECLARE in_name_upper                         	VARCHAR(50)     DEFAULT '';

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
    
    0, /* public business object*/
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* All public object names are in UPPER case. Except address names.*/
SET in_name_upper = UPPER(in_name);



/* Check for duplicate entry */
SELECT  id
INTO    cur_medvac_brand_id
FROM    medvac_brand
WHERE   country_id          = in_country_id   AND
        name                = in_name_upper
LIMIT   1;

IF cur_medvac_brand_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* medvac_brand can be added by any user. To prevent abuse of entering
invalid medvac_brand, unverified entries will be counted and 
deleted entries against the user will be counted.*/

SELECT  COUNT(*)
INTO    cur_count
FROM    medvac_brand
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_MEDVAC_BRAND_IS_VERIFIED) = 0;

IF cur_count >= MAX_UNVERIFIED_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many unverified entries entered by user.";
    
    LEAVE process_user;

END IF;


SELECT  COUNT(*) 
INTO    cur_count
FROM    medvac_brand
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_MEDVAC_BRAND_IS_DELETED) > 0;
        
IF cur_count >= MAX_DELETED_INVALID_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many invalid entries entered by user.";
    
    LEAVE process_user;

END IF;
        

INSERT INTO medvac_brand(
    country_id,
    
    name,
    added_by_user_id
    
) VALUES (
   in_country_id,
  
   in_name_upper,
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_medvac_brand_id;




END process_user;


SELECT
    flag,
    name
INTO 
    cur_medvac_brand_flag,
    cur_medvac_brand_name
FROM medvac_brand
WHERE id = cur_medvac_brand_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_medvac_brand_id                	AS medvac_brand_id,
    cur_medvac_brand_flag               AS medvac_brand_flag,
    cur_medvac_brand_name               AS medvac_brand_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_num_pigs_wean_populate $$
CREATE PROCEDURE sow_boar_num_pigs_wean_populate()  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 23, 2025
 *
 */


DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;

DECLARE cur_count_births                        INT             DEFAULT 0;

DECLARE cur_num_pigs_weaning_m                  INT             DEFAULT 0;
DECLARE cur_num_pigs_weaning_f                  INT             DEFAULT 0;
DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;

DECLARE cur_num_pigs_live_m                     INT             DEFAULT 0;
DECLARE cur_num_pigs_live_f                     INT             DEFAULT 0;


DECLARE cur_num_pigs                            INT             DEFAULT 0;



DECLARE l_last_row_fetched TINYINT;
DECLARE c_pig_prod CURSOR FOR
    SELECT  sow_id
    FROM    pig_production
    GROUP BY  sow_id;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 

    
SET l_last_row_fetched=0;
OPEN c_pig_prod;   
    

loop_here: LOOP
    FETCH c_pig_prod INTO 
        cur_pig_prod_sow_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    /** Count number of births */
    SELECT  COUNT(*)
    INTO    cur_count_births
    FROM    pig_production
    WHERE   sow_id = cur_pig_prod_sow_id AND date_actual_birth IS NOT NULL;
    
    
    /** SUM the number pigs weaned for this sow. */

    SELECT  SUM(num_pigs_weaning_m),
            SUM(num_pigs_weaning_f),
            SUM(num_pigs_weaning)
            
    INTO    cur_num_pigs_weaning_m,    
            cur_num_pigs_weaning_f,
            cur_num_pigs_weaning
    FROM    pig_production
    WHERE   sow_id = cur_pig_prod_sow_id AND date_weaning IS NOT NULL;
    
    
    SELECT  SUM(num_pigs_live_m),
            SUM(num_pigs_live_f)
            
    INTO    cur_num_pigs_live_m,    
            cur_num_pigs_live_f
            
    FROM    pig_production
    WHERE   sow_id = cur_pig_prod_sow_id    AND 
            date_actual_birth IS NOT NULL   AND 
            date_weaning IS NULL;
    
    

    SET cur_num_pigs = 0;
    
    
    IF cur_num_pigs_weaning_m > 0 THEN 
        SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning_m;
    END IF;

    IF cur_num_pigs_weaning_f > 0 THEN 
        SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning_f;
    END IF;

    IF cur_num_pigs_weaning > 0 THEN 
        SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning;
    END IF;
    
    IF cur_num_pigs_live_m > 0 THEN 
        SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_live_m;
    END IF;
    
    
    IF cur_num_pigs_live_f > 0 THEN 
        SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_live_f;
    END IF;
    
    
    
    
    UPDATE sow_boar SET
        num_births = cur_count_births,
        num_pigs_wean = cur_num_pigs
    WHERE id = cur_pig_prod_sow_id;
   

END LOOP loop_here;
 
CLOSE c_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
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

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


DECLARE SOW_STATUS_ID_GROWING                   INT             DEFAULT 1;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_last_sow_id                INT             DEFAULT 0;
DECLARE cur_pig_farm_last_boar_id               INT             DEFAULT 0;


DECLARE cur_sow_boar_id                         INT             DEFAULT 0;
DECLARE cur_sow_boar_flag                       INT             DEFAULT 0;

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
    
    UPDATE pig_farm SET 
        data_ver_num_sow = data_ver_num_sow + 1
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
    
    UPDATE pig_farm SET 
        data_ver_num_boar = data_ver_num_boar + 1
    WHERE id = in_pig_farm_id;
    
END IF;

SELECT LAST_INSERT_ID() INTO cur_sow_boar_id;



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
DELIMITER $$

DROP PROCEDURE IF EXISTS boar_external_mate_update $$
CREATE PROCEDURE boar_external_mate_update(
    in_user_id              INT,
    in_sow_boar_mate_id     INT,
    
    in_boar_customer_id     INT,    /* This is mapped to account_pig_buyer*/
    
    in_customer_sow_name    VARCHAR(50),
    
    in_date_mate            VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update sow_boar_mate.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_mate_notes_id              INT             DEFAULT 0;


DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  b.account_id,
        a.notes_id
        
INTO    cur_sow_boar_account_id,
        cur_sow_boar_mate_notes_id
        
FROM    sow_boar_mate a
LEFt OUTER JOIN  sow_boar b ON a.sow_boar_id = b.id
WHERE   a.id = in_sow_boar_mate_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
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



    
    
UPDATE sow_boar_mate SET
    boar_customer_id    = in_boar_customer_id,
    customer_sow_name   = in_customer_sow_name,
    
    date_mate           = in_date_mate,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_sow_boar_mate_id;

IF in_notes IS NOT NULL THEN
    IF cur_sow_boar_mate_notes_id IS  NULL THEN 

        INSERT INTO pig_prod_notes (
            sow_boar_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            in_boar_id,
            
            in_notes,
            in_date_mate,
            in_user_id
        );

        SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
        
        UPDATE sow_boar_mate SET
            notes_id = cur_pig_prod_notes_id
        WHERE id = in_sow_boar_mate_id;
        
    ELSE
        UPDATE pig_prod_notes SET
            notes = in_notes
        WHERE id = cur_sow_boar_mate_notes_id;
    END IF;

END IF;


UPDATE sow_boar SET 
    data_ver_num_sow_boar   = data_ver_num_sow_boar + 1
WHERE id = in_boar_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS gilt_pig_ops_add $$
CREATE PROCEDURE gilt_pig_ops_add(
    in_user_id              INT,
    
    in_account_id           INT,
    in_operation_type       INT,
    in_sow_id               INT,
    in_date_reference       VARCHAR(10)
)  

BEGIN

/** 
 * A sub procedure to create pig_prod_pig_ops entries.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 12, 2025
 *
 */

DECLARE cur_account_flag_settings               INT             DEFAULT 0;
DECLARE cur_account_pig_ops_id                  INT             DEFAULT 0;
DECLARE cur_account_pig_ops_num_days            INT             DEFAULT 0;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_ops CURSOR FOR
    SELECT  id,
            num_days_since
    FROM    account_pig_ops
    WHERE   account_id = in_account_id      AND 
            operation_type = PIG_OPERATION_TYPE_GILT_OPS AND 
            (flag & 1) = 0
    ORDER BY num_days_since ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;


    
SET l_last_row_fetched=0;
OPEN c_account_pig_ops;   
    

loop_here: LOOP
    FETCH c_account_pig_ops INTO 
        cur_account_pig_ops_id,
        cur_account_pig_ops_num_days;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;


    /* Default*/
    SET num_days_to_add = cur_account_pig_ops_num_days;
    
    /* Need to adjust Day 1 counting.*/
    IF  in_operation_type = PIG_OPERATION_TYPE_GILT_OPS THEN 
        IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH > 0 THEN 
            SET num_days_to_add = cur_account_pig_ops_num_days - 1;
        ELSE
            SET num_days_to_add = cur_account_pig_ops_num_days;
        END IF;
    END IF;
    
   

    INSERT INTO pig_prod_pig_ops(
        pig_prod_id,
        
        sow_boar_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        NULL,
        
        in_sow_id,
        cur_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(in_date_reference, INTERVAL num_days_to_add DAY)
    );
    
    UPDATE sow_boar SET 
        data_ver_num_sow_boar   = data_ver_num_sow_boar + 1
    WHERE id = in_sow_id;
    

END LOOP loop_here;
 
CLOSE c_account_pig_ops;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_mate_populate $$
CREATE PROCEDURE sow_boar_mate_populate()  

BEGIN

/** 
 * A sub procedure to create pig_prod_pig_ops entries.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 30, 2025
 *
 */

DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_boar_id                    INT             DEFAULT 0;
DECLARE cur_pig_prod_date_insemination          DATE;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_pig_prod CURSOR FOR
    SELECT  id,
            sow_id,
            boar_id,
            date_insemination
    FROM    pig_production
    WHERE   boar_id IS NOT NULL; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 

    
SET l_last_row_fetched=0;
OPEN c_pig_prod;   
    

loop_here: LOOP
    FETCH c_pig_prod INTO 
        cur_pig_prod_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_boar_id,
        cur_pig_prod_date_insemination;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    INSERT INTO sow_boar_mate(
        pig_prod_id,
        sow_boar_id,
        mate_sow_boar_id,
        date_mate
    ) VALUES(
        cur_pig_prod_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_boar_id,
        cur_pig_prod_date_insemination
    ),
    
    (
        cur_pig_prod_id,
        cur_pig_prod_boar_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_date_insemination
    );
   

END LOOP loop_here;
 
CLOSE c_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_dispose $$
CREATE PROCEDURE sow_boar_dispose(
    in_user_id              INT,
    
    in_sow_boar_id          INT,
    in_dispose_status_id    INT,
    
    in_date_dispose         VARCHAR(10),
    in_dispose_notes        VARCHAR(160)
)  

BEGIN

/** 
 * Will dispose sow_boar entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 17, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
        

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;



DECLARE cur_sow_boar_sex                        CHAR(2);


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.pig_farm_id,  
        a.account_id,
        a.sex,
        a.last_pig_production_id,
        b.prod_status_id

INTO    cur_sow_boar_pig_farm_id,
        cur_sow_boar_account_id,
        cur_sow_boar_sex,
        cur_pig_prod_id,
        cur_pig_prod_status_id
        
FROM    sow_boar
WHERE   id = in_sow_boar_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SOW_BOAR,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF in_dispose_notes IS NOT NULL THEN 
    INSERT INTO pig_prod_notes (
        sow_boar_id,
        
        notes,
        date_notes,
        added_by_user_id
        
    ) VALUES (
        in_sow_boar_id,
        
        in_dispose_notes,
        CURRENT_DATE,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
END IF;




UPDATE sow_boar SET
    date_dispose        = in_date_dispose,
    dispose_notes_id    = cur_pig_prod_notes_id,
    dispose_status_id   = in_dispose_status_id,
    is_disposed         = 1,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE 
    id = in_sow_boar_id;


IF cur_sow_boar_sex = 'M' THEN 
    UPDATE pig_farm SET
        data_ver_num_boar = data_ver_num_boar + 1
    WHERE id = cur_sow_boar_pig_farm_id; 
ELSE
    /* Update production status if gestating*/
    IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_GESTATING THEN 
        UPDATE pig_production SET 
            prod_status_id = PRODUCTION_STATUS_ID_TERMINATED
        WHERE id = cur_pig_prod_id;
        
        UPDATE pig_farm SET
            data_ver_num_sow      = data_ver_num_sow + 1,
            data_ver_num_pig_prod = data_ver_num_pig_prod + 1
        WHERE id = cur_sow_boar_pig_farm_id; 
    
    ELSE
    
        UPDATE pig_farm SET
            data_ver_num_sow      = data_ver_num_sow + 1
        WHERE id = cur_sow_boar_pig_farm_id; 

    END IF;
END IF;







END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_sow_boar_id                      AS sow_boar_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_update $$
CREATE PROCEDURE sow_boar_update(
    in_user_id              INT,
    
    in_sow_boar_id          INT,
    in_line_id              INT,
    in_sow_status_id        INT,
    in_is_external          INT,
    in_is_production_ready  INT,
    
    in_parent_sow_id        INT,
    in_parent_boar_id       INT,
    
    in_number               VARCHAR(10),
    in_name                 VARCHAR(20),
    in_date_of_birth        VARCHAR(10),
    in_date_eartag          VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update sow_boar entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 16, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;
DECLARE RES_NUM_SOW_BOAR_ALREADY_DISPOSED       INT             DEFAULT 1;

DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;



DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_sow_boar_id                         INT             DEFAULT 0;
DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_flag                       INT             DEFAULT 0;
DECLARE cur_sow_boar_add_notes_id               INT             DEFAULT 0;
DECLARE cur_sow_boar_is_disposed                INT             DEFAULT 0;
DECLARE cur_sow_boar_sex                        VARCHAR(2);
DECLARE cur_sow_boar_date_of_birth              DATE;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_account_flag_settings               INT             DEFAULT 0;
DECLARE cur_count                               INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        flag,
        add_notes_id,
        is_disposed,
        sex,
        date_of_birth
        
INTO    cur_sow_boar_account_id,
        cur_sow_boar_flag,
        cur_sow_boar_add_notes_id,
        cur_sow_boar_is_disposed,
        cur_sow_boar_sex,
        cur_sow_boar_date_of_birth
        
FROM    sow_boar
WHERE   id = in_sow_boar_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SOW_BOAR,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_sow_boar_is_disposed > 0 THEN 
    SET res_num     = RES_NUM_SOW_BOAR_ALREADY_DISPOSED;
    SET res_code    = "RES_NUM_SOW_BOAR_ALREADY_DISPOSED";
    
    LEAVE process_user;
END IF;


UPDATE sow_boar SET
    line_id                 = in_line_id,
    sow_status_id           = in_sow_status_id,
    
    is_external             = in_is_external,
    is_production_ready     = in_is_production_ready,
        
        
    parent_sow_id           = in_parent_sow_id,
    parent_boar_id          = in_parent_boar_id,
        
    number                  = in_number,
    name                    = in_name,
    date_of_birth           = in_date_of_birth,
    date_eartag             = in_date_eartag,
        
    last_update_user_id     = in_user_id,
    dt_last_update          = CURRENT_TIMESTAMP,
    
    data_ver_num_sow_boar   = data_ver_num_sow_boar + 1
    
WHERE 
    id = in_sow_boar_id;


IF cur_sow_boar_add_notes_id > 0 THEN
    UPDATE pig_prod_notes SET
        notes               = in_notes,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP

    WHERE id = cur_sow_boar_add_notes_id;
ELSE 
    IF in_notes IS NOT NULL THEN 
        INSERT INTO pig_prod_notes (
            sow_boar_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_sow_boar_id,
            
            in_notes,
            CURRENT_DATE,
            in_user_id
        );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    /* sow_boar.add_notes_id*/
    UPDATE sow_boar SET
        add_notes_id = cur_pig_prod_notes_id
    WHERE id = in_sow_boar_id;

    END IF;

END IF;


/*Perform a series of gilt ops adjustments if 
- a sow
- no gilt ops yet
- change in sow date_of_birth (need to recalculate the dates);
*/


IF cur_sow_boar_sex = 'F' THEN 
    IF in_date_of_birth IS NULL THEN 
        LEAVE process_user; /* Nothing to do*/
    END IF;
    

    SELECT  flag_settings
    INTO    cur_account_flag_settings
    FROM    account 
    WHERE   id = cur_sow_boar_account_id;


    /* Count if there is an account gilt pig ops.*/
    SELECT  COUNT(*) 
    INTO    cur_count 
    FROM    account_pig_ops
    WHERE   account_id = cur_sow_boar_account_id AND 
            operation_type = PIG_OPERATION_TYPE_GILT_OPS;
            
    IF cur_count > 0 THEN 
        SET cur_count = 0;
    
        SELECT  COUNT(*) 
        INTO    cur_count 
        FROM    pig_prod_pig_ops
        WHERE   sow_boar_id = in_sow_boar_id AND 
                operation_type = PIG_OPERATION_TYPE_GILT_OPS;
        
        IF cur_count = 0 THEN 
            CALL gilt_pig_ops_add(
                in_user_id,
                cur_user_account_id,
                PIG_OPERATION_TYPE_GILT_OPS,
                in_sow_boar_id,
                in_date_of_birth
            );
        
        END IF;
        
        IF cur_count > 0 THEN 
            
            /* Chnage only if there is an update of gilt date_of_birth */
            IF cur_sow_boar_date_of_birth != in_date_of_birth THEN 
            
                /* Need to adjust Day 1 counting.*/
                IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH = 0 THEN 
                    UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                        a.date_target = DATE_ADD(in_date_of_birth, INTERVAL b.num_days_since DAY)
                    WHERE   a.sow_boar_id = in_sow_boar_id AND 
                            a.operation_type = PIG_OPERATION_TYPE_GILT_OPS AND
                            a.account_pig_ops_id = b.id;
                
                ELSE
                    UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                        a.date_target = DATE_ADD(in_date_of_birth, INTERVAL b.num_days_since - 1 DAY)
                    WHERE   a.sow_boar_id = in_sow_boar_id AND 
                            a.operation_type = PIG_OPERATION_TYPE_GILT_OPS AND
                            a.account_pig_ops_id = b.id;
                END IF;
            
            END IF;
        
        END IF;
        
        
    END IF;
    
END IF;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_sow_boar_id                      AS sow_boar_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS boar_external_mate_add $$
CREATE PROCEDURE boar_external_mate_add(
    in_user_id              INT,
    
    in_boar_id              INT,
    in_boar_customer_id     INT,    /* This is mapped to account_pig_buyer*/
    
    in_customer_sow_name    VARCHAR(50),
    
    in_date_mate            VARCHAR(10),
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

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;


DECLARE cur_sow_boar_mate_id                    INT             DEFAULT 0;


DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        pig_farm_id
        
INTO    
        cur_sow_boar_account_id,
        cur_sow_boar_pig_farm_id
WHERE   id = in_pig_farm_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
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


SELECT  id
INTO    cur_sow_boar_mate_id
FROM    sow_boar_mate
WHERE   sow_boar_id         = in_boar_id            AND
        boar_customer_id    = in_boar_customer_id   AND
        date_mate           = in_date_mate
        
LIMIT 1;
        


IF cur_sow_boar_mate_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



    
    
INSERT INTO sow_boar_mate(
    sow_boar_id,
    boar_customer_id,
    customer_sow_name,
    
    date_mate,
    
    added_by_user_id
) VALUES (
    in_boar_id,
    in_boar_customer_id,
    in_customer_sow_name,
    
    in_date_mate,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_sow_boar_mate_id;


IF in_notes IS NOT NULL THEN
    INSERT INTO pig_prod_notes (
        sow_boar_id,
        
        notes,
        date_notes,
        added_by_user_id
        
    ) VALUES (
        in_boar_id,
        
        in_notes,
        in_date_mate,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    UPDATE sow_boar_mate SET
        notes_id = cur_pig_prod_notes_id
    WHERE id = cur_sow_boar_mate_id;

END IF;


UPDATE sow_boar SET 
    data_ver_num_sow_boar   = data_ver_num_sow_boar + 1
WHERE id = in_boar_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_sow_boar_mate_id                AS sow_boar_mate_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_medvac_add $$
CREATE PROCEDURE account_medvac_add(
    in_user_id              INT,
    in_medvac_brand_id      INT,
    in_medvac_type_id       INT,
    
    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will add account medvac entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since January 14, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;




DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';



DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_account_medvac_id                   INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;

DECLARE in_name_upper                           VARCHAR(80)     DEFAULT '';

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";




CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, 
    
    BUSINESS_OBJ_ID_FEED_BUY, /* TODO */
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


SET in_name_upper = UPPER(in_name);


/* Check for duplicate entry */

SELECT  id
INTO    cur_account_medvac_id
FROM    account_medvac
WHERE   UPPER(name) = in_name_upper
LIMIT   1;


IF cur_account_medvac_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO account_medvac(
    account_id,
    
    medvac_brand_id,
    medvac_type_id,
    
    name,
    added_by_user_id

) VALUES (
    cur_user_account_id,
    
    in_medvac_brand_id,
    in_medvac_type_id,
    
    in_name,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_medvac_id;





END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_medvac_id               AS medvac_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_add $$
CREATE PROCEDURE pig_prod_add(
    in_user_id              INT,
   
    in_sow_id               INT,    /* Cannot be updated*/
    in_boar_id              INT,
    in_semen_supplier_id    INT,
    in_semen_sup_semen_id   INT,    /* semen supplier semen_id*/
    in_semen_ai_boar_id     INT,    /* semen coming from one of farm's boar*/
    
    in_semen_cost           DECIMAL(6,2),
    in_insemination_cost    DECIMAL(6,2),
    in_comments             VARCHAR(160),
    
    in_insem_staff_id       INT,
    in_done_by_user         INT, 
    
    in_date_insemination    VARCHAR(10)  /* in YYYY-MM-DD format*/
)  

BEGIN

/** 
 * Will create pig_production entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 17, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE INSEMINATION_TYPE_BOAR                  VARCHAR(2)      DEFAULT 'B';
DECLARE INSEMINATION_TYPE_ARTIFICIAL_EXTERNAL   VARCHAR(4)      DEFAULT 'AI_X';
DECLARE INSEMINATION_TYPE_ARTIFICIAL_INTERNAL   VARCHAR(4)      DEFAULT 'AI_N';


/* common_supplier.flag bits*/
DECLARE FLAG_BIT_SUPPLIER_IS_DELETED            INT             DEFAULT 1;
DECLARE FLAG_BIT_SUPPLIER_IS_VERIFIED           INT             DEFAULT 2;


/* semen_supplier_semen.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_DELETED  INT             DEFAULT 1;
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED INT             DEFAULT 2;




DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;

DECLARE SOW_STATUS_ID_GESTATING                 INT             DEFAULT 2;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* Date insemination is day 0.*/
DECLARE PIG_NUM_DAYS_GESTATION                  INT             DEFAULT 114;


DECLARE MIN_COUNT_SUPPLIER_IS_VERIFIED          INT             DEFAULT 3;
DECLARE MIN_COUNT_SEMEN_IS_VERIFIED             INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';


DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_farm_sow_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_last_prod_id               INT             DEFAULT 0;
DECLARE cur_sow_boar_last_prod_status_id        INT             DEFAULT 0;


DECLARE cur_insemination_type                   VARCHAR(4)      DEFAULT '';


DECLARE cur_pig_farm_last_pig_production_id     INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_id                      INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;
DECLARE cur_count_semen_sup_semen_usage         INT             DEFAULT 0;
DECLARE cur_count_semen_sup_semen_account       INT             DEFAULT 0;
DECLARE cur_flag_bit                            INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.account_id,
        a.pig_farm_id,
        a.farm_sow_id,
        a.last_pig_production_id,
        b.prod_status_id
        
INTO    cur_sow_boar_account_id,
        cur_sow_boar_pig_farm_id,
        cur_sow_boar_farm_sow_id,
        cur_sow_boar_last_prod_id,
        cur_sow_boar_last_prod_status_id
FROM    sow_boar a
LEFT OUTER JOIN pig_production b ON a.last_pig_production_id = b.id
WHERE   a.id = in_sow_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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




/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_prod_id
FROM    pig_production
WHERE   pig_farm_id         = cur_sow_boar_pig_farm_id AND
        sow_id              = in_sow_id     AND 
        date_insemination   = in_date_insemination 
LIMIT   1;


IF cur_pig_prod_id > 0 THEN
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* If done by user, user will be added to staff list.
Note: not all staff are users
*/
IF in_done_by_user > 0 THEN
    SELECT  pig_farm_staff_id,
            name_first,
            name_last
    
    INTO    cur_user_staff_id,
            cur_user_name_first,
            cur_user_name_last
    FROM    user 
    WHERE   id = in_user_id;
    
    
    IF cur_user_staff_id = 0 THEN 
        INSERT INTO pig_farm_staff (
            account_id,
            pig_farm_id,
            user_id,
            name,
            
            added_by_user_id
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            in_user_id,
            CONCAT(cur_user_name_first, ' ', cur_user_name_last),
            
            in_user_id
        );
        SELECT LAST_INSERT_ID() INTO cur_user_staff_id;
        
        
        UPDATE pig_farm SET 
            data_ver_num_staff = data_ver_num_staff + 1
        WHERE id = cur_sow_boar_pig_farm_id;
        
        
        UPDATE user SET 
            pig_farm_staff_id = cur_user_staff_id
        WHERE id = in_user_id;
        
    END IF;
    
    
    SET in_insem_staff_id = cur_user_staff_id;
    
END IF;





/* Set previous pig_production of this sow to not pregnant, if status is gestating*/
UPDATE pig_production SET 
    prod_status_id = PRODUCTION_STATUS_ID_NOT_PREGNANT
WHERE sow_id = in_sow_id AND prod_status_id = PRODUCTION_STATUS_ID_GESTATING;


/* Update pig_farm*/
IF cur_sow_boar_last_prod_status_id = PRODUCTION_STATUS_ID_GESTATING THEN 
    UPDATE pig_farm SET 
        data_ver_num_not_pregnant =  data_ver_num_not_pregnant + 1
    WHERE id = cur_sow_boar_pig_farm_id;
END IF;


SELECT  last_pig_production_id
INTO    cur_pig_farm_last_pig_production_id
FROM    pig_farm
WHERE   id = cur_sow_boar_pig_farm_id;

SET cur_pig_farm_last_pig_production_id = cur_pig_farm_last_pig_production_id + 1;

IF in_boar_id IS NOT NULL THEN 
    INSERT INTO pig_production (
        account_id,
        pig_farm_id,
        farm_prod_id,
        
        insemination_type,
        
        sow_id,
        boar_id,
        
        semen_cost,
        insemination_cost,
        
        date_insemination,
        date_expected_birth,
        
        prod_status_id,
        insem_staff_id
    ) VALUES (
        cur_user_account_id,
        cur_sow_boar_pig_farm_id,
        cur_pig_farm_last_pig_production_id,
        
        INSEMINATION_TYPE_BOAR,
        
        in_sow_id,
        in_boar_id,
        
        NULL,
        in_insemination_cost,
        
        in_date_insemination,
        DATE_ADD(in_date_insemination, INTERVAL PIG_NUM_DAYS_GESTATION DAY),

        PRODUCTION_STATUS_ID_GESTATING,
        in_insem_staff_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;

    
    /* Insert to sow_boar_mate*/
    INSERT INTO sow_boar_mate(
        pig_prod_id,
        sow_boar_id,
        mate_sow_boar_id,
        date_mate,
        added_by_user_id
    ) 
    VALUES
    (
        cur_pig_prod_id,
        in_sow_id,
        in_boar_id,
        in_date_insemination,
        in_user_id
    ),
    
    (
        cur_pig_prod_id,
        in_boar_id,
        in_sow_id,
        in_date_insemination,
        in_user_id
    );



    /* Update sow_boar last mate*/
    UPDATE sow_boar SET
        last_pig_production_id  = cur_pig_prod_id,
        mate_count              = mate_count + 1,
        date_last_mate          = in_date_insemination,
        last_mate_sow_boar_id   = in_sow_id
    WHERE id = in_boar_id;

    UPDATE sow_boar SET
        last_pig_production_id  = cur_pig_prod_id,
        mate_count              = mate_count + 1,
        date_last_mate          = in_date_insemination,
        last_mate_sow_boar_id   = in_boar_id
    WHERE id = in_sow_id;


ELSE
    /* artificial insemination */
    
    /* Check if semen is coming from external supplier*/
    IF in_semen_sup_semen_id > 0 THEN 
        SET cur_insemination_type = INSEMINATION_TYPE_ARTIFICIAL_EXTERNAL;
    ELSE
        IF in_semen_ai_boar_id > 0 THEN 
            SET cur_insemination_type = INSEMINATION_TYPE_ARTIFICIAL_INTERNAL;
        END IF;
        
    END IF;
    
    
        
        
    
    INSERT INTO pig_production (
        account_id,
        pig_farm_id,
        farm_prod_id,
        
        insemination_type,
        
        sow_id,
        boar_id,
        
        semen_supplier_id,
        semen_sup_semen_id,
        semen_ai_boar_id,
        
        semen_cost,
        insemination_cost,
        
        date_insemination,
        date_expected_birth,
        
        prod_status_id,
        insem_staff_id
    ) VALUES (
        cur_user_account_id,
        cur_sow_boar_pig_farm_id,
        cur_pig_farm_last_pig_production_id,
        
        cur_insemination_type,
        
        in_sow_id,
        NULL,
        
        in_semen_supplier_id,
        in_semen_sup_semen_id,
        in_semen_ai_boar_id,
        
        in_semen_cost,
        in_insemination_cost,
        
        in_date_insemination,
        DATE_ADD(in_date_insemination, INTERVAL PIG_NUM_DAYS_GESTATION DAY),

        PRODUCTION_STATUS_ID_GESTATING,
        in_insem_staff_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;
    
    
    
    IF in_semen_supplier_id > 0 THEN 
    
        /* Insert account_id INTO account_selection.semen_supplier_id*/
        SELECT  COUNT(*) 
        INTO    cur_count
        FROM    account_selection
        WHERE   account_id =  cur_user_account_id AND 
                semen_supplier_id = in_semen_supplier_id;
                
        IF cur_count = 0 THEN 
            INSERT INTO account_selection(
                account_id,
                semen_supplier_id,
                added_by_user_id
            ) VALUES (
                cur_user_account_id,
                in_semen_supplier_id,
                in_user_id
            );
        END IF;
        
        
        /*Compute common_supplier.flag.FLAG_BIT_SUPPLIER_IS_VERIFIED*/
        SELECT  COUNT(*) 
        INTO    cur_count
        FROM    account_selection
        WHERE   (feed_supplier_id = in_semen_supplier_id OR
                semen_supplier_id = in_semen_supplier_id OR
                gilt_supplier_id  = in_semen_supplier_id) AND 
                
                account_id !=  cur_user_account_id;
                
        /* Update common_supplier.flag.FLAG_BIT_SUPPLIER_IS_VERIFIED*/
        IF cur_count >= MIN_COUNT_SUPPLIER_IS_VERIFIED THEN
            UPDATE common_supplier SET 
                flag = flag | FLAG_BIT_SUPPLIER_IS_VERIFIED
            WHERE id = in_semen_supplier_id;
        END IF;
        
        
        /* Insert account_id INTO account_selection.semen_sup_semen_id*/
        SELECT  COUNT(*) 
        INTO    cur_count
        FROM    account_selection
        WHERE   account_id =  cur_user_account_id AND 
                semen_sup_semen_id = in_semen_sup_semen_id;
                
        IF cur_count = 0 THEN 
            INSERT INTO account_selection(
                account_id,
                semen_sup_semen_id,
                added_by_user_id
            ) VALUES (
                cur_user_account_id,
                in_semen_sup_semen_id,
                in_user_id
            );
        END IF;
        
        
        SELECT  COUNT(*)
        INTO    cur_count_semen_sup_semen_account
        FROM    account_selection
        WHERE   semen_sup_semen_id = in_semen_sup_semen_id;
    
        
        IF cur_count_semen_sup_semen_account >= MIN_COUNT_SEMEN_IS_VERIFIED THEN 
            SET cur_flag_bit = FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED;
        END IF;
        
        
        UPDATE semen_supplier_semen SET 
            account_counter     = cur_count_semen_sup_semen_account,
            usage_counter       = usage_counter + 1,
            flag                = flag | cur_flag_bit
        WHERE id = in_semen_sup_semen_id;
        
        
        
        /* Update supplier account counter and usage*/
        SELECT  COUNT(*) 
        INTO    cur_count
        FROM    account_selection
        WHERE   semen_supplier_id = in_semen_supplier_id;
        
        UPDATE  common_supplier SET 
            ss_account_counter  = cur_count,
            ss_usage_counter    = ss_usage_counter + 1
        WHERE id = in_semen_supplier_id;
        
        
    
    END IF;
    
    
    INSERT INTO pig_prod_ai(
        pig_farm_id,
        pig_prod_id,
        semen_supplier_id,
        semen_sup_semen_id,
        semen_ai_boar_id,
        
        insem_staff_id,
        date_insemination,
        
        added_by_user_id
    ) VALUES(
        cur_sow_boar_pig_farm_id,
        cur_pig_prod_id,
        in_semen_supplier_id,
        in_semen_sup_semen_id,
        in_semen_ai_boar_id,
        
        in_insem_staff_id,
        in_date_insemination,
        
        in_user_id
    );
    
    SELECT LAST_INSERT_ID() INTO cur_pig_prod_ai_id;
    
END IF; 


/* Add comments*/
IF in_comments IS NOT NULL THEN 
    INSERT INTO pig_prod_notes (
        account_id,
        pig_farm_id,
        
        pig_prod_id,
        sow_boar_id,
        
        notes,
        date_notes,
        added_by_user_id
        
    ) VALUES (
        cur_sow_boar_account_id,
        cur_sow_boar_pig_farm_id,
    
        cur_pig_prod_id,
        in_sow_id,
        
        in_comments,
        in_date_insemination,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    /* pig_production.insem_notes_id*/
    UPDATE pig_production SET
        insem_notes_id = cur_pig_prod_notes_id
    WHERE id = cur_pig_prod_id;

END IF;
    

/* Increment pig_farm.last_pig_production_id*/
UPDATE pig_farm SET 
    last_pig_production_id  = cur_pig_farm_last_pig_production_id,
    data_ver_num_pig_prod   = data_ver_num_pig_prod + 1    
WHERE id = cur_sow_boar_pig_farm_id;


/* Update sow status*/
UPDATE sow_boar SET
    last_pig_production_id  = cur_pig_prod_id,
    sow_status_id           = SOW_STATUS_ID_GESTATING,
    data_ver_num_sow_boar   = data_ver_num_sow_boar + 1
WHERE id = in_sow_id;




/* Create pig_prod_pig_ops entry*/
CALL pig_prod_pig_ops_add(
    in_user_id, 
    
    cur_sow_boar_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    cur_pig_prod_id, 
    in_date_insemination);


/* Since this is a gestating pig ops, need to relate to SOW.*/
UPDATE pig_prod_pig_ops SET 
    sow_boar_id = in_sow_id
WHERE pig_prod_id = cur_pig_prod_id AND operation_type = PIG_OPERATION_TYPE_GESTATING;



END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_id                     AS pig_prod_id,
    cur_pig_prod_ai_id                  AS pig_prod_ai_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_check_active_status $$
CREATE PROCEDURE pig_prod_check_active_status(
    in_prod_status_id           INT,
    

    OUT out_is_active           INT
    
)

BEGIN

/** 
 * Will check if pig_production.pig_prod_status is active.
 * @author Jack Wong
 * @since January 18, 2026
 *
 */
 

DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;

SET out_is_active = 0;

IF in_prod_status_id IN (   PRODUCTION_STATUS_ID_GESTATING,
                            PRODUCTION_STATUS_ID_LACTATING,
                            PRODUCTION_STATUS_ID_GROWING,
                            PRODUCTION_STATUS_ID_WEANING) THEN 
    
    SET out_is_active = 1;
    
END IF;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_feed_start_date $$
CREATE PROCEDURE pig_prod_update_feed_start_date(
    in_user_id                  INT,
    
    in_pig_prod_id              INT,
    in_feed_type_id             INT,
    in_feed_start_date          VARCHAR(10)  /* in YYYY-MM-DD format*/
)

BEGIN

/** 
 * Will update pig_production feed start date.
 * @author Jack Wong
 * @since December 4, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_UPDATE_FEED_START_DATE_NOT_ALLOWED INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE FEED_TYPE_ID_GESTATING                  INT             DEFAULT 1;
DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                	INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;





DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;

DECLARE cur_account_flag_settings               INT             DEFAULT 0;

DECLARE cur_count_account_pig_ops               INT             DEFAULT 0;
DECLARE cur_count_pig_prod_pig_ops              INT             DEFAULT 0;

DECLARE num_days_to_add                         INT             DEFAULT 0;

DECLARE date_temp                               DATE            DEFAULT NULL;
DECLARE detected_actual_date_birth_change       INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        prod_status_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_status_id
        
FROM    pig_production
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_GESTATING,
                                    PRODUCTION_STATUS_ID_LACTATING,
                                    PRODUCTION_STATUS_ID_WEANING,
                                    PRODUCTION_STATUS_ID_GROWING,
                                    PRODUCTION_STATUS_ID_COMBINED) THEN 
    SET res_num     = RES_NUM_UPDATE_FEED_START_DATE_NOT_ALLOWED;
    SET res_code    = "RES_NUM_UPDATE_FEED_START_DATE_NOT_ALLOWED";

    LEAVE process_user;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_GESTATING THEN 

    UPDATE pig_production SET 
        date_gestating              = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_LACTATING THEN 

    UPDATE pig_production SET 
        date_lactating              = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_BOOSTER THEN 

    UPDATE pig_production SET 
        date_booster                = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_PRESTARTER THEN 

    UPDATE pig_production SET 
        date_prestarter             = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_STARTER THEN 

    UPDATE pig_production SET 
        date_starter                = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 

    UPDATE pig_production SET 
        date_grower                 = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_FINISHER THEN 

    UPDATE pig_production SET 
        date_finisher               = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_fattening_add $$
CREATE PROCEDURE pig_prod_fattening_add(
    in_user_id              INT,
    in_pig_farm_id          INT,
    
    in_num_pigs_added       INT,
    
    in_date_weaning         VARCHAR(10), /* in YYYY-MM-DD format*/
    in_date_added           VARCHAR(10)
)  

BEGIN

/** 
 * Will create pig_production fattening entry, piglets brought externally.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* pig_production.flag bits*/
DECLARE FLAG_BIT_PIGLETS_ARE_EXTERNAL           INT             DEFAULT 2;



DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;

DECLARE SOW_STATUS_ID_GESTATING                 INT             DEFAULT 2;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;


DECLARE cur_pig_farm_last_pig_production_id               INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_id                      INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_farm_account_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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




/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_prod_id
FROM    pig_production
WHERE   pig_farm_id         = in_pig_farm_id    AND
        date_weaning        = in_date_weaning   AND
        (flag & FLAG_BIT_PIGLETS_ARE_EXTERNAL) > 0
LIMIT   1;


IF cur_pig_prod_id > 0 THEN
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


SELECT  last_pig_production_id
INTO    cur_pig_farm_last_pig_production_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;

SET cur_pig_farm_last_pig_production_id = cur_pig_farm_last_pig_production_id + 1;



INSERT INTO pig_production (
    account_id,
    pig_farm_id,
    farm_prod_id,
    flag,
    prod_status_id,
    
    num_pigs_weaning_m,
    num_pigs_weaning_f,
    num_pigs_current,
    date_weaning,
    
    added_by_user_id
    
) VALUES (
    cur_user_account_id,
    cur_sow_boar_pig_farm_id,
    cur_pig_farm_last_pig_production_id,
    FLAG_BIT_PIGLETS_ARE_EXTERNAL,
    PRODUCTION_STATUS_ID_GROWING,
    
    0,
    0,
    in_num_pigs,
    in_date_weaning,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;


/* Since the number of pigs at weaning is indeterminate as these are 
external pigs, this will be treated as pigs added to production entry. 
Note: The pig_production.num_pigs_current is a computed number

num_pigs_current = number_of_weaning_pigs + SUM(added_external_pigs) -
    SUM(pigs_dead_at_growing_stage) - SUM(pigs_already_harvested)

Need to insert to pig_prod_pig_add table.*/

INSERT INTO pig_prod_pig_add (
    account_id,
    pig_farm_id,
    pig_prod_id,
    
    date_added,
    num_pigs_added,
    added_by_user_id
) VALUES (
    cur_pig_farm_account_id,
    in_pig_farm_id,
    cur_pig_prod_id,
    
    in_date_added,
    in_num_pigs_added,
    in_user_id
);



/* Increment pig_farm.last_prod_id*/
UPDATE pig_farm SET 
    last_prod_id    = cur_pig_farm_last_pig_production_id
WHERE id = cur_sow_boar_pig_farm_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_id                     AS pig_prod_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_status $$
CREATE PROCEDURE pig_prod_update_status(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_pig_prod_status_id   INT,
    
    in_date_status          VARCHAR(10),
    in_notes                VARCHAR(160)
)

BEGIN

/** 
 * Will update pig_production entry.
 * 
 * Will manually update pig_production.prod_status_id
 *
 * Allowed status_ids: TERMINATED, NOT_PREGNANT, CLOSED, NO_LIVE_PIGLETS
 *
 *
 * @author Jack Wong
 * @since September 12, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_INVALID_PIG_PROD_STATUS         INT             DEFAULT 20;
DECLARE RES_NUM_MANUAL_STATUS_UPDATE_NOT_ALLOWED INT            DEFAULT 21;
DECLARE RES_NUM_PIG_PROD_STATUS_NOT_GESTATING   INT             DEFAULT 22;

DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* pig_production.flag bits*/
DECLARE FLAG_BIT_PIGLETS_ARE_EXTERNAL           INT             DEFAULT 2;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;
DECLARE PRODUCTION_STATUS_ID_NO_LIVE_PIGLETS    INT             DEFAULT 10;

DECLARE PRODUCTION_STATUS_ID_DELETED            INT             DEFAULT 99;

DECLARE SOW_STATUS_ID_GROWING                   INT             DEFAULT 1;
DECLARE SOW_STATUS_ID_GESTATING                 INT             DEFAULT 2;
DECLARE SOW_STATUS_ID_DEAD                      INT             DEFAULT 6;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        sow_id,
        prod_status_id,
        flag
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_status_id,
        cur_pig_prod_flag
FROM    pig_production
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF in_pig_prod_status_id NOT IN (PRODUCTION_STATUS_ID_TERMINATED, 
                                PRODUCTION_STATUS_ID_NOT_PREGNANT, 
                                PRODUCTION_STATUS_ID_CLOSED,
                                PRODUCTION_STATUS_ID_NO_LIVE_PIGLETS,
                                PRODUCTION_STATUS_ID_DELETED) THEN
    
    SET res_num     = RES_NUM_MANUAL_STATUS_UPDATE_NOT_ALLOWED;
    SET res_code    = "RES_NUM_MANUAL_STATUS_UPDATE_NOT_ALLOWED";
    
    LEAVE process_user;
END IF;

IF in_pig_prod_status_id IN (PRODUCTION_STATUS_ID_TERMINATED, 
                            PRODUCTION_STATUS_ID_NOT_PREGNANT,
                            PRODUCTION_STATUS_ID_NO_LIVE_PIGLETS,
                            PRODUCTION_STATUS_ID_DELETED) THEN 
    
    IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
        SET res_num     = RES_NUM_PIG_PROD_STATUS_NOT_GESTATING;
        SET res_code    = "RES_NUM_PIG_PROD_STATUS_NOT_GESTATING";
        
        LEAVE process_user;
    END IF;
END IF;


UPDATE pig_production SET
    prod_status_id              = in_pig_prod_status_id,
    
    last_update_user_id         = in_user_id,
    dt_last_update              = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_id;


/* This will also update sow_status*/
IF in_pig_prod_status_id = PRODUCTION_STATUS_ID_TERMINATED THEN 
    UPDATE sow_boar SET 
        sow_status_id = SOW_STATUS_ID_DEAD
    WHERE id = cur_pig_prod_sow_id;
END IF;


IF in_pig_prod_status_id = PRODUCTION_STATUS_ID_DELETED THEN 
    UPDATE sow_boar SET 
        sow_status_id = SOW_STATUS_ID_GROWING
    WHERE id = cur_pig_prod_sow_id;
END IF;




IF in_pig_prod_status_id IN (PRODUCTION_STATUS_ID_NOT_PREGNANT,
                            PRODUCTION_STATUS_ID_NO_LIVE_PIGLETS,
                            PRODUCTION_STATUS_ID_DELETED) THEN 
    
    
    /* Sow is gestating but no production. */
    UPDATE sow_boar SET 
        sow_status_id = SOW_STATUS_ID_GESTATING
    WHERE id = cur_pig_prod_sow_id;
END IF;


/* Add notes*/
IF in_notes IS NOT NULL THEN 
    INSERT INTO pig_prod_notes (
        pig_prod_id,
        
        notes,
        date_notes,
        added_by_user_id
        
    ) VALUES (
        in_pig_prod_id,
        
        in_notes,
        in_date_status,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
END IF;


/** Update pig_farm.data_ver_num_pig_prod
Note: This is different from pig_production.data_ver_num_pig_prod;
The update of prod_status from gestating to being removed needs to propagated 
to users of the account.

*/
 
    
UPDATE pig_farm SET 
    data_ver_num_pig_prod = data_ver_num_pig_prod + 1
WHERE id = cur_pig_prod_pig_farm_id;
    



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_close $$
CREATE PROCEDURE pig_prod_close(
    in_user_id              INT,
    
    in_pig_prod_id          INT
)

BEGIN

/** 
 * Will update pig_production entry.
 * @author Jack Wong
 * @since September 5, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;

DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_pig_prod_date_actual_birth          DATE;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        prod_status_id
INTO    cur_pig_prod_account_id,
        cur_pig_prod_status_id
FROM    pig_production
WHERE   id = in_pig_prod_id
LIMIT   1;


/* Operation pig_production.close will be treated as delete operation
even if the actual row is not deleted; If the production_status is set close, 
all new changes to the pig production will not be allowed.

*/

CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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

IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


UPDATE pig_production SET
    prod_status_id      = PRODUCTION_STATUS_ID_CLOSED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_id;

END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_pig_count $$
CREATE PROCEDURE pig_prod_update_pig_count(
    in_user_id              INT,
    in_pig_prod_id          INT,

    in_num_pigs             INT,
    in_date_notes           VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update current pigs count data for pig_production entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 27, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_PIG_PROD_CANNOT_UPDATE_PIG_COUNT INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 19;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  
        account_id,
        pig_farm_id,
        status_id

INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id

FROM    pig_production 
WHERE   id = in_pig_prod_id
LIMIT   1;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF  cur_pig_prod_status_id NOT IN ( PRODUCTION_STATUS_ID_LACTATING,
                                    PRODUCTION_STATUS_ID_WEANING,
                                    PRODUCTION_STATUS_ID_GROWING) THEN 
    
    SET res_num     = RES_NUM_PIG_PROD_CANNOT_UPDATE_PIG_COUNT;
    SET res_code    = "RES_NUM_PIG_PROD_CANNOT_UPDATE_PIG_COUNT";
    SET res_desc    = "Production status not LACTATING, WEANING OR GROWING";
    
    LEAVE process_user;
END IF;


UPDATE pig_production SET
    num_pigs_current            = in_num_pigs,

    last_update_user_id         = in_user_id,
    dt_last_update              = CURRENT_TIMESTAMP
WHERE id = in_pig_prod_id;


IF in_notes IS NULL THEN 
    SET in_notes = "Updated pig count";
END IF;


INSERT INTO pig_prod_notes (
    account_id,
    pig_farm_id,
    pig_prod_id,
    
    notes,
    date_notes,
    added_by_user_id
    
) VALUES (
    cur_pig_prod_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    
    in_notes,
    in_date_notes,
    in_user_id
);


END process_user;


SELECT 

    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_prod_id;

    

END $$

DELIMITER ;DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_insem $$
CREATE PROCEDURE pig_prod_update_insem(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    
    in_boar_id              INT,
    
    in_semen_supplier_id    INT,
    in_semen_sup_semen_id   INT,    /* semen supplier semen_id*/
    in_semen_ai_boar_id     INT,    /* semen coming from one of farm's boar*/
    
    
    in_semen_cost           DECIMAL(6,2),
    in_insemination_cost    DECIMAL(6,2),
    in_comments             VARCHAR(160),
    
    in_insem_staff_id       INT,
    in_date_insemination    VARCHAR(10)  /* in YYYY-MM-DD format*/

)

BEGIN

/** 
 * Will update pig_production entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_STATUS_NOT_GESTATING   INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA INT             DEFAULT 21;
DECLARE RES_NUM_PIG_PROD_PIGLETS_ARE_EXTERNAL   INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE INSEMINATION_TYPE_BOAR                  VARCHAR(2)      DEFAULT 'B';
DECLARE INSEMINATION_TYPE_ARTIFICIAL_EXTERNAL   VARCHAR(4)      DEFAULT 'AI_X';
DECLARE INSEMINATION_TYPE_ARTIFICIAL_INTERNAL   VARCHAR(4)      DEFAULT 'AI_N';


/* pig_production.flag bits*/
DECLARE FLAG_BIT_PIGLETS_ARE_EXTERNAL           INT             DEFAULT 2;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_insemination          DATE            DEFAULT NULL;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;
DECLARE cur_pig_prod_insem_notes_id             INT             DEFAULT 0;

DECLARE cur_insemination_type                   VARCHAR(4)      DEFAULT NULL;

DECLARE cur_pig_prod_date_actual_birth          DATE;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        sow_id,
        prod_status_id,
        date_insemination,
        flag,
        insem_notes_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_insemination,
        cur_pig_prod_flag,
        cur_pig_prod_insem_notes_id
FROM    pig_production
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
    SET res_num     = RES_NUM_PIG_PROD_STATUS_NOT_GESTATING;
    SET res_code    = "RES_NUM_PIG_PROD_STATUS_NOT_GESTATING";
    
    LEAVE process_user;
END IF;


IF cur_pig_prod_flag & FLAG_BIT_PIGLETS_ARE_EXTERNAL THEN 
    SET res_num     = RES_NUM_PIG_PROD_PIGLETS_ARE_EXTERNAL;
    SET res_code    = "RES_NUM_PIG_PROD_PIGLETS_ARE_EXTERNAL";
    SET res_desc    = "Cannot update insemination data if piglets are external.";
    
    LEAVE process_user;
END IF;


SELECT  date_actual_birth
INTO    cur_pig_prod_date_actual_birth
FROM    pig_production
WHERE   id = in_pig_prod_id;


IF cur_pig_prod_date_actual_birth IS NOT NULL THEN 

    SET res_num     = RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA;
    SET res_code    = "RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA";
    SET res_desc    = "Cannot update insemination data after birth.";
    
    LEAVE process_user;

END IF;


/* Check if semen is coming from external supplier*/
IF in_boar_id > 0 THEN 
    SET cur_insemination_type = INSEMINATION_TYPE_BOAR;
ELSE 

    IF in_semen_sup_semen_id > 0 THEN 
        SET cur_insemination_type = INSEMINATION_TYPE_ARTIFICIAL_EXTERNAL;
        
    ELSE
        IF in_semen_ai_boar_id > 0 THEN 
            SET cur_insemination_type = INSEMINATION_TYPE_ARTIFICIAL_INTERNAL;
        END IF;
        
    END IF;
END IF;


UPDATE pig_production SET
    insemination_type       = cur_insemination_type,
    
    boar_id                 = in_boar_id,
        
    semen_supplier_id       = in_semen_supplier_id,
    semen_sup_semen_id      = in_semen_sup_semen_id,
    semen_ai_boar_id        = in_semen_ai_boar_id,
        
    semen_cost              = in_semen_cost,
    insemination_cost       = in_insemination_cost,
        
    date_insemination       = in_date_insemination,
    date_expected_birth     = DATE_ADD(in_date_insemination, INTERVAL 115 DAY),
        
    insem_staff_id          = in_insem_staff_id,
        
    last_update_user_id     = in_user_id,
    dt_last_update          = CURRENT_TIMESTAMP,
    
    data_ver_num_pig_prod   = data_ver_num_pig_prod + 1
    
WHERE id =  in_pig_prod_id;


IF cur_pig_prod_insem_notes_id > 0 THEN 
    UPDATE pig_prod_notes SET
        date_notes          = in_date_insemination,
        notes               = in_comments,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP

    WHERE id = cur_pig_prod_insem_notes_id;

ELSE
    IF in_comments IS NOT NULL THEN 
        INSERT INTO pig_prod_notes (
            pig_prod_id,
            sow_boar_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            in_pig_prod_id,
            cur_pig_prod_sow_id,
            
            in_comments,
            in_date_insemination,
            in_user_id
        );
        
        SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
        
        /* pig_production.insem_notes_id*/
        UPDATE pig_production SET
            insem_notes_id = cur_pig_prod_notes_id
        WHERE id = in_pig_prod_id;
    END IF;
    
END IF;


IF cur_pig_prod_date_insemination != in_date_insemination THEN 
    UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
        a.date_target = DATE_ADD(in_date_insemination, INTERVAL b.num_days_since DAY)
    WHERE   a.pig_prod_id = in_pig_prod_id AND 
            a.operation_type = PIG_OPERATION_TYPE_GESTATING AND
            a.account_pig_ops_id = b.id;
END IF;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_eartag_a_pig $$
CREATE PROCEDURE pig_prod_eartag_a_pig(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_sex                  CHAR(1),
    
    in_number               VARCHAR(10),
    in_date_eartag          VARCHAR(10)
    
)  

BEGIN

/** 
 * Will eartag a pig in production. Will assume that the eartagged pig will
 * be either be made into a Gilt or a Boar.
 * 
 * Notes: 
 * 1.) This is not the same action as eartagging an already recorded sow or 
 * newly bought gilts and putting eartags on them. This is eartagging a pig 
 * that has a pig_prod_id so that the sow_boar.birth_pig_prod_id and other 
 * birth details can be populated.
 * 
 * 2.) Eartagged pigs are listed as gilts if female and boar if male.
 * If female it should automatically create scheduled gilt ops.  
 *
 * 3.) The eartagged pigs are not treated as pig_harvest and the pig_count
 * in the production stays the same.       
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since January 19, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_STATUS_CANNOT_EARTAG   INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;



DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE SOW_STATUS_ID_WEANING                   INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;


DECLARE cur_pig_farm_last_sow_id                INT             DEFAULT 0;
DECLARE cur_pig_farm_last_boar_id               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        prod_status_id,
        flag,
        
        sow_id,
        boar_id,
        date_actual_birth
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        cur_pig_prod_flag
        cur_pig_prod_date_actual_birth
        
FROM    pig_production 
WHERE   id = in_pig_prod_id
LIMIT   1;


SELECT  
        last_sow_id,
        last_boar_id
INTO    
        cur_pig_farm_last_sow_id,
        cur_pig_farm_last_boar_id
FROM    pig_farm
WHERE   id = cur_pig_prod_pig_farm_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN


IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



IF cur_pig_prod_status_id NOT IN(   PRODUCTION_STATUS_ID_LACTATING,
                                    PRODUCTION_STATUS_ID_WEANING,
                                    PRODUCTION_STATUS_ID_GROWING) THEN 
    SET res_num     = RES_NUM_PIG_PROD_STATUS_CANNOT_EARTAG;
    SET res_code    = "RES_NUM_PIG_PROD_STATUS_CANNOT_EARTAG";
END IF;



/** INSERT sow_boar entry*/

IF in_sex = 'F' THEN 
    SET cur_pig_farm_last_sow_id = cur_pig_farm_last_sow_id + 1;
    
    
    INSERT INTO sow_boar(
        account_id,
        pig_farm_id,
        farm_sow_id,
        
        sow_status_id,
        
        parent_sow_id,
        parent_boar_id,
        
        sex,
        
        number,
        date_of_birth,
        
        added_by_user_id
    ) VALUES (
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_farm_last_sow_id,
        
        in_sow_status_id,
        
        in_parent_sow_id,
        in_parent_boar_id,
        
        in_sex,
        
        in_number,
        in_date_of_birth,
        
        in_user_id
    );


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
    
    
END IF;

SELECT LAST_INSERT_ID() INTO cur_sow_boar_id;



UPDATE pig_farm SET 
    last_sow_id     = cur_pig_farm_last_sow_id,
    last_boar_id    = cur_pig_farm_last_boar_id
WHERE id = cur_pig_prod_pig_farm_id;





END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_prod_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_weaning $$
CREATE PROCEDURE pig_prod_update_weaning(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_date_weaning         VARCHAR(10),
    
    in_num_pigs_female      INT,
    in_num_pigs_male        INT,
    
    /* There is an option to count the pigs 
    regardless of sex. This is because it maybe time 
    consuming to count per sex at wean. */
    in_num_pigs             INT,    
    
    in_total_weight         DECIMAL(6,2),
    in_per_pig_weight       VARCHAR(200)
)  

BEGIN

/** 
 * Will update weaning data for pig_production entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 27, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_UPDATE_WEAN_NOT_ALLOWED         INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;



DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE SOW_STATUS_ID_WEANING                   INT             DEFAULT 4;

DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;
DECLARE cur_pig_prod_date_weaning               DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;

DECLARE cur_count_account_pig_ops               INT             DEFAULT 0;
DECLARE cur_count_pig_prod_pig_ops              INT             DEFAULT 0;


DECLARE cur_num_pigs_weaning_m                  INT             DEFAULT 0;
DECLARE cur_num_pigs_weaning_f                  INT             DEFAULT 0;
DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;

DECLARE cur_num_pigs                            INT             DEFAULT 0;


DECLARE date_temp                               DATE            DEFAULT NULL;
DECLARE detected_date_weaning_change            INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        sow_id,
        prod_status_id,
        flag,
        date_weaning
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_status_id,
        cur_pig_prod_flag,
        cur_pig_prod_date_weaning
        
FROM    pig_production 
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN


IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_LACTATING,
                                    PRODUCTION_STATUS_ID_WEANING) THEN 
    SET res_num     = RES_NUM_UPDATE_WEAN_NOT_ALLOWED;
    SET res_code    = "RES_NUM_UPDATE_WEAN_NOT_ALLOWED";
    SET res_desc    = "Production status not LACTATING or WEANING.";
    
    LEAVE process_user;
END IF;



/*
It is possible to change the pig_production.date_weaning after previously SET, 
but there is a series of operations to be done to the affected business objects. 
So that is why we need to check if the date_actual_birth is to be modified.
*/

IF cur_pig_prod_date_weaning IS NULL THEN 
    SET detected_date_weaning_change = 1;

ELSE
    SET date_temp = STR_TO_DATE(in_date_weaning, '%Y-%m-%d');
    
    IF date_temp != cur_pig_prod_date_weaning THEN 
        SET detected_date_weaning_change = 1;
    END IF;

END IF;




IF in_num_pigs IS NOT NULL THEN 
    UPDATE pig_production SET
        date_weaning                = in_date_weaning,
        prod_status_id              = PRODUCTION_STATUS_ID_WEANING,

        num_pigs_weaning_m          = NULL,
        num_pigs_weaning_f          = NULL,
        num_pigs_weaning            = in_num_pigs,

        num_pigs_current            = in_num_pigs,
        
        wean_pigs_weight_total      = in_total_weight,
        wean_pigs_weight_pp         = in_per_pig_weight,
        
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP,
        
        data_ver_num_pig_prod       = data_ver_num_pig_prod + 1
        
    WHERE id = in_pig_prod_id;
    
ELSE
    UPDATE pig_production SET
        date_weaning                = in_date_weaning,
        prod_status_id              = PRODUCTION_STATUS_ID_WEANING,

        num_pigs_weaning_m          = in_num_pigs_male,
        num_pigs_weaning_f          = in_num_pigs_female,
        num_pigs_weaning            = NULL,

        num_pigs_current            = in_num_pigs_male + in_num_pigs_female,
        
        wean_pigs_weight_total      = in_total_weight,
        wean_pigs_weight_pp         = in_per_pig_weight,
        
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP,
        
        data_ver_num_pig_prod       = data_ver_num_pig_prod + 1
        
    WHERE id = in_pig_prod_id;


END IF;


/* SUM the number pigs weaned for this sow. */

SELECT  SUM(num_pigs_weaning_m),
        SUM(num_pigs_weaning_f),
        SUM(num_pigs_weaning)
        
INTO    cur_num_pigs_weaning_m,    
        cur_num_pigs_weaning_f,
        cur_num_pigs_weaning
FROM    pig_production
WHERE   sow_id = cur_pig_prod_sow_id AND date_weaning IS NOT NULL;


SET cur_num_pigs = 0;
IF cur_num_pigs_weaning_m > 0 THEN 
    SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning_m;
END IF;

IF cur_num_pigs_weaning_f > 0 THEN 
    SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning_f;
END IF;

IF cur_num_pigs_weaning > 0 THEN 
    SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning;
END IF;




UPDATE sow_boar SET
    sow_status_id       = SOW_STATUS_ID_WEANING,
    num_pigs_wean       = cur_num_pigs,
    data_ver_num_sow_boar = data_ver_num_sow_boar 
WHERE id = cur_pig_prod_sow_id;



/* Count if there are pig operations to be done for weaning sow set by account.*/
SELECT  COUNT(*)
INTO    cur_count_account_pig_ops
FROM    account_pig_ops
WHERE   account_id = cur_pig_prod_account_id  AND 
        operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS AND 
        (flag & FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED) = 0;


IF cur_count_account_pig_ops > 0 THEN
    /* Count if there are already created pig_ops*/
    SELECT  COUNT(*)
    INTO    cur_count_pig_prod_pig_ops
    FROM    pig_prod_pig_ops
    WHERE   pig_prod_id = in_pig_prod_id AND 
            operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS;

    IF cur_count_pig_prod_pig_ops = 0 THEN 
        /* Create pig_prod_pig_ops entry*/
        CALL pig_prod_pig_ops_add(
            in_user_id,
            
            cur_pig_prod_account_id, 
            PIG_OPERATION_TYPE_WEANING_SOW_OPS,
            in_pig_prod_id,
            in_date_weaning
        );
        
        /* Since this is a weaning sow pig ops, need to relate to SOW.*/
        UPDATE pig_prod_pig_ops SET 
            sow_boar_id = cur_pig_prod_sow_id
        WHERE pig_prod_id = in_pig_prod_id AND operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS;
        
    ELSE
        IF detected_date_weaning_change > 0 THEN
            
            /* Need to adjust Day 1 counting.*/
            /*
            IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH = 0 THEN 
                UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                    a.date_target = DATE_ADD(in_date_weaning, INTERVAL b.num_days_since DAY)
                WHERE   a.pig_prod_id = in_pig_prod_id AND 
                        a.operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS AND
                        a.account_pig_ops_id = b.id;
            
            ELSE
                UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                    a.date_target = DATE_ADD(in_date_weaning, INTERVAL b.num_days_since - 1 DAY)
                WHERE   a.pig_prod_id = in_pig_prod_id AND 
                        a.operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS AND
                        a.account_pig_ops_id = b.id;
            END IF;
            
            */
            
            
            /* in_date_weaning is DAY 0 after wean */
            UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                a.date_target = DATE_ADD(in_date_weaning, INTERVAL b.num_days_since DAY)
            WHERE   a.pig_prod_id = in_pig_prod_id AND 
                    a.operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS AND
                    a.account_pig_ops_id = b.id;
        
        END IF;

    END IF;


END IF;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_prod_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_birth $$
CREATE PROCEDURE pig_prod_update_birth(
    in_user_id                  INT,
    
    in_pig_prod_id              INT,
    
    in_date_actual_birth        VARCHAR(10),  /* in YYYY-MM-DD format*/
    in_num_pigs_dead_at_birth   INT,
    in_num_pigs_live_m          INT,
    in_num_pigs_live_f          INT,
    
    in_birth_staff_id           INT,
    in_done_by_user             INT
    
)

BEGIN

/** 
 * Will update pig_production at piglets birth entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_UPDATE_BIRTH_NOT_ALLOWED        INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE SOW_STATUS_ID_LACTATING                 INT             DEFAULT 3;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;



/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;

DECLARE cur_account_flag_settings               INT             DEFAULT 0;


DECLARE cur_count_births                        INT             DEFAULT 0;

DECLARE cur_num_pigs_weaning_m                  INT             DEFAULT 0;
DECLARE cur_num_pigs_weaning_f                  INT             DEFAULT 0;
DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;

DECLARE cur_num_pigs                            INT             DEFAULT 0;



DECLARE cur_count_account_pig_ops               INT             DEFAULT 0;
DECLARE cur_count_pig_prod_pig_ops              INT             DEFAULT 0;

DECLARE num_days_to_add                         INT             DEFAULT 0;

DECLARE date_temp                               DATE            DEFAULT NULL;
DECLARE detected_actual_date_birth_change       INT             DEFAULT 0;

DECLARE added_new_staff                         INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        sow_id,
        prod_status_id,
        date_actual_birth
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_actual_birth
        
FROM    pig_production
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;




SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = cur_pig_prod_account_id;



IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_GESTATING,
                                    PRODUCTION_STATUS_ID_LACTATING) THEN 
    SET res_num     = RES_NUM_UPDATE_BIRTH_NOT_ALLOWED;
    SET res_code    = "RES_NUM_UPDATE_BIRTH_NOT_ALLOWED";
    SET res_desc    = "Production status not GESTATING or LACTATING.";
    
    LEAVE process_user;
END IF;


/*
It is possible to change the pig_production.date_actual_birth after previously SET,
but there is a series of operations to be done to the affected business objects. 
So that is why we need to check if the date_actual_birth is to be modified.

*/

IF cur_pig_prod_date_actual_birth IS NULL THEN 
    SET detected_actual_date_birth_change = 1;

ELSE
    SET date_temp = STR_TO_DATE(in_date_actual_birth, '%Y-%m-%d');
    
    IF date_temp != cur_pig_prod_date_actual_birth THEN 
        SET detected_actual_date_birth_change = 1;
    END IF;

END IF;


/* If done by user, user will be added to staff list.
Note: not all staff are users
*/
IF in_done_by_user > 0 THEN
    SELECT  pig_farm_staff_id,
            name_first,
            name_last
    
    INTO    cur_user_staff_id,
            cur_user_name_first,
            cur_user_name_last
    FROM    user 
    WHERE   id = in_user_id;
    
    
    IF cur_user_staff_id = 0 THEN 
        INSERT INTO pig_farm_staff (
            account_id,
            pig_farm_id,
            user_id,
            name,
            
            added_by_user_id
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            in_user_id,
            CONCAT(cur_user_name_first, ' ', cur_user_name_last),
            
            in_user_id
        );
        SELECT LAST_INSERT_ID() INTO cur_user_staff_id;
        
        
        UPDATE pig_farm SET 
            data_ver_num_staff = data_ver_num_staff + 1
        WHERE id = cur_pig_prod_pig_farm_id;
        
        
        UPDATE user SET 
            pig_farm_staff_id = cur_user_staff_id
        WHERE id = in_user_id;
        
        SET added_new_staff = 1;
        
    END IF;
    
    
    SET in_birth_staff_id = cur_user_staff_id;
    
END IF;




UPDATE pig_production SET 
    date_actual_birth           = in_date_actual_birth,
    num_days_actual             = DATEDIFF(in_date_actual_birth, date_insemination),
    prod_status_id              = PRODUCTION_STATUS_ID_LACTATING,
    
    num_pigs_dead_at_birth      = in_num_pigs_dead_at_birth,
    num_pigs_live_m             = in_num_pigs_live_m,
    num_pigs_live_f             = in_num_pigs_live_f,
    
    num_pigs_current            = in_num_pigs_live_m + in_num_pigs_live_f,
    
    birth_staff_id              = in_birth_staff_id,
    
    last_update_user_id         = in_user_id,
    dt_last_update              = CURRENT_TIMESTAMP,
    
    data_ver_num_pig_prod       = data_ver_num_pig_prod + 1
    
WHERE id =  in_pig_prod_id;


/** Count how many births for this sow.*/
SELECT  COUNT(*)
INTO    cur_count_births
FROM    pig_production
WHERE   sow_id = cur_pig_prod_sow_id AND date_actual_birth IS NOT NULL;


/** Count how many pigs weaned for this sow and add the number of piglets of this birth.*/
/** Any dead piglets after birth will be corrected in pig_prod_update_wean.  */

/** SUM the number pigs weaned for this sow. */
SELECT  SUM(num_pigs_weaning_m),
        SUM(num_pigs_weaning_f),
        SUM(num_pigs_weaning)
        
INTO    cur_num_pigs_weaning_m,    
        cur_num_pigs_weaning_f,
        cur_num_pigs_weaning
FROM    pig_production
WHERE   sow_id = cur_pig_prod_sow_id AND date_weaning IS NOT NULL;


SET cur_num_pigs = 0;
IF cur_num_pigs_weaning_m > 0 THEN 
    SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning_m;
END IF;

IF cur_num_pigs_weaning_f > 0 THEN 
    SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning_f;
END IF;

IF cur_num_pigs_weaning > 0 THEN 
    SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning;
END IF;

IF in_num_pigs_live_m > 0 THEN 
    SET cur_num_pigs =  cur_num_pigs + in_num_pigs_live_m;
END IF;

IF in_num_pigs_live_f > 0 THEN 
    SET cur_num_pigs =  cur_num_pigs + in_num_pigs_live_f;
END IF;



UPDATE sow_boar SET 
    sow_status_id           = SOW_STATUS_ID_LACTATING,
    num_births              = cur_count_births,
    num_pigs_wean           = cur_num_pigs, 
    data_ver_num_sow_boar   = data_ver_num_sow_boar + 1
WHERE id = cur_pig_prod_sow_id;


/* Count if there are pig operations to be done for lactating sow set by account.*/
SELECT  COUNT(*)
INTO    cur_count_account_pig_ops
FROM    account_pig_ops
WHERE   account_id = cur_pig_prod_account_id  AND 
        operation_type = PIG_OPERATION_TYPE_LACTATING_SOW AND 
        (flag & FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED) = 0;


IF cur_count_account_pig_ops > 0 THEN 
    /* Count if there are already created pig_ops*/
    SELECT  COUNT(*)
    INTO    cur_count_pig_prod_pig_ops
    FROM    pig_prod_pig_ops
    WHERE   pig_prod_id = in_pig_prod_id AND 
            operation_type = PIG_OPERATION_TYPE_LACTATING_SOW;

    IF cur_count_pig_prod_pig_ops = 0 THEN 
        /* Create pig_prod_pig_ops entry*/
        CALL pig_prod_pig_ops_add(
            in_user_id,
            
            cur_pig_prod_account_id, 
            PIG_OPERATION_TYPE_LACTATING_SOW,
            in_pig_prod_id,
            in_date_actual_birth
        );
        
        /* Since this is a lactating sow pig ops, need to relate to SOW.*/
        UPDATE pig_prod_pig_ops SET 
            sow_boar_id = cur_pig_prod_sow_id
        WHERE pig_prod_id = in_pig_prod_id AND operation_type = PIG_OPERATION_TYPE_LACTATING_SOW;
        
    ELSE
        IF detected_actual_date_birth_change > 0 THEN
            
            /* Need to adjust Day 1 counting.*/
            IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH = 0 THEN 
                UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                    a.date_target = DATE_ADD(in_date_actual_birth, INTERVAL b.num_days_since DAY)
                WHERE   a.pig_prod_id = in_pig_prod_id AND 
                        a.operation_type = PIG_OPERATION_TYPE_LACTATING_SOW AND
                        a.account_pig_ops_id = b.id;
            
            ELSE
                UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                    a.date_target = DATE_ADD(in_date_actual_birth, INTERVAL b.num_days_since - 1 DAY)
                WHERE   a.pig_prod_id = in_pig_prod_id AND 
                        a.operation_type = PIG_OPERATION_TYPE_LACTATING_SOW AND
                        a.account_pig_ops_id = b.id;
            END IF;
            
        END IF;

    END IF;

END IF;


/* Count if there are pig operations to be done for lactating piglets set by account.*/
SELECT  COUNT(*)
INTO    cur_count_pig_prod_pig_ops
FROM    pig_prod_pig_ops
WHERE   pig_prod_id = in_pig_prod_id AND 
        operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS;

IF cur_count_pig_prod_pig_ops = 0 THEN 
    /* Create pig_prod_pig_ops entry*/
    CALL pig_prod_pig_ops_add(
        in_user_id,
        
        cur_pig_prod_account_id, 
        PIG_OPERATION_TYPE_LACTATING_PIGLETS,
        in_pig_prod_id,
        in_date_actual_birth
    );

ELSE
    IF detected_actual_date_birth_change > 0 THEN
    
        IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH = 0 THEN
            UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                a.date_target = DATE_ADD(in_date_actual_birth, INTERVAL b.num_days_since DAY)
            WHERE   a.pig_prod_id = in_pig_prod_id AND 
                    a.operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS AND
                    a.account_pig_ops_id = b.id;
        
        ELSE
            UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                a.date_target = DATE_ADD(in_date_actual_birth, INTERVAL b.num_days_since - 1 DAY)
            WHERE   a.pig_prod_id = in_pig_prod_id AND 
                    a.operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS AND
                    a.account_pig_ops_id = b.id;
        END IF;
    END IF;
END IF;


/** Update pig_farm.data_ver_num_pig_prod
Note: This is different from pig_production.data_ver_num_pig_prod;
The update of prod_status from gestating to lactating needs to propagated 
to users of the account.

*/
IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_GESTATING AND 
    detected_actual_date_birth_change > 0 THEN 
    
    UPDATE pig_farm SET 
        data_ver_num_pig_prod = data_ver_num_pig_prod + 1
    WHERE id = cur_pig_prod_pig_farm_id;
    
END IF;
    



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id,
    added_new_staff                     AS added_new_staff;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_notes_update $$
CREATE PROCEDURE pig_prod_notes_update(
    in_user_id              INT,
   
    in_pig_prod_notes_id    INT,
    in_date_notes           VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_notes entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_INACTIVE_STATUS        INT             DEFAULT 20;
DECLARE RES_NUM_SOW_BOAR_INACTIVE_STATUS        INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_group_id                   INT             DEFAULT 0;
DECLARE cur_sow_boar_id                         INT             DEFAULT 0;


DECLARE cur_account_id_to_check                 INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_is_disposed                INT             DEFAULT 0;


DECLARE cur_is_active_status                    INT             DEFAULT 0;


DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  pig_prod_id,
        production_group_id,
        sow_boar_id

INTO    cur_pig_prod_id,
        cur_pig_prod_group_id,
        cur_sow_boar_id

FROM    pig_prod_notes 
WHERE   id = in_pig_prod_notes_id;
 

IF cur_pig_prod_id > 0 THEN 

    SELECT  
            account_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_status_id
            
    FROM    pig_production
    WHERE   id = cur_pig_prod_id
    LIMIT   1;


    SET cur_account_id_to_check = cur_pig_prod_account_id;

END IF;

IF cur_sow_boar_id > 0 THEN 

    SELECT  
            account_id,
            is_disposed
    INTO    
            cur_sow_boar_account_id,
            cur_sow_boar_is_disposed
            
    FROM    sow_boar
    WHERE   id = cur_sow_boar_id
    LIMIT   1;


    SET cur_account_id_to_check = cur_sow_boar_account_id;

END IF;



CALL basic_user_check(
        in_user_id, 
        1, /* user must have an account*/
        cur_account_id_to_check, /* compare user.account_id to this account_id*/
        
        BUSINESS_OBJ_ID_PIG_PROD_NOTES,
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


IF cur_pig_prod_id > 0 THEN 
    SET cur_is_active_status = 0;
    CALL pig_prod_check_active_status(cur_pig_prod_status_id, cur_is_active_status);
    
    IF cur_is_active_status = 0 THEN 
        SET res_num     = RES_NUM_PIG_PROD_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_PIG_PROD_INACTIVE_STATUS";
    
        LEAVE process_user;
    END IF;
    
END IF;


IF cur_sow_boar_id > 0 THEN 
    IF cur_sow_boar_is_disposed > 0 THEN 
        SET res_num     = RES_NUM_SOW_BOAR_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_SOW_BOAR_INACTIVE_STATUS";
    
        LEAVE process_user;
    END IF;

END IF;




UPDATE pig_prod_notes SET
    date_notes          = in_date_notes,
    notes               = in_notes,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_pig_prod_notes_id;


IF cur_sow_boar_id > 0 THEN 
    UPDATE sow_boar SET
        data_ver_num_health_notes = data_ver_num_health_notes + 1 
    WHERE id = cur_sow_boar_id;
END IF;


IF cur_pig_prod_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_health_notes = data_ver_num_health_notes + 1
    WHERE id = cur_pig_prod_id;
END IF;


IF cur_pig_prod_group_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_health_notes = data_ver_num_health_notes + 1
    WHERE id = cur_pig_prod_group_id;
END IF;



END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_notes_id                AS pig_prod_notes_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_notes_delete $$
CREATE PROCEDURE pig_prod_notes_delete(
    in_user_id                  INT,
    
    in_pig_prod_notes_id        INT
)  

BEGIN

/** 
 * Will delete pig_prod_notes entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


/* pig_prod_notes.flag bits*/
DECLARE FLAG_BIT_PIG_PROD_NOTES_IS_DELETED      INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_group_id                   INT             DEFAULT 0;
DECLARE cur_sow_boar_id                         INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_account_id           INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  pig_prod_id,
        production_group_id,
        sow_boar_id

INTO    cur_pig_prod_id,
        cur_pig_prod_group_id,
        cur_sow_boar_id

FROM    pig_prod_notes 
WHERE   id = in_pig_prod_notes_id;



IF cur_pig_prod_id > 0 THEN 

    SELECT  
            account_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_status_id
            
    FROM    pig_production
    WHERE   id = in_pig_prod_notes_id
    LIMIT   1;

ELSE

    SELECT  
            account_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_status_id
            
    FROM    production_group
    WHERE   id = cur_pig_prod_group_id
    LIMIT   1;

END IF;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


UPDATE pig_prod_notes SET
    flag                = flag | FLAG_BIT_PIG_PROD_NOTES_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_pig_prod_notes_id;



IF cur_sow_boar_id > 0 THEN 
    UPDATE sow_boar SET
        data_ver_num_health_notes = data_ver_num_health_notes + 1 
    WHERE id = cur_sow_boar_id;
END IF;


IF cur_pig_prod_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_health_notes = data_ver_num_health_notes + 1
    WHERE id = cur_pig_prod_id;
END IF;


IF cur_pig_prod_group_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_health_notes = data_ver_num_health_notes + 1
    WHERE id = cur_pig_prod_group_id;
END IF;




END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_notes_id                AS pig_prod_notes_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_notes_add $$
CREATE PROCEDURE pig_prod_notes_add(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_sow_boar_id          INT,
    in_production_group_id  INT,
    
    in_is_health_issue      INT,
    
    in_date_notes           VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will create pig_prod_notes entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_INACTIVE_STATUS        INT             DEFAULT 20;
DECLARE RES_NUM_SOW_BOAR_INACTIVE_STATUS        INT             DEFAULT 21;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;


/* pig_prod_notes.flag bits*/
DECLARE FLAG_BIT_PIG_PROD_NOTES_IS_DELETED      INT             DEFAULT 1;
DECLARE FLAG_BIT_NOTES_IS_PIG_HEALTH_ISSUE      INT             DEFAULT 2;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_id_to_check                 INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_is_disposed                INT             DEFAULT 0;


DECLARE cur_is_active_status                    INT             DEFAULT 0;


DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;



DECLARE cur_flag                                INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id
    
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    pig_production 
    WHERE   id = in_pig_prod_id
    LIMIT   1;
    
    SET cur_account_id_to_check = cur_pig_prod_account_id;
END IF;


IF in_sow_boar_id > 0 THEN 
    SELECT  
            account_id,
            pig_farm_id,
            is_disposed
    INTO 
            cur_sow_boar_account_id,
            cur_sow_boar_pig_farm_id,
            cur_sow_boar_is_disposed
            
    FROM    sow_boar
    WHERE   id = in_sow_boar_id;

    SET cur_account_id_to_check = cur_sow_boar_account_id;
END IF;


IF in_production_group_id > 0 THEN 
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    production_group 
    WHERE   id = in_production_group_id
    LIMIT   1;
    
    SET cur_account_id_to_check = cur_pig_prod_account_id;
END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_id_to_check, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
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

    SET cur_is_active_status = 0;
    CALL pig_prod_check_active_status(cur_pig_prod_status_id, cur_is_active_status);
    
    IF cur_is_active_status = 0 THEN 
        SET res_num     = RES_NUM_PIG_PROD_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_PIG_PROD_INACTIVE_STATUS";
    
        LEAVE process_user;
    END IF;
    

END IF;


IF in_sow_boar_id > 0 THEN 
    IF cur_sow_boar_is_disposed > 0 THEN 
        SET res_num     = RES_NUM_SOW_BOAR_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_SOW_BOAR_INACTIVE_STATUS";
    
        LEAVE process_user;
    END IF;

END IF;







IF  in_is_health_issue > 0 THEN 
    SET cur_flag = FLAG_BIT_NOTES_IS_PIG_HEALTH_ISSUE;
END IF;

INSERT INTO pig_prod_notes (
    account_id,
    pig_farm_id,
    pig_prod_id,
    sow_boar_id,
    production_group_id,
    flag,
    
    notes,
    date_notes,
    added_by_user_id
    
) VALUES (
    cur_pig_prod_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    in_sow_boar_id,
    in_production_group_id,
    cur_flag,
    
    in_notes,
    in_date_notes,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;



IF in_sow_boar_id > 0 THEN 
    UPDATE sow_boar SET
        data_ver_num_health_notes = data_ver_num_health_notes + 1 
    WHERE id = in_sow_boar_id;
END IF;


IF in_pig_prod_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_health_notes = data_ver_num_health_notes + 1
    WHERE id = in_pig_prod_id;
END IF;


IF in_production_group_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_health_notes = data_ver_num_health_notes + 1
    WHERE id = in_production_group_id;
END IF;




END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_notes_id               AS pig_prod_notes_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_pen_delete $$
CREATE PROCEDURE pig_pen_delete(
    in_user_id                  INT,
    
    in_pig_pen_id               INT
)  

BEGIN

/** 
 * Will delete pig_pen entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_PEN                 INT             DEFAULT 33;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* pig_pen.flag bits*/
DECLARE FLAG_BIT_PIG_PEN_IS_DELETED             INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_pen_account_id                  INT             DEFAULT 0;
DECLARE cur_pig_pen_flag                        INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_pen_account_id
FROM    pig_pen
WHERE   id = in_pig_pen_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_pen_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PEN,
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



UPDATE pig_pen SET
    flag                = flag | FLAG_BIT_PIG_PEN_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_pig_pen_id;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_pen_id                       AS pig_pen_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_pen_add $$
CREATE PROCEDURE pig_pen_add(
    in_user_id              INT,

    in_pig_farm_id          INT,
    in_pig_pen_type_id      INT,
    
    in_name                 VARCHAR(20)
)  

BEGIN

/** 
 * Will add pen entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PEN                 INT             DEFAULT 33;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_pen_id                          INT             DEFAULT 0;
DECLARE cur_pig_pen_flag                        INT             DEFAULT 0;
DECLARE cur_pig_pen_name                        VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PIG_PEN,
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


/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_pen_id
FROM    pig_pen
WHERE   pig_farm_id         = in_pig_farm_id   AND
        pig_pen_type_id     = in_pig_pen_type_id AND 
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_pig_pen_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO pig_pen(
    account_id,
    pig_farm_id,
    pig_pen_type_id,
    
    name,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_pig_farm_id,
    in_pig_pen_type_id,
    
    in_name,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_pen_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_pen_id                      AS pig_pen_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_pig_pen_update $$
CREATE PROCEDURE pig_pig_pen_update(
    in_user_id                  INT,
    
    in_pig_pig_pen_id           INT,
    
    in_pig_pen_type_id          INT,
    
    in_name                     VARCHAR(20)
    
)

BEGIN

/** 
 * Will update pig_pig_pen entry.
 * @author Jack Wong
 * @since September 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PEN                 INT             DEFAULT 12;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_pig_pen_id                      INT             DEFAULT 0;
DECLARE cur_pig_pig_pen_account_id              INT             DEFAULT 0;
DECLARE cur_pig_pig_pen_flag                    INT             DEFAULT 0;
DECLARE cur_pig_pig_pen_name                    VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_pig_pen_account_id
FROM    pig_pig_pen
WHERE   id = in_pig_pig_pen_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_pig_pen_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PEN,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_pig_pen_id
FROM    pig_pig_pen
WHERE   id                  != in_pig_pig_pen_id  AND
        pig_farm_id         = in_pig_farm_id   AND
        pig_pen_type_id     = in_pig_pen_type_id AND 
        UPPER(name)         = UPPER(in_name)
LIMIT   1;


IF cur_pig_pig_pen_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



UPDATE pig_pig_pen SET
    pig_pen_type_id     = in_pig_pen_type_id,
    
    name                = in_name,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_pig_pen_id;

END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_pig_pen_id                   AS pig_pig_pen_id;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_access_code_add $$
CREATE PROCEDURE account_access_code_add(
    in_user_id              INT,
    
    in_user_group_num       INT)  

BEGIN

/** 
 * Will add account access code entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since March 18, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;



DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_user_group_id               INT             DEFAULT 0;

DECLARE cur_account_access_code_id              INT             DEFAULT 0;



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


SELECT  id
INTO    cur_account_user_group_id
FROM    user_group
WHERE   account_id = cur_user_account_id AND  group_num = in_user_group_num;


INSERT INTO account_access_code(
    account_id,
    issued_by_user_id,
    user_group_id
) VALUES (
    cur_user_account_id,
    in_user_id,
    cur_account_user_group_id
);

SELECT LAST_INSERT_ID() INTO cur_account_access_code_id;



 

END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_access_code_id          AS access_code_id,
    cur_user_account_id                 AS user_account_id, 
    cur_user_group_id                   AS user_group_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_access_code_update $$
CREATE PROCEDURE account_access_code_update(
    in_user_id              INT,
    
    in_access_code_id      INT,
    
    in_user_group_id        INT)  

BEGIN

/** 
 * Will update  account access code entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since March 18, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;



DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_access_code_account_id              INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  account_id
INTO    cur_access_code_account_id
FROM    account_access_code
WHERE   id = in_access_code_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_access_code_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



UPDATE account_access_code SET 
    user_group_id = in_user_group_id
WHERE id = in_access_code_id;



 

END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_access_code_id                   AS access_code_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS customer_feedback_add $$
CREATE PROCEDURE customer_feedback_add(
    in_user_id              INT,
    
    in_notes                VARCHAR(500)
)  

BEGIN

/** 
 * Will create customer_feedback entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since March 12, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_customer_feedback_id                INT             DEFAULT 0;


DECLARE cur_flag                                INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";




CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
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



INSERT INTO customer_feedback (
    account_id,
    user_id,
    
    notes
    
) VALUES (
    cur_user_account_id,
    in_user_id,
    in_notes
);

SELECT LAST_INSERT_ID() INTO cur_customer_feedback_id;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_customer_feedback_id            AS customer_feedback_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_staff_add $$
CREATE PROCEDURE pig_farm_staff_add(
    in_user_id                  INT,

    in_pig_farm_id              INT,
    in_set_user_as_staff        INT,
    in_name                     VARCHAR(50)

)  

BEGIN

/** 
 * Will add pig_farm_staff entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF          INT             DEFAULT 10;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_staff_id                   INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_flag                 INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_name                 VARCHAR(50)     DEFAULT '';

DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PIG_FARM_STAFF,
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


/* Check for duplicate entry */
IF in_set_user_as_staff = 0 THEN 

    SELECT  id
    INTO    cur_pig_farm_staff_id
    FROM    pig_farm_staff
    WHERE   account_id = cur_user_account_id    AND
            pig_farm_id = in_pig_farm_id        AND
            UPPER(name)  = UPPER(in_name)
    LIMIT   1;

ELSE
    SELECT  id
    INTO    cur_pig_farm_staff_id
    FROM    pig_farm_staff
    WHERE   account_id = cur_user_account_id    AND
            pig_farm_id = in_pig_farm_id        AND
            user_id  = in_user_id
    LIMIT   1;
END IF;


IF cur_pig_farm_staff_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


IF in_set_user_as_staff > 0 THEN 
    SELECT  name_first,
            name_last
    
    INTO    cur_user_name_first,
            cur_user_name_last
    FROM    user
    WHERE   id =  in_user_id;

    SET in_name = CONCAT(cur_user_name_first, ' ', cur_user_name_last);

    INSERT INTO pig_farm_staff(
        account_id,
        pig_farm_id,
        user_id,
        name,
        
        added_by_user_id
    ) VALUES (
        cur_user_account_id,
        in_pig_farm_id,
        in_user_id,
        in_name,
        
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_farm_staff_id;

ELSE
    
    INSERT INTO pig_farm_staff(
        account_id,
        pig_farm_id,
        name,
        
        added_by_user_id
    ) VALUES (
        cur_user_account_id,
        in_pig_farm_id,
        in_name,
        
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_farm_staff_id;

END IF;


UPDATE pig_farm SET 
    data_ver_num_staff = data_ver_num_staff + 1
WHERE id = in_pig_farm_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_staff_flag,
    cur_pig_farm_staff_name
FROM pig_farm_staff
WHERE id = cur_pig_farm_staff_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_staff_id               AS pig_farm_id,
    cur_pig_farm_staff_flag             AS pig_farm_flag,
    cur_pig_farm_staff_name             AS pig_farm_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_staff_delete $$
CREATE PROCEDURE pig_farm_staff_delete(
    in_user_id                  INT,
    
    in_pig_farm_staff_id         INT
)  

BEGIN

/** 
 * Will delete pig_farm_staff entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF           INT            DEFAULT 6;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";

/* pig_farm_staff.flag bits*/
DECLARE FLAG_BIT_PIG_FARM_STAFF_IS_DELETED      INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_flag                 INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_name                 VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        pig_farm_id
        
INTO    cur_pig_farm_account_id,
        cur_pig_farm_id
        
FROM    pig_farm_staff
WHERE   id = in_pig_farm_staff_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_FARM_STAFF,
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



UPDATE pig_farm_staff SET
    flag                = flag | FLAG_BIT_PIG_FARM_STAFF_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_pig_farm_staff_id;


UPDATE pig_farm SET 
    data_ver_num_staff = data_ver_num_staff + 1
WHERE id = cur_pig_farm_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_staff_flag,
    cur_pig_farm_staff_name
FROM pig_farm_staff
WHERE id = in_pig_farm_staff_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_farm_staff_id                AS pig_farm_staff_id,
    cur_pig_farm_staff_flag             AS pig_farm_staff_flag,
    cur_pig_farm_staff_name             AS pig_farm_staff_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_staff_update $$
CREATE PROCEDURE pig_farm_staff_update(
    in_user_id                  INT,
    
    in_pig_farm_staff_id        INT,
    in_staff_user_id            INT,
    
    in_name                     VARCHAR(50)
    
)

BEGIN

/** 
 * Will update pig_farm_staff entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF          INT             DEFAULT 6;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_staff_id                   INT             DEFAULT 0;
DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_flag                 INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_name                 VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  account_id,
        pig_farm_id
        
INTO    cur_pig_farm_account_id,
        cur_pig_farm_id
        
FROM    pig_farm_staff
WHERE   id = in_pig_farm_staff_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_FARM_STAFF,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_farm_staff_id
FROM    pig_farm_staff
WHERE   id                  != in_pig_farm_staff_id  AND
        account_id          = cur_user_account_id   AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_pig_farm_staff_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



UPDATE pig_farm_staff SET
    name                = in_name,
    
    user_id             = in_staff_user_id,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_farm_staff_id;


UPDATE pig_farm SET 
    data_ver_num_staff = data_ver_num_staff + 1
WHERE id = cur_pig_farm_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_staff_flag,
    cur_pig_farm_staff_name
FROM pig_farm_staff
WHERE id = in_pig_farm_staff_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_farm_staff_id                AS pig_farm_staff_id,
    cur_pig_farm_staff_flag             AS pig_farm_staff_flag,
    cur_pig_farm_staff_name             AS pig_farm_staff_name;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_feed_add $$
CREATE PROCEDURE pig_prod_feed_add(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_pig_farm_feed_buy_id INT,
    
    in_date_add             VARCHAR(10),
    
    
    in_num_gesta            INT, /** must be > 0; can be NULL; */
    in_num_lacta            INT, /** must be > 0; can be NULL; */   
    in_num_booster          INT, /** must be > 0; can be NULL; */
    in_num_prestarter       INT, /** must be > 0; can be NULL; */
    in_num_starter          INT, /** must be > 0; can be NULL; */
    in_num_grower           INT, /** must be > 0; can be NULL; */
    in_num_finisher         INT  /** must be > 0; can be NULL; */

) 
 
BEGIN
/**
 * Will add pig_prod_feed entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 13, 2026
 */





DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_PIG_PROD_INACTIVE_STATUS        INT             DEFAULT 20;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;

DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

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



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_is_active_status                    INT             DEFAULT 0;

DECLARE cur_pig_prod_feed_id                    INT             DEFAULT 0;


DECLARE cur_feed_item_gesta_id                  INT             DEFAULT 0;
DECLARE cur_feed_item_lacta_id                  INT             DEFAULT 0;
DECLARE cur_feed_item_booster_id                INT             DEFAULT 0;
DECLARE cur_feed_item_prestarter_id             INT             DEFAULT 0;
DECLARE cur_feed_item_starter_id                INT             DEFAULT 0;
DECLARE cur_feed_item_grower_id                 INT             DEFAULT 0;
DECLARE cur_feed_item_finisher_id               INT             DEFAULT 0;


DECLARE cur_feed_buy_id                         INT             DEFAULT 0; 
DECLARE cur_feed_buy_feed_brand_id              INT             DEFAULT 0;
DECLARE cur_feed_buy_feed_supplier_id           INT             DEFAULT 0;
        
DECLARE cur_feed_buy_kg_per_unit                DECIMAL(5,1)    DEFAULT NULL;        
DECLARE cur_feed_buy_unit_cost                  DECIMAL(8,2)    DEFAULT NULL;



DECLARE cur_feed_quantity                       INT             DEFAULT 0;
DECLARE cur_feed_weight_kg                      DECIMAL(6,1)    DEFAULT NULL;
DECLARE cur_total_cost                          DECIMAL(8,2)    DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  account_id,
        prod_status_id
        
INTO    cur_pig_prod_account_id,
        cur_pig_prod_status_id
        
FROM    pig_production 
WHERE   id = in_pig_prod_id;

CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    BUSINESS_OBJ_ID_FEED_BUY,
    FLAG_BIT_OPERATION_ADD,
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user: BEGIN
IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



SET cur_is_active_status = 0;
CALL pig_prod_check_active_status(cur_pig_prod_status_id, cur_is_active_status);

IF cur_is_active_status = 0 THEN 
    SET res_num     = RES_NUM_PIG_PROD_INACTIVE_STATUS;
    SET res_code    = "RES_NUM_PIG_PROD_INACTIVE_STATUS";

    LEAVE process_user;
END IF;


/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_prod_feed_id
FROM    pig_prod_feed
WHERE   pig_prod_id         = in_pig_prod_id    AND
        date_add            = in_date_add       AND
        pig_farm_feed_buy_id= in_pig_farm_feed_buy_id
LIMIT   1;

IF cur_pig_prod_feed_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    LEAVE process_user;
END IF;





/* Insert to pig_prod_feed;*/

INSERT INTO pig_prod_feed(
    pig_prod_id,              
    pig_farm_feed_buy_id,
    
    date_add,    
    added_by_user_id         
    
) VALUES (
    in_pig_prod_id,              
    in_pig_farm_feed_buy_id,
    
    in_date_add,    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_feed_id;


/* Insert to feed_buy;*/
IF in_num_gesta > 0 THEN 
    SET cur_feed_buy_id = 0;

    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = in_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_GESTATING
    LIMIT   1;
    
    
    IF cur_feed_buy_id > 0 THEN 
    
        INSERT INTO feed_buy(
            pig_prod_id,
            pig_prod_feed_id,
            
            date_buy,
            
            feed_type_id,
            feed_brand_id,
            feed_supplier_id,
            
            quantity,
            kg_per_unit,
            kg_total,
            
            unit_cost,
            total_cost,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_id,
            cur_pig_prod_feed_id,
            
            in_date_add,
            
            FEED_TYPE_ID_GESTATING,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
            
            in_num_gesta,
            cur_feed_buy_kg_per_unit,
            in_num_gesta * cur_feed_buy_kg_per_unit,
            
            cur_feed_buy_unit_cost,
            in_num_gesta * cur_feed_buy_unit_cost,
            
            in_user_id
        );

        
        
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_GESTATING;

        
        UPDATE pig_production SET 
            num_b_gestating     = cur_feed_quantity,
            num_b_kg_gestating  = cur_feed_weight_kg,
            cost_gestating      = cur_total_cost
        WHERE id = in_pig_prod_id;
    
    END IF;
    
END IF;     


IF in_num_lacta > 0 THEN 
    SET cur_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = in_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_LACTATING
    LIMIT   1;
    
    
    IF cur_feed_buy_id > 0 THEN
        INSERT INTO feed_buy(
            pig_prod_id,
            pig_prod_feed_id,
            
            date_buy,
            
            feed_type_id,
            feed_brand_id,
            feed_supplier_id,
            
            quantity,
            kg_per_unit,
            kg_total,
            
            unit_cost,
            total_cost,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_id,
            cur_pig_prod_feed_id,
            
            in_date_add,
            
            FEED_TYPE_ID_LACTATING,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
            
            in_num_lacta,
            cur_feed_buy_kg_per_unit,
            in_num_lacta * cur_feed_buy_kg_per_unit,
            
            cur_feed_buy_unit_cost,
            in_num_lacta * cur_feed_buy_unit_cost,
            
            in_user_id
        );

        
        
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_LACTATING;

        
        UPDATE pig_production SET 
            num_b_lactating     = cur_feed_quantity,
            num_b_kg_lactating  = cur_feed_weight_kg,
            cost_lactating      = cur_total_cost
        WHERE id = in_pig_prod_id;
    
    END IF;
    
END IF;     


IF in_num_booster > 0 THEN 
    SET cur_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = in_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_BOOSTER
    LIMIT   1;
    
    
    IF cur_feed_buy_id > 0 THEN 
        INSERT INTO feed_buy(
            pig_prod_id,
            pig_prod_feed_id,
            
            date_buy,
            
            feed_type_id,
            feed_brand_id,
            feed_supplier_id,
            
            quantity,
            kg_per_unit,
            kg_total,
            
            unit_cost,
            total_cost,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_id,
            cur_pig_prod_feed_id,
            
            in_date_add,
            
            FEED_TYPE_ID_BOOSTER,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
            
            in_num_booster,
            cur_feed_buy_kg_per_unit,
            in_num_booster * cur_feed_buy_kg_per_unit,
            
            cur_feed_buy_unit_cost,
            in_num_booster * cur_feed_buy_unit_cost,
            
            in_user_id
        );

        
        
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_BOOSTER;

        
        UPDATE pig_production SET 
            num_b_booster       = cur_feed_quantity,
            num_b_kg_booster    = cur_feed_weight_kg,
            cost_booster        = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;
    
END IF;     


IF in_num_prestarter > 0 THEN 
    SET cur_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = in_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_PRESTARTER
    LIMIT   1;
    
    
    IF cur_feed_buy_id THEN 
        INSERT INTO feed_buy(
            pig_prod_id,
            pig_prod_feed_id,
            
            date_buy,
            
            feed_type_id,
            feed_brand_id,
            feed_supplier_id,
            
            quantity,
            kg_per_unit,
            kg_total,
            
            unit_cost,
            total_cost,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_id,
            cur_pig_prod_feed_id,
            
            in_date_add,
            
            FEED_TYPE_ID_PRESTARTER,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
            
            in_num_prestarter,
            cur_feed_buy_kg_per_unit,
            in_num_prestarter * cur_feed_buy_kg_per_unit,
            
            cur_feed_buy_unit_cost,
            in_num_prestarter * cur_feed_buy_unit_cost,
            
            in_user_id
        );

        
        
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_PRESTARTER;

        
        UPDATE pig_production SET 
            num_b_prestarter    = cur_feed_quantity,
            num_b_kg_prestarter = cur_feed_weight_kg,
            cost_prestarter     = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;
    
END IF;     


IF in_num_starter > 0 THEN 
    SET cur_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = in_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_STARTER
    LIMIT   1;
    
    
    IF cur_feed_buy_id > 0 THEN 
        INSERT INTO feed_buy(
            pig_prod_id,
            pig_prod_feed_id,
            
            date_buy,
            
            feed_type_id,
            feed_brand_id,
            feed_supplier_id,
            
            quantity,
            kg_per_unit,
            kg_total,
            
            unit_cost,
            total_cost,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_id,
            cur_pig_prod_feed_id,
            
            in_date_add,
            
            FEED_TYPE_ID_STARTER,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
            
            in_num_starter,
            cur_feed_buy_kg_per_unit,
            in_num_starter * cur_feed_buy_kg_per_unit,
            
            cur_feed_buy_unit_cost,
            in_num_starter * cur_feed_buy_unit_cost,
            
            in_user_id
        );
        

    
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_STARTER;

        
        UPDATE pig_production SET 
            num_b_starter       = cur_feed_quantity,
            num_b_kg_starter    = cur_feed_weight_kg,
            cost_starter        = cur_total_cost
        WHERE id = in_pig_prod_id;
    
    END IF;
    
END IF;     


IF in_num_grower > 0 THEN 
    SET cur_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = in_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_GROWER;
    
    
    IF cur_feed_buy_id > 0 THEN 
        INSERT INTO feed_buy(
            pig_prod_id,
            pig_prod_feed_id,
            
            date_buy,
            
            feed_type_id,
            feed_brand_id,
            feed_supplier_id,
            
            quantity,
            kg_per_unit,
            kg_total,
            
            unit_cost,
            total_cost,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_id,
            cur_pig_prod_feed_id,
            
            in_date_add,
            
            FEED_TYPE_ID_GROWER,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
            
            in_num_grower,
            cur_feed_buy_kg_per_unit,
            in_num_grower * cur_feed_buy_kg_per_unit,
            
            cur_feed_buy_unit_cost,
            in_num_grower * cur_feed_buy_unit_cost,
            
            in_user_id
        );

        
        
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_GROWER;

        
        UPDATE pig_production SET 
            num_b_grower        = cur_feed_quantity,
            num_b_kg_grower     = cur_feed_weight_kg,
            cost_grower         = cur_total_cost
        WHERE id = in_pig_prod_id;
    
    END IF;
    
END IF;     

  
IF in_num_finisher > 0 THEN 
    SET cur_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = in_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_FINISHER;
    
    
    IF cur_feed_buy_id > 0 THEN 
        INSERT INTO feed_buy(
            pig_prod_id,
            pig_prod_feed_id,
            
            date_buy,
            
            feed_type_id,
            feed_brand_id,
            feed_supplier_id,
            
            quantity,
            kg_per_unit,
            kg_total,
            
            unit_cost,
            total_cost,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_id,
            cur_pig_prod_feed_id,
            
            in_date_add,
            
            FEED_TYPE_ID_FINISHER,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
            
            in_num_finisher,
            cur_feed_buy_kg_per_unit,
            in_num_finisher * cur_feed_buy_kg_per_unit,
            
            cur_feed_buy_unit_cost,
            in_num_finisher * cur_feed_buy_unit_cost,
            
            in_user_id
        );
        


        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_FINISHER;

        
        UPDATE pig_production SET 
            num_b_finisher      = cur_feed_quantity,
            num_b_kg_finisher   = cur_feed_weight_kg,
            cost_finisher       = cur_total_cost
        WHERE id = in_pig_prod_id;
    
    END IF;
    
END IF;  



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    cur_pig_prod_feed_id                AS pig_prod_feed_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_feed_update $$
CREATE PROCEDURE pig_prod_feed_update(
    in_user_id              INT,
    in_pig_prod_feed_id     INT,
    
    in_date_add             VARCHAR(10),
    
    
    in_num_gesta            INT, /** can be >= 0; cannot be NULL*/
    in_num_lacta            INT, /** can be >= 0; cannot be NULL*/   
    in_num_booster          INT, /** can be >= 0; cannot be NULL*/
    in_num_prestarter       INT, /** can be >= 0; cannot be NULL*/
    in_num_starter          INT, /** can be >= 0; cannot be NULL*/
    in_num_grower           INT, /** can be >= 0; cannot be NULL*/
    in_num_finisher         INT  /** can be >= 0; cannot be NULL*/
    
    
) 
 
BEGIN
/**
 * Will update pig_prod_feed entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 13, 2026
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_PIG_PROD_INACTIVE_STATUS        INT             DEFAULT 20;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;

DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

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


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_feed_buy_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_is_active_status                    INT             DEFAULT 0;


DECLARE cur_prod_feed_buy_id                    INT             DEFAULT 0;

DECLARE cur_pf_feed_buy_id                      INT             DEFAULT 0;
DECLARE cur_feed_buy_feed_brand_id              INT             DEFAULT 0;
DECLARE cur_feed_buy_feed_supplier_id           INT             DEFAULT 0;
        
DECLARE cur_feed_buy_kg_per_unit                DECIMAL(5,1)    DEFAULT NULL;        
DECLARE cur_feed_buy_unit_cost                  DECIMAL(8,2)    DEFAULT NULL;


DECLARE cur_feed_quantity                       INT             DEFAULT 0;
DECLARE cur_feed_weight_kg                      DECIMAL(6,1)    DEFAULT NULL;
DECLARE cur_total_cost                          DECIMAL(8,2)    DEFAULT NULL;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  a.pig_prod_id,
        a.pig_farm_feed_buy_id,
        b.account_id,
        b.prod_status_id
        
INTO    cur_pig_prod_id,
        cur_pig_farm_feed_buy_id,
        cur_pig_prod_account_id,
        cur_pig_prod_status_id
        
FROM    pig_prod_feed a
LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id
WHERE   a.id = in_pig_prod_feed_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    BUSINESS_OBJ_ID_FEED_BUY,
    FLAG_BIT_OPERATION_ADD,
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user: BEGIN
IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



SET cur_is_active_status = 0;
CALL pig_prod_check_active_status(cur_pig_prod_status_id, cur_is_active_status);

IF cur_is_active_status = 0 THEN 
    SET res_num     = RES_NUM_PIG_PROD_INACTIVE_STATUS;
    SET res_code    = "RES_NUM_PIG_PROD_INACTIVE_STATUS";

    LEAVE process_user;
END IF;




UPDATE pig_prod_feed SET 
    date_add = in_date_add
WHERE id = in_pig_prod_feed_id;


/** Update feed items*/


IF in_num_gesta IS NOT NULL THEN 
    /** Check if already added */
    SET     cur_prod_feed_buy_id = 0;

    SELECT  id
    INTO    cur_prod_feed_buy_id
    FROM    feed_buy
    WHERE   pig_prod_feed_id = in_pig_prod_feed_id AND 
            feed_type_id = FEED_TYPE_ID_GESTATING
    LIMIT   1;


    SET     cur_pf_feed_buy_id = 0;

    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_pf_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = cur_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_GESTATING
    LIMIT   1;


    /** Insert newly added feed_buy. */
    IF cur_prod_feed_buy_id = 0 AND in_num_gesta > 0 THEN 
        
        IF cur_pf_feed_buy_id > 0 THEN 
            INSERT INTO feed_buy(
                pig_prod_id,
                pig_prod_feed_id,
                
                date_buy,
                
                feed_type_id,
                feed_brand_id,
                feed_supplier_id,
                
                quantity,
                kg_per_unit,
                kg_total,
                
                unit_cost,
                total_cost,
                
                added_by_user_id

            ) VALUES (
                cur_pig_prod_id,
                cur_pig_prod_feed_id,
                
                in_date_add,
                
                FEED_TYPE_ID_GESTATING,
                cur_feed_buy_feed_brand_id,
                cur_feed_buy_feed_supplier_id,
                
                in_num_gesta,
                cur_feed_buy_kg_per_unit,
                in_num_gesta * cur_feed_buy_kg_per_unit,
                
                cur_feed_buy_unit_cost,
                in_num_gesta * cur_feed_buy_unit_cost,
                
                in_user_id
            );
            
            
            /** Sum up all feeds related to pig_prod_id*/
            SELECT  SUM(quantity),
                    SUM(kg_total),
                    SUM(total_cost)
                    
            INTO    cur_feed_quantity,
                    cur_feed_weight_kg,
                    cur_total_cost
            FROM    feed_buy
            WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_GESTATING;

            
            UPDATE pig_production SET 
                num_b_gestating     = cur_feed_quantity,
                num_b_kg_gestating  = cur_feed_weight_kg,
                cost_gestating      = cur_total_cost
            WHERE id = cur_pig_prod_id;
        END IF;

    END IF;
        
    
    /** Update already inserted feed_buy. */
    IF cur_prod_feed_buy_id > 0 THEN 
        UPDATE feed_buy SET
            date_buy            = in_date_add,

                           
            quantity            = in_num_gesta,
            kg_per_unit         = cur_feed_buy_kg_per_unit,
            kg_total            = in_num_gesta * cur_feed_buy_kg_per_unit,
                      
            unit_cost           = cur_feed_buy_unit_cost,
            total_cost          = in_num_gesta * cur_feed_buy_unit_cost
                           
        WHERE id = cur_prod_feed_buy_id;
    
    
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_GESTATING;

        
        UPDATE pig_production SET 
            num_b_gestating     = cur_feed_quantity,
            num_b_kg_gestating  = cur_feed_weight_kg,
            cost_gestating      = cur_total_cost
        WHERE id = cur_pig_prod_id;
    
    END IF;
    
END IF;




IF in_num_lacta IS NOT NULL THEN 
    /** Check if already added */
    SET     cur_prod_feed_buy_id = 0;

    SELECT  id
    INTO    cur_prod_feed_buy_id
    FROM    feed_buy
    WHERE   pig_prod_feed_id = in_pig_prod_feed_id AND 
            feed_type_id = FEED_TYPE_ID_LACTATING
    LIMIT   1;

    
    SET     cur_pf_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_pf_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = cur_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_LACTATING
    LIMIT   1;


    /** Insert newly added feed_buy. */
    IF cur_prod_feed_buy_id = 0 AND in_num_lacta > 0 THEN 
        
        IF cur_pf_feed_buy_id > 0 THEN 
            INSERT INTO feed_buy(
                pig_prod_id,
                pig_prod_feed_id,
                
                date_buy,
                
                feed_type_id,
                feed_brand_id,
                feed_supplier_id,
                
                quantity,
                kg_per_unit,
                kg_total,
                
                unit_cost,
                total_cost,
                
                added_by_user_id

            ) VALUES (
                cur_pig_prod_id,
                cur_pig_prod_feed_id,
                
                in_date_add,
                
                FEED_TYPE_ID_LACTATING,
                cur_feed_buy_feed_brand_id,
                cur_feed_buy_feed_supplier_id,
                
                in_num_lacta,
                cur_feed_buy_kg_per_unit,
                in_num_lacta * cur_feed_buy_kg_per_unit,
                
                cur_feed_buy_unit_cost,
                in_num_lacta * cur_feed_buy_unit_cost,
                
                in_user_id
            );
            
            
            /** Sum up all feeds related to pig_prod_id*/
            SELECT  SUM(quantity),
                    SUM(kg_total),
                    SUM(total_cost)
                    
            INTO    cur_feed_quantity,
                    cur_feed_weight_kg,
                    cur_total_cost
            FROM    feed_buy
            WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_LACTATING;

            
            UPDATE pig_production SET 
                num_b_lactating     = cur_feed_quantity,
                num_b_kg_lactating  = cur_feed_weight_kg,
                cost_lactating      = cur_total_cost
            WHERE id = cur_pig_prod_id;
        END IF;

    END IF;
        
    
    /** Update already inserted feed_buy. */
    IF cur_prod_feed_buy_id > 0 THEN 
        UPDATE feed_buy SET
            date_buy            = in_date_add,

                           
            quantity            = in_num_lacta,
            kg_per_unit         = cur_feed_buy_kg_per_unit,
            kg_total            = in_num_lacta * cur_feed_buy_kg_per_unit,
                            
            unit_cost           = cur_feed_buy_unit_cost,
            total_cost          = in_num_lacta * cur_feed_buy_unit_cost
                           
        WHERE id = cur_prod_feed_buy_id;
    
    
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_LACTATING;

        
        UPDATE pig_production SET 
            num_b_lactating     = cur_feed_quantity,
            num_b_kg_lactating  = cur_feed_weight_kg,
            cost_lactating      = cur_total_cost
        WHERE id = cur_pig_prod_id;
    
    END IF;
    
END IF;




IF in_num_booster IS NOT NULL THEN 
    /** Check if already added */
    SET     cur_prod_feed_buy_id = 0;

    SELECT  id
    INTO    cur_prod_feed_buy_id
    FROM    feed_buy
    WHERE   pig_prod_feed_id = in_pig_prod_feed_id AND 
            feed_type_id = FEED_TYPE_ID_BOOSTER
    LIMIT   1;

    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_pf_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = cur_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_BOOSTER
    LIMIT   1;


    /** Insert newly added feed_buy. */
    IF cur_prod_feed_buy_id = 0 AND in_num_booster > 0 THEN 
        
        IF cur_pf_feed_buy_id > 0 THEN 
            INSERT INTO feed_buy(
                pig_prod_id,
                pig_prod_feed_id,
                
                date_buy,
                
                feed_type_id,
                feed_brand_id,
                feed_supplier_id,
                
                quantity,
                kg_per_unit,
                kg_total,
                
                unit_cost,
                total_cost,
                
                added_by_user_id

            ) VALUES (
                cur_pig_prod_id,
                cur_pig_prod_feed_id,
                
                in_date_add,
                
                FEED_TYPE_ID_BOOSTER,
                cur_feed_buy_feed_brand_id,
                cur_feed_buy_feed_supplier_id,
                
                in_num_booster,
                cur_feed_buy_kg_per_unit,
                in_num_booster * cur_feed_buy_kg_per_unit,
                
                cur_feed_buy_unit_cost,
                in_num_booster * cur_feed_buy_unit_cost,
                
                in_user_id
            );
            
            
            /** Sum up all feeds related to pig_prod_id*/
            SELECT  SUM(quantity),
                    SUM(kg_total),
                    SUM(total_cost)
                    
            INTO    cur_feed_quantity,
                    cur_feed_weight_kg,
                    cur_total_cost
            FROM    feed_buy
            WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_BOOSTER;

            
            UPDATE pig_production SET 
                num_b_booster       = cur_feed_quantity,
                num_b_kg_booster    = cur_feed_weight_kg,
                cost_booster        = cur_total_cost
            WHERE id = cur_pig_prod_id;
        END IF;

    END IF;
        
    
    /** Update already inserted feed_buy. */
    IF cur_prod_feed_buy_id > 0 THEN 
        UPDATE feed_buy SET
            date_buy            = in_date_add,

                           
            quantity            = in_num_booster,
            kg_per_unit         = cur_feed_buy_kg_per_unit,
            kg_total            = in_num_booster * cur_feed_buy_kg_per_unit,
                            
            unit_cost           = cur_feed_buy_unit_cost,
            total_cost          = in_num_booster * cur_feed_buy_unit_cost
                           
        WHERE id = cur_prod_feed_buy_id;
    
    
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_BOOSTER;

        
        UPDATE pig_production SET 
            num_b_booster       = cur_feed_quantity,
            num_b_kg_booster    = cur_feed_weight_kg,
            cost_booster        = cur_total_cost
        WHERE id = cur_pig_prod_id;
    
    END IF;
    
END IF;




IF in_num_prestarter IS NOT NULL THEN 
    /** Check if already added */
    SET     cur_prod_feed_buy_id = 0;

    SELECT  id
    INTO    cur_prod_feed_buy_id
    FROM    feed_buy
    WHERE   pig_prod_feed_id = in_pig_prod_feed_id AND 
            feed_type_id = FEED_TYPE_ID_PRESTARTER
    LIMIT   1;

    
    SET     cur_pf_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_pf_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = cur_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_PRESTARTER
    LIMIT   1;


    /** Insert newly added feed_buy. */
    IF cur_prod_feed_buy_id = 0 AND in_num_prestarter > 0 THEN 
        
        IF cur_pf_feed_buy_id > 0 THEN 
            INSERT INTO feed_buy(
                pig_prod_id,
                pig_prod_feed_id,
                
                date_buy,
                
                feed_type_id,
                feed_brand_id,
                feed_supplier_id,
                
                quantity,
                kg_per_unit,
                kg_total,
                
                unit_cost,
                total_cost,
                
                added_by_user_id

            ) VALUES (
                cur_pig_prod_id,
                cur_pig_prod_feed_id,
                
                in_date_add,
                
                FEED_TYPE_ID_PRESTARTER,
                cur_feed_buy_feed_brand_id,
                cur_feed_buy_feed_supplier_id,
                
                in_num_prestarter,
                cur_feed_buy_kg_per_unit,
                in_num_prestarter * cur_feed_buy_kg_per_unit,
                
                cur_feed_buy_unit_cost,
                in_num_prestarter * cur_feed_buy_unit_cost,
                
                in_user_id
            );
            
            
            /** Sum up all feeds related to pig_prod_id*/
            SELECT  SUM(quantity),
                    SUM(kg_total),
                    SUM(total_cost)
                    
            INTO    cur_feed_quantity,
                    cur_feed_weight_kg,
                    cur_total_cost
            FROM    feed_buy
            WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_PRESTARTER;

            
            UPDATE pig_production SET 
                num_b_prestarter       = cur_feed_quantity,
                num_b_kg_prestarter    = cur_feed_weight_kg,
                cost_prestarter        = cur_total_cost
            WHERE id = cur_pig_prod_id;
        END IF;

    END IF;
        
    
    /** Update already inserted feed_buy. */
    IF cur_prod_feed_buy_id > 0 THEN 
        UPDATE feed_buy SET
            date_buy            = in_date_add,

                           
            quantity            = in_num_prestarter,
            kg_per_unit         = cur_feed_buy_kg_per_unit,
            kg_total            = in_num_prestarter * cur_feed_buy_kg_per_unit,
                        
            unit_cost           = cur_feed_buy_unit_cost,
            total_cost          = in_num_prestarter * cur_feed_buy_unit_cost
                           
        WHERE id = cur_prod_feed_buy_id;
    
    
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_PRESTARTER;

        
        UPDATE pig_production SET 
            num_b_prestarter       = cur_feed_quantity,
            num_b_kg_prestarter    = cur_feed_weight_kg,
            cost_prestarter        = cur_total_cost
        WHERE id = cur_pig_prod_id;
    
    END IF;
    
END IF;




IF in_num_starter IS NOT NULL THEN 
    /** Check if already added */
    SET     cur_prod_feed_buy_id = 0;

    SELECT  id
    INTO    cur_prod_feed_buy_id
    FROM    feed_buy
    WHERE   pig_prod_feed_id = in_pig_prod_feed_id AND 
            feed_type_id = FEED_TYPE_ID_STARTER
    LIMIT   1;

    
    SET     cur_pf_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_pf_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = cur_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_STARTER
    LIMIT   1;


    /** Insert newly added feed_buy. */
    IF cur_prod_feed_buy_id = 0 AND in_num_starter > 0 THEN 
        
        IF cur_pf_feed_buy_id > 0 THEN 
            INSERT INTO feed_buy(
                pig_prod_id,
                pig_prod_feed_id,
                
                date_buy,
                
                feed_type_id,
                feed_brand_id,
                feed_supplier_id,
                
                quantity,
                kg_per_unit,
                kg_total,
                
                unit_cost,
                total_cost,
                
                added_by_user_id

            ) VALUES (
                cur_pig_prod_id,
                cur_pig_prod_feed_id,
                
                in_date_add,
                
                FEED_TYPE_ID_STARTER,
                cur_feed_buy_feed_brand_id,
                cur_feed_buy_feed_supplier_id,
                
                in_num_starter,
                cur_feed_buy_kg_per_unit,
                in_num_starter * cur_feed_buy_kg_per_unit,
                
                cur_feed_buy_unit_cost,
                in_num_starter * cur_feed_buy_unit_cost,
                
                in_user_id
            );
            
            
            /** Sum up all feeds related to pig_prod_id*/
            SELECT  SUM(quantity),
                    SUM(kg_total),
                    SUM(total_cost)
                    
            INTO    cur_feed_quantity,
                    cur_feed_weight_kg,
                    cur_total_cost
            FROM    feed_buy
            WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_STARTER;

            
            UPDATE pig_production SET 
                num_b_starter       = cur_feed_quantity,
                num_b_kg_starter    = cur_feed_weight_kg,
                cost_starter        = cur_total_cost
            WHERE id = cur_pig_prod_id;
        END IF;

    END IF;
        
    
    /** Update already inserted feed_buy. */
    IF cur_prod_feed_buy_id > 0 THEN 
        UPDATE feed_buy SET
            date_buy            = in_date_add,

                           
            quantity            = in_num_starter,
            kg_per_unit         = cur_feed_buy_kg_per_unit,
            kg_total            = in_num_starter * cur_feed_buy_kg_per_unit,
                  
            unit_cost           = cur_feed_buy_unit_cost,
            total_cost          = in_num_starter * cur_feed_buy_unit_cost
                           
        WHERE id = cur_prod_feed_buy_id;
    
    
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_STARTER;

        
        UPDATE pig_production SET 
            num_b_starter       = cur_feed_quantity,
            num_b_kg_starter    = cur_feed_weight_kg,
            cost_starter        = cur_total_cost
        WHERE id = cur_pig_prod_id;
    
    END IF;
    
END IF;




IF in_num_grower IS NOT NULL THEN 
    /** Check if already added */
    SET     cur_prod_feed_buy_id = 0;

    SELECT  id
    INTO    cur_prod_feed_buy_id
    FROM    feed_buy
    WHERE   pig_prod_feed_id = in_pig_prod_feed_id AND 
            feed_type_id = FEED_TYPE_ID_GROWER
    LIMIT   1;

    
    SET     cur_pf_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_pf_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = cur_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_GROWER
    LIMIT   1;


    /** Insert newly added feed_buy. */
    IF cur_prod_feed_buy_id = 0 AND in_num_grower > 0 THEN 
        
        IF cur_pf_feed_buy_id > 0 THEN 
            INSERT INTO feed_buy(
                pig_prod_id,
                pig_prod_feed_id,
                
                date_buy,
                
                feed_type_id,
                feed_brand_id,
                feed_supplier_id,
                
                quantity,
                kg_per_unit,
                kg_total,
                
                unit_cost,
                total_cost,
                
                added_by_user_id

            ) VALUES (
                cur_pig_prod_id,
                cur_pig_prod_feed_id,
                
                in_date_add,
                
                FEED_TYPE_ID_GROWER,
                cur_feed_buy_feed_brand_id,
                cur_feed_buy_feed_supplier_id,
                
                in_num_grower,
                cur_feed_buy_kg_per_unit,
                in_num_grower * cur_feed_buy_kg_per_unit,
                
                cur_feed_buy_unit_cost,
                in_num_grower * cur_feed_buy_unit_cost,
                
                in_user_id
            );
            
            
            /** Sum up all feeds related to pig_prod_id*/
            SELECT  SUM(quantity),
                    SUM(kg_total),
                    SUM(total_cost)
                    
            INTO    cur_feed_quantity,
                    cur_feed_weight_kg,
                    cur_total_cost
            FROM    feed_buy
            WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_GROWER;

            
            UPDATE pig_production SET 
                num_b_grower       = cur_feed_quantity,
                num_b_kg_grower    = cur_feed_weight_kg,
                cost_grower        = cur_total_cost
            WHERE id = cur_pig_prod_id;
        END IF;

    END IF;
        
    
    /** Update already inserted feed_buy. */
    IF cur_prod_feed_buy_id > 0 THEN 
        UPDATE feed_buy SET
            date_buy            = in_date_add,

                           
            quantity            = in_num_grower,
            kg_per_unit         = cur_feed_buy_kg_per_unit,
            kg_total            = in_num_grower * cur_feed_buy_kg_per_unit,
                          
            unit_cost           = cur_feed_buy_unit_cost,
            total_cost          = in_num_grower * cur_feed_buy_unit_cost
                           
        WHERE id = cur_prod_feed_buy_id;
    
    
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_GROWER;

        
        UPDATE pig_production SET 
            num_b_grower       = cur_feed_quantity,
            num_b_kg_grower    = cur_feed_weight_kg,
            cost_grower        = cur_total_cost
        WHERE id = cur_pig_prod_id;
    
    END IF;
    
END IF;




IF in_num_finisher IS NOT NULL THEN 
    /** Check if already added */
    SET     cur_prod_feed_buy_id = 0;

    SELECT  id
    INTO    cur_prod_feed_buy_id
    FROM    feed_buy
    WHERE   pig_prod_feed_id = in_pig_prod_feed_id AND 
            feed_type_id = FEED_TYPE_ID_FINISHER
    LIMIT   1;

    
    SET     cur_pf_feed_buy_id = 0;
    
    SELECT  id,
            feed_brand_id,
            feed_supplier_id,
        
            kg_per_unit,        
            unit_cost
    
    INTO    cur_pf_feed_buy_id,
            cur_feed_buy_feed_brand_id,
            cur_feed_buy_feed_supplier_id,
        
            cur_feed_buy_kg_per_unit,        
            cur_feed_buy_unit_cost
            
    FROM    feed_buy
    WHERE   pig_farm_feed_buy_id = cur_pig_farm_feed_buy_id AND 
            feed_type_id = FEED_TYPE_ID_FINISHER
    LIMIT   1;


    /** Insert newly added feed_buy. */
    IF cur_prod_feed_buy_id = 0 AND in_num_finisher > 0 THEN 
        
        IF cur_pf_feed_buy_id > 0 THEN 
            INSERT INTO feed_buy(
                pig_prod_id,
                pig_prod_feed_id,
                
                date_buy,
                
                feed_type_id,
                feed_brand_id,
                feed_supplier_id,
                
                quantity,
                kg_per_unit,
                kg_total,
                
                unit_cost,
                total_cost,
                
                added_by_user_id

            ) VALUES (
                cur_pig_prod_id,
                cur_pig_prod_feed_id,
                
                in_date_add,
                
                FEED_TYPE_ID_FINISHER,
                cur_feed_buy_feed_brand_id,
                cur_feed_buy_feed_supplier_id,
                
                in_num_finisher,
                cur_feed_buy_kg_per_unit,
                in_num_finisher * cur_feed_buy_kg_per_unit,
                
                cur_feed_buy_unit_cost,
                in_num_finisher * cur_feed_buy_unit_cost,
                
                in_user_id
            );
            
            
            /** Sum up all feeds related to pig_prod_id*/
            SELECT  SUM(quantity),
                    SUM(kg_total),
                    SUM(total_cost)
                    
            INTO    cur_feed_quantity,
                    cur_feed_weight_kg,
                    cur_total_cost
            FROM    feed_buy
            WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_FINISHER;

            
            UPDATE pig_production SET 
                num_b_finisher       = cur_feed_quantity,
                num_b_kg_finisher    = cur_feed_weight_kg,
                cost_finisher        = cur_total_cost
            WHERE id = cur_pig_prod_id;
        END IF;

    END IF;
        
    
    /** Update already inserted feed_buy. */
    IF cur_prod_feed_buy_id > 0 THEN 
        UPDATE feed_buy SET
            date_buy            = in_date_add,

                           
            quantity            = in_num_finisher,
            kg_per_unit         = cur_feed_buy_kg_per_unit,
            kg_total            = in_num_finisher * cur_feed_buy_kg_per_unit,
                         
            unit_cost           = cur_feed_buy_unit_cost,
            total_cost          = in_num_finisher * cur_feed_buy_unit_cost
                           
        WHERE id = cur_prod_feed_buy_id;
    
    
        /** Sum up all feeds related to pig_prod_id*/
        SELECT  SUM(quantity),
                SUM(kg_total),
                SUM(total_cost)
                
        INTO    cur_feed_quantity,
                cur_feed_weight_kg,
                cur_total_cost
        FROM    feed_buy
        WHERE   pig_prod_id = cur_pig_prod_id AND feed_type_id = FEED_TYPE_ID_FINISHER;

        
        UPDATE pig_production SET 
            num_b_finisher       = cur_feed_quantity,
            num_b_kg_finisher    = cur_feed_weight_kg,
            cost_finisher        = cur_total_cost
        WHERE id = cur_pig_prod_id;
    
    END IF;
    
END IF;





END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    in_pig_prod_feed_id                 AS pig_prod_feed_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS production_calculate_current_pigs $$
CREATE PROCEDURE production_calculate_current_pigs(
    in_pig_prod_id          INT,
    in_production_group_id  INT,
    
    OUT num_pigs            INT
)  

BEGIN

/** 
 * Will count number of pigs left in pig_production or production_group.
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 19, 2025
 *
 */

DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;

DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;

DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_num_pigs_at_birth                   INT             DEFAULT 0;
DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;
DECLARE cur_num_pigs_added                      INT             DEFAULT 0;
DECLARE cur_num_pigs_harvest                    INT             DEFAULT 0;
DECLARE cur_num_dead_pigs                       INT             DEFAULT 0;
DECLARE cur_num_pigs_current                    INT             DEFAULT 0;



IF in_pig_prod_id > 0 THEN 
    SELECT  prod_status_id
    INTO    cur_pig_prod_status_id
    FROM    pig_production
    WHERE   id = in_pig_prod_id;
    
    IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_LACTATING THEN 
        SELECT  num_pigs_live_m + num_pigs_live_f
        INTO    cur_num_pigs_at_birth
        FROM    pig_production 
        WHERE   id = in_pig_prod_id;

    ELSE
    
        /* This can be NULL if the pigs are brought externally*/
        SELECT  num_pigs_weaning_m + num_pigs_weaning_f
        INTO    cur_num_pigs_weaning
        FROM    pig_production 
        WHERE   id = in_pig_prod_id;
        
        IF cur_num_pigs_weaning IS NULL THEN 
            SELECT  num_pigs_weaning
            INTO    cur_num_pigs_weaning
            FROM    pig_production 
            WHERE   id = in_pig_prod_id;
        END IF;
        
    END IF;
    
    
    /* This can be NULL.*/
    SELECT  SUM(num_pigs_added)
    INTO    cur_num_pigs_added
    FROM    pig_prod_pig_add
    WHERE   pig_prod_id = in_pig_prod_id;
    
    
    /* This can be NULL*/
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    production_harvest
    WHERE   pig_prod_id = in_pig_prod_id;
    
    
    /* This can be NULL.*/
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   pig_prod_id = in_pig_prod_id;
    
    
    
ELSE
    /*  Get of all weaning pigs in the group*/
    /* This can be NULL if the pigs are brought externally*/
    SELECT  SUM(b.num_pigs_weaning_m + b.num_pigs_weaning_f)
    INTO    cur_num_pigs_weaning
    FROM    production_group_pig_prod a 
    LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id 
    WHERE a.production_group_id = in_production_group_id;


    /* This can be NULL*/
    SELECT  SUM(num_pigs_added)
    INTO    cur_num_pigs_added
    FROM    pig_prod_pig_add 
    WHERE   production_group_id = in_production_group_id;


    /* This can be NULL*/
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    production_harvest
    WHERE   production_group_id = in_production_group_id;


    /* This can be NULL.*/
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   production_group_id = in_production_group_id AND dead_at_stage = DEAD_AT_STAGE_GROWING;

END IF;
    

IF cur_num_pigs_at_birth > 0 THEN 
    SET cur_num_pigs_current = cur_num_pigs_at_birth;
END IF;

IF cur_num_pigs_weaning > 0 THEN 
    SET cur_num_pigs_current = cur_num_pigs_weaning;
END IF;

IF cur_num_pigs_added > 0 THEN 
    SET cur_num_pigs_current = cur_num_pigs_current + cur_num_pigs_added;
END IF;

IF cur_num_pigs_harvest > 0 THEN 
    SET cur_num_pigs_current = cur_num_pigs_current - cur_num_pigs_harvest;
END IF;
 
IF cur_num_dead_pigs > 0 THEN 
    SET cur_num_pigs_current = cur_num_pigs_current - cur_num_dead_pigs;
END IF;

SET num_pigs  = cur_num_pigs_current;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS production_group_pig_prod_add $$
CREATE PROCEDURE production_group_pig_prod_add(
    in_user_id              INT,

    in_production_group_id  INT,
    in_pig_prod_id          INT,
    
    in_date_added           INT
)  

BEGIN

/** 
 * Will add (combine) pig_production to existing production_group entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;

DECLARE RES_NUM_CANNOT_BE_ADDED_TO_GROUP		INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PRODUCTION_GROUP        INT             DEFAULT 34;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;
DECLARE PRODUCTION_STATUS_ID_CULLED             INT             DEFAULT 10;



DECLARE PRODUCTION_GRP_STATUS_ID_GROWING        INT             DEFAULT 1;
DECLARE PRODUCTION_GRP_STATUS_ID_HARVESTED      INT             DEFAULT 2;
DECLARE PRODUCTION_GRP_STATUS_ID_CLOSED         INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_production_group_account_id         INT             DEFAULT 0;


DECLARE cur_pig_prod_production_group_id        INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_num_pigs_current                    INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";

SELECT  account_id
INTO    cur_production_group_account_id
FROM    production_group
WHERE   id = in_production_group_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_production_group_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PRODUCTION_GROUP,
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



SELECT  a.production_group_id,
        a.prod_status_id

INTO    cur_pig_prod_production_group_id,
        cur_pig_prod_status_id
        
FROM    pig_production a 
WHERE   a.id = in_pig_prod_id;


/* A pig_production entry can only be associated with one production_group*/
IF cur_pig_prod_production_group_id > 0 THEN 
    SET res_num     = RES_NUM_CANNOT_BE_ADDED_TO_GROUP;
    SET res_code    = "RES_NUM_CANNOT_BE_ADDED_TO_GROUP";
    SET res_desc    = "Production already added to group.";
    
    LEAVE process_user;
END IF;



INSERT INTO production_group_pig_prod (
    production_group_id,
    pig_prod_id,
    date_added_to_group,
    added_by_user_id
)
VALUES (
    in_production_group_id,
    in_pig_prod_id,
    in_date_added,
    in_user_id
);


UPDATE pig_production SET
    prod_status_id          = PRODUCTION_STATUS_ID_COMBINED,
    production_group_id     = in_production_group_id
WHERE id = in_pig_prod_id;

END process_user;


/* Compute current total pigs in the production_group*/
CALL production_calculate_current_pigs(0, in_production_group_id, cur_num_pigs_current);
    

UPDATE production_group SET 
    num_pigs_current = cur_num_pigs_current
WHERE id = in_production_group_id;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_production_group_id              AS production_group_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS production_group_create $$
CREATE PROCEDURE production_group_create(
    in_user_id              INT,

    in_pig_prod_id          INT, /*initial pig_production in the production_group*/
    
    in_date_added           INT
)  

BEGIN

/** 
 * Will add production_group entry. Note the procedure name is purposely 
 * not production_group_add  so that it will not confuse with 
 * production_group_pig_prod_add procedure. A production_group is formed
 * when a pig_production in converted to production_group and more pig_production
 * entries are added into the production_group.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_CANNOT_BE_ADDED_TO_GROUP        INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PRODUCTION_GROUP        INT             DEFAULT 34;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;
DECLARE PRODUCTION_STATUS_ID_CULLED             INT             DEFAULT 10;



DECLARE PRODUCTION_GROUP_STATUS_ID_GROWING      INT             DEFAULT 1;
DECLARE PRODUCTION_GROUP_STATUS_ID_HARVESTED    INT             DEFAULT 2;
DECLARE PRODUCTION_GROUP_STATUS_ID_CLOSED       INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_production_group_id        INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_farm_last_production_group_id   INT             DEFAULT 0;

DECLARE cur_production_group_id                 INT             DEFAULT 0;
DECLARE cur_production_group_flag               INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PRODUCTION_GROUP,
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



/* Get the farm information of the in_pig_prod_id.*/
SELECT  a.production_group_id,
        a.pig_farm_id,
        a.prod_status_id,
        b.last_production_group_id

INTO    cur_pig_prod_production_group_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        cur_pig_farm_last_production_group_id
FROM    pig_production a 
LEFT OUTER JOIN pig_farm b ON a.pig_farm_id = b.id
WHERE   a.id = in_pig_prod_id;


/* Check for duplicate entry */
/* A pig_production entry can only be associated with one production_group*/
IF cur_pig_prod_production_group_id > 0 THEN 
    SET res_num     = RES_NUM_CANNOT_BE_ADDED_TO_GROUP;
    SET res_code    = "RES_NUM_CANNOT_BE_ADDED_TO_GROUP";
    SET res_desc    = "Production already added to group.";
    
    LEAVE process_user;
END IF;


/* Check the status of the pig_production entry to be added into the group*/
IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_WEANING,
                                    PRODUCTION_STATUS_ID_GROWING) THEN 
    SET res_num     = RES_NUM_CANNOT_BE_ADDED_TO_GROUP;
    SET res_code    = "RES_NUM_CANNOT_BE_ADDED_TO_GROUP";
    SET res_desc    = "Production status not WEANING or GROWING.";
    
    LEAVE process_user;
END IF;


SET cur_pig_farm_last_production_group_id = cur_pig_farm_last_production_group_id + 1;


INSERT INTO production_group(
    account_id,
    pig_farm_id,
    farm_production_group_id,
    prod_group_status_id,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    cur_pig_prod_pig_farm_id,
    cur_pig_farm_last_production_group_id,
    PRODUCTION_GROUP_STATUS_ID_GROWING,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_production_group_id;


INSERT INTO production_group_pig_prod (
    production_group_id,
    pig_prod_id,
    date_added_to_group,
    added_by_user_id
)
VALUES (
    cur_production_group_id,
    in_pig_prod_id,
    in_date_added,
    in_user_id
);


UPDATE pig_production SET
    prod_status_id          = PRODUCTION_STATUS_ID_COMBINED,
    production_group_id     = cur_production_group_id
WHERE id = in_pig_prod_id;


UPDATE pig_farm SET
    last_production_group_id = cur_pig_farm_last_production_group_id
WHERE id = cur_pig_prod_pig_farm_id;


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_production_group_id             AS production_group_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS basic_user_check $$
CREATE PROCEDURE basic_user_check(
    in_user_id                  INT,
    in_user_must_have_account   INT,
    in_compare_to_account_id    INT,
    
    in_business_obj_id_to_access INT, 
    in_business_obj_operation   INT, /* This must be a FLAG_BIT_OPERATION value*/
    
    OUT out_user_account_id     INT,
    OUT out_user_group_id       INT,
    
    OUT res_num                 INT,
    OUT res_code                VARCHAR(80),
    OUT res_desc                VARCHAR(180)
)  

BEGIN

/** 
 * Will perform user flag checks, account checks and user group checks.
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 18, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_USER_IS_INACTIVE                INT             DEFAULT 1;
DECLARE RES_NUM_USER_NOT_EMAIL_VERIFIED         INT             DEFAULT 2;
DECLARE RES_NUM_USER_NOT_ACCOUNT_ADMIN          INT             DEFAULT 3;
DECLARE RES_NUM_USER_NO_ACCOUNT_SET             INT             DEFAULT 4;
DECLARE RES_NUM_USER_NO_USER_GROUP_SET          INT             DEFAULT 5;


DECLARE RES_NUM_ACCOUNT_DISABLED                INT             DEFAULT 6;
DECLARE RES_NUM_ACCOUNT_STATUS_TRIAL_EXPIRED    INT             DEFAULT 7;
DECLARE RES_NUM_ACCOUNT_MISMATCH                INT             DEFAULT 8;
DECLARE RES_NUM_ACCOUNT_STATUS_UNPAID_BILL      INT             DEFAULT 9;


DECLARE RES_NUM_USER_GROUP_HAS_NO_ACCESS        INT             DEFAULT 12;
DECLARE RES_NUM_USER_GROUP_NO_ADD_PRIVILEGE     INT             DEFAULT 13;
DECLARE RES_NUM_USER_GROUP_NO_UPDATE_PRIVILEGE  INT             DEFAULT 14;
DECLARE RES_NUM_USER_GROUP_NO_DELETE_PRIVILEGE  INT             DEFAULT 15;

/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


/* These system bits can be also embedded into user.flag*/
DECLARE FLAG_BIT_SYSTEM_SUPPORT                 INT             DEFAULT 131072; /* 2^17*/
DECLARE FLAG_BIT_SYSTEM_MARKETING               INT             DEFAULT 262144; /* 2^18*/
DECLARE FLAG_BIT_SYSTEM_RESERVE_1               INT             DEFAULT 528288; /* 2^19*/
DECLARE FLAG_BIT_SYSTEM_ADMIN                   INT             DEFAULT 1048576; /* 2^20*/

/* reserved bits for future use*/
DECLARE FLAG_BIT_SYSTEM_SUPER_USER              INT             DEFAULT 33554432; /* 2^25*/



/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;

DECLARE ACCOUNT_STATUS_ID_ON_TRIAL              INT             DEFAULT 1;
DECLARE ACCOUNT_STATUS_ID_TRIAL_EXPIRED         INT             DEFAULT 2;
DECLARE ACCOUNT_STATUS_ID_UNPAID_BILL           INT             DEFAULT 3;



/* This is read from a02_business_object table. */
DECLARE BUSINESS_OBJ_ID_USER                    INT             DEFAULT 1;
DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;
DECLARE BUSINESS_OBJ_ID_USER_REQUEST            INT             DEFAULT 3;
DECLARE BUSINESS_OBJ_ID_USER_GROUP              INT             DEFAULT 4;

DECLARE BUSINESS_OBJ_ID_ACCOUNT_TRANSLATION     INT             DEFAULT 5;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_BILLING         INT             DEFAULT 6;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER       INT             DEFAULT 7;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 8;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;
DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF          INT             DEFAULT 10;

DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;
DECLARE BUSINESS_OBJ_ID_FEED_BALANCE            INT             DEFAULT 18;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;
DECLARE BUSINESS_OBJ_ID_SEMEN_SOURCE            INT             DEFAULT 20;
DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_AI             INT             DEFAULT 22;



DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_ADD        INT             DEFAULT 27;

DECLARE BUSINESS_OBJ_ID_PIG_DEAD_TYPE           INT             DEFAULT 28;

DECLARE BUSINESS_OBJ_ID_SOW_BOAR_BALANCE        INT             DEFAULT 30;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_RESERVED_2     INT             DEFAULT 32;

DECLARE BUSINESS_OBJ_ID_PIG_PEN                 INT             DEFAULT 33;
DECLARE BUSINESS_OBJ_ID_PRODUCTION_GROUP        INT             DEFAULT 34;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE SYS_USER_FLAG_MASK                      INT             DEFAULT 0;

DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_is_system_super_user           INT             DEFAULT 0;

DECLARE cur_biz_obj_flag_bit_num                INT             DEFAULT 0;

DECLARE cur_user_grp_flag_business_obj_1        BIGINT          DEFAULT 0;
DECLARE cur_user_grp_flag_business_obj_2        BIGINT          DEFAULT 0;

        
DECLARE cur_user_grp_flag_priv_user             INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_account          INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_request      INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_user_group       INT             DEFAULT 0;


DECLARE cur_user_grp_flag_priv_acc_translation  INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_billing      INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_pig_buyer    INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_pig_ops      INT             DEFAULT 0;


DECLARE cur_user_grp_flag_priv_pig_farm         INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_farm_staff   INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_race_line    INT             DEFAULT 0;



DECLARE cur_user_grp_flag_priv_feed_buy         INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_feed_balance     INT             DEFAULT 0;


DECLARE cur_user_grp_flag_priv_sow_boar         INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_semen_source     INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_production   INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_ai      INT             DEFAULT 0;



DECLARE cur_user_grp_flag_priv_pig_prod_pig_ops INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_pig_dead INT            DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_notes   INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_harvest INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_pig_add INT             DEFAULT 0;

DECLARE cur_user_grp_flag_priv_sow_boar_balance INT             DEFAULT 0;

DECLARE cur_user_grp_flag_priv_pig_pen          INT             DEFAULT 0;


DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;


DECLARE flag_bit                                BIGINT          DEFAULT 0;
DECLARE cur_group_flag                          INT             DEFAULT 0;


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";

SELECT  bit_num
INTO    cur_biz_obj_flag_bit_num
FROM    a02_business_object
WHERE   id = in_business_obj_id_to_access;


SELECT  
    a.flag,
    a.account_id,
    a.user_group_id,
    
    b.flag_business_obj_1,
    b.flag_business_obj_2,
    
    b.flag_priv_user,
    b.flag_priv_account,
    b.flag_priv_acc_request,
    b.flag_priv_user_group,
    
    b.flag_priv_acc_translation,
    b.flag_priv_acc_billing,
    b.flag_priv_acc_pig_buyer,
    b.flag_priv_acc_pig_ops,
    
    b.flag_priv_pig_farm,
    b.flag_priv_pig_farm_staff,
    b.flag_priv_pig_race_line,
    
    b.flag_priv_feed_buy,
    b.flag_priv_feed_balance,
    
    
    b.flag_priv_sow_boar,
    b.flag_priv_semen_source,
    b.flag_priv_pig_production,
    b.flag_priv_pig_prod_ai,
    
    
    b.flag_priv_pig_prod_pig_ops,
    b.flag_priv_pig_prod_pig_dead,
    b.flag_priv_pig_prod_notes,
    b.flag_priv_pig_prod_harvest,
    b.flag_priv_pig_prod_pig_add,
    
    b.flag_priv_sow_boar_balance,
    
    b.flag_priv_pig_pen
    

INTO    
    cur_user_flag,
    out_user_account_id,
    out_user_group_id,
        
    cur_user_grp_flag_business_obj_1,
    cur_user_grp_flag_business_obj_2,
    
        
    cur_user_grp_flag_priv_user,
    cur_user_grp_flag_priv_account,
    cur_user_grp_flag_priv_acc_request,
    cur_user_grp_flag_priv_user_group,
    
    cur_user_grp_flag_priv_acc_translation,
    cur_user_grp_flag_priv_acc_billing,
    cur_user_grp_flag_priv_acc_pig_buyer,
    cur_user_grp_flag_priv_acc_pig_ops,
    
    cur_user_grp_flag_priv_pig_farm,
    cur_user_grp_flag_priv_pig_farm_staff,
    cur_user_grp_flag_priv_pig_race_line,
    

    cur_user_grp_flag_priv_feed_buy,
    cur_user_grp_flag_priv_feed_balance,
    
    
    cur_user_grp_flag_priv_sow_boar,
    cur_user_grp_flag_priv_semen_source,
    cur_user_grp_flag_priv_pig_production,
    cur_user_grp_flag_priv_pig_prod_ai,
    
    
    cur_user_grp_flag_priv_pig_prod_pig_ops,
    cur_user_grp_flag_priv_pig_prod_pig_dead,
    cur_user_grp_flag_priv_pig_prod_notes,
    cur_user_grp_flag_priv_pig_prod_harvest,
    cur_user_grp_flag_priv_pig_prod_pig_add,
    
    cur_user_grp_flag_priv_sow_boar_balance,
    
    cur_user_grp_flag_priv_pig_pen
    
FROM  user a 
LEFT OUTER JOIN  user_group b ON  a.user_group_id = b.id
WHERE   a.id = in_user_id;



process_user : BEGIN

/* Check user*/
IF cur_user_flag & FLAG_BIT_USER_IS_ACTIVE = 0 THEN 
    SET res_num     = RES_NUM_USER_IS_INACTIVE;
    SET res_code    = "RES_NUM_USER_IS_INACTIVE";

    LEAVE process_user;    
END IF;


IF cur_user_flag & FLAG_BIT_USER_EMAIL_VERIFIED = 0 THEN 
    SET res_num     = RES_NUM_USER_NOT_EMAIL_VERIFIED;
    SET res_code    = "RES_NUM_USER_NOT_EMAIL_VERIFIED";

    LEAVE process_user;
END IF;


IF in_user_must_have_account = 0 THEN 
    LEAVE process_user;
END IF;


/* Check if the user is a  system super user*/
IF cur_user_flag & FLAG_BIT_SYSTEM_SUPER_USER > 0 THEN 
    SET cur_user_is_system_super_user = 1;
END IF;


/* User must be associated to an account */

IF out_user_account_id = 0 THEN 
    SET res_num     = RES_NUM_USER_NO_ACCOUNT_SET;
    SET res_code    = "RES_NUM_USER_NO_ACCOUNT_SET";

    LEAVE process_user;
END IF;


IF out_user_group_id = 0 THEN 
    SET res_num     = RES_NUM_USER_NO_USER_GROUP_SET;
    SET res_code    = "RES_NUM_USER_NO_USER_GROUP_SET";

    LEAVE process_user;
END IF;




/* Check account*/
SELECT 
    flag,
    status_id
INTO
    cur_account_flag,
    cur_account_status_id
    
FROM account
WHERE id = out_user_account_id;


/* Will ignore these checks if user is a system super user. */
IF cur_user_is_system_super_user = 0 THEN
    IF cur_account_flag & FLAG_BIT_ACCOUNT_ENABLE = 0 THEN 
        SET res_num     = RES_NUM_ACCOUNT_DISABLED;
        SET res_code    = "RES_NUM_ACCOUNT_DISABLED";
        
        IF cur_account_status_id = ACCOUNT_STATUS_ID_UNPAID_BILL THEN
            SET res_num     = RES_NUM_ACCOUNT_STATUS_UNPAID_BILL;
            SET res_code    = "RES_NUM_ACCOUNT_STATUS_UNPAID_BILL";
        
        END IF;
        
        LEAVE process_user;
    END IF;


    IF in_compare_to_account_id > 0 THEN 
        IF out_user_account_id != in_compare_to_account_id THEN 
            SET res_num     = RES_NUM_ACCOUNT_MISMATCH;
            SET res_code    = "RES_NUM_ACCOUNT_MISMATCH";

            LEAVE process_user;
        END IF;

    END IF;


    IF in_business_obj_id_to_access = 0 THEN 
        /* This is means the business_object is a public business object.*/
        LEAVE process_user;
    END IF;



    /* Check user.usergroup privileges. */

    SET flag_bit = POWER(2, cur_biz_obj_flag_bit_num);

    IF in_business_obj_id_to_access <= 32 THEN 
        IF cur_user_grp_flag_business_obj_1 & flag_bit =  0 THEN
            SET res_num     = RES_NUM_USER_GROUP_HAS_NO_ACCESS;
            SET res_code    = "RES_NUM_USER_GROUP_HAS_NO_ACCESS";

            LEAVE process_user;
        END IF;
    END IF;
    
    IF in_business_obj_id_to_access > 32 AND in_business_obj_id_to_access <= 64 THEN
        IF cur_user_grp_flag_business_obj_2 & flag_bit =  0 THEN
            SET res_num     = RES_NUM_USER_GROUP_HAS_NO_ACCESS;
            SET res_code    = "RES_NUM_USER_GROUP_HAS_NO_ACCESS";

            LEAVE process_user;
        END IF;
    END IF;
END IF;





CASE in_business_obj_id_to_access

WHEN BUSINESS_OBJ_ID_USER THEN 
    SET cur_group_flag = cur_user_grp_flag_priv_user;

WHEN BUSINESS_OBJ_ID_ACCOUNT THEN
    SET cur_group_flag = cur_user_grp_flag_priv_account;

WHEN BUSINESS_OBJ_ID_USER_REQUEST THEN
    SET cur_group_flag = cur_user_grp_flag_priv_acc_request;

WHEN BUSINESS_OBJ_ID_USER_GROUP THEN
    SET cur_group_flag = cur_user_grp_flag_priv_user_group;
    
    
    
WHEN BUSINESS_OBJ_ID_ACCOUNT_TRANSLATION THEN
    SET cur_group_flag = cur_user_grp_flag_priv_acc_translation;
    
WHEN BUSINESS_OBJ_ID_ACCOUNT_BILLING THEN
    SET cur_group_flag = cur_user_grp_flag_priv_acc_billing;
    
WHEN BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER THEN
    SET cur_group_flag = cur_user_grp_flag_priv_acc_pig_buyer;
    
WHEN BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS THEN
    SET cur_group_flag = cur_user_grp_flag_priv_acc_pig_ops;
    
    
WHEN BUSINESS_OBJ_ID_PIG_FARM THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_farm;
    
WHEN BUSINESS_OBJ_ID_PIG_FARM_STAFF THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_farm_staff;
    
WHEN BUSINESS_OBJ_ID_PIG_RACE_LINE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_race_line;



WHEN BUSINESS_OBJ_ID_FEED_BUY THEN
    SET cur_group_flag = cur_user_grp_flag_priv_feed_buy;
        
WHEN BUSINESS_OBJ_ID_FEED_BALANCE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_feed_balance;
           

WHEN BUSINESS_OBJ_ID_SOW_BOAR THEN
    SET cur_group_flag = cur_user_grp_flag_priv_sow_boar;
        
WHEN BUSINESS_OBJ_ID_SEMEN_SOURCE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_semen_source;
    
WHEN BUSINESS_OBJ_ID_PIG_PRODUCTION THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_production;
              
WHEN BUSINESS_OBJ_ID_PIG_PROD_AI THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_ai;


WHEN BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_pig_ops;
        
WHEN BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_pig_dead;
        
WHEN BUSINESS_OBJ_ID_PIG_PROD_NOTES THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_notes;

WHEN BUSINESS_OBJ_ID_PIG_PROD_HARVEST THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_harvest;
    
WHEN BUSINESS_OBJ_ID_PIG_PROD_PIG_ADD THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_pig_add;
    

WHEN BUSINESS_OBJ_ID_SOW_BOAR_BALANCE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_sow_boar_balance;


WHEN BUSINESS_OBJ_ID_PIG_PEN THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_pen;



END CASE;


/* Will ignore these checks if user is a system super user. */
IF cur_user_is_system_super_user = 0 THEN

    IF in_business_obj_operation = FLAG_BIT_OPERATION_ADD THEN 
        IF cur_group_flag & FLAG_BIT_OPERATION_ADD = 0 THEN 
            SET res_num     = RES_NUM_USER_GROUP_NO_ADD_PRIVILEGE;
            SET res_code    = "RES_NUM_USER_GROUP_NO_ADD_PRIVILEGE";
        
            LEAVE process_user;
        END IF;
    END IF;

    IF in_business_obj_operation = FLAG_BIT_OPERATION_UPDATE THEN 
        IF cur_group_flag & FLAG_BIT_OPERATION_UPDATE = 0 THEN 
            SET res_num     = RES_NUM_USER_GROUP_NO_UPDATE_PRIVILEGE;
            SET res_code    = "RES_NUM_USER_GROUP_NO_UPDATE_PRIVILEGE";
        
            LEAVE process_user;
        END IF;
    END IF;

    IF in_business_obj_operation = FLAG_BIT_OPERATION_DELETE THEN 
        IF cur_group_flag & FLAG_BIT_OPERATION_DELETE = 0 THEN 
            SET res_num     = RES_NUM_USER_GROUP_NO_DELETE_PRIVILEGE;
            SET res_code    = "RES_NUM_USER_GROUP_NO_DELETE_PRIVILEGE";
        
            LEAVE process_user;
        END IF;
    END IF;

END IF;




END process_user;





END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_medvac_search_keys $$
CREATE PROCEDURE pig_medvac_search_keys(
    IN p_account_id INT,
    IN p_search_str VARCHAR(255)
)  

BEGIN

/** 
 * Will search medvac key; using deepseek 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since January 19, 2026
 *
 */
	SELECT 
        searched_str,
        SUM(hits) as num_hits
    FROM (
        SELECT 
            u_brand_name AS searched_str,
            COUNT(*) as hits,
            1 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_brand_name LIKE CONCAT(p_search_str, '%')
        GROUP BY u_brand_name
        
        UNION ALL
        
        SELECT 
            u_type_name AS searched_str,
            COUNT(*) as hits,
            1 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_type_name LIKE CONCAT(p_search_str, '%')
        GROUP BY u_type_name
        
        UNION ALL
        
        SELECT 
            u_acc_medvac_name AS searched_str,
            COUNT(*) as hits,
            1 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_acc_medvac_name LIKE CONCAT(p_search_str, '%')
        GROUP BY u_acc_medvac_name
        
        UNION ALL
        
		
		
		
        SELECT 
            u_brand_name AS searched_str,
            COUNT(*) as hits,
            2 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_brand_name LIKE CONCAT('%', p_search_str, '%')
            AND u_brand_name NOT LIKE CONCAT(p_search_str, '%')
        GROUP BY u_brand_name
        
        UNION ALL
        
        SELECT 
            u_type_name AS searched_str,
            COUNT(*) as hits,
            2 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_type_name LIKE CONCAT('%', p_search_str, '%')
            AND u_type_name NOT LIKE CONCAT(p_search_str, '%')
        GROUP BY u_type_name
        
        UNION ALL
        
        SELECT 
            u_acc_medvac_name AS searched_str,
            COUNT(*) as hits,
            2 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_acc_medvac_name LIKE CONCAT('%', p_search_str, '%')
            AND u_acc_medvac_name NOT LIKE CONCAT(p_search_str, '%')
        GROUP BY u_acc_medvac_name
		
		UNION ALL
        
        SELECT 
            notes AS searched_str,
            COUNT(*) as hits,
            2 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND notes LIKE CONCAT('%', p_search_str, '%')
        GROUP BY notes
		
    ) AS combined_results
    GROUP BY searched_str, priority
    ORDER BY priority ASC, SUM(hits) DESC
    LIMIT 8;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_medvac_add $$
CREATE PROCEDURE pig_medvac_add(
    in_user_id              INT,
    

    in_sow_boar_id          INT,
    in_pig_prod_id          INT,
    in_pig_prod_pig_ops_id  INT,
    in_health_issue_id      INT,
    
    in_date_medvac          VARCHAR(10),
    in_medvac_brand_id      INT,
    in_medvac_type_id       INT,
    in_acc_medvac_id        INT,
    
    in_staff_id             INT,
    in_done_by_user         INT,
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will add medvac entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since January 8, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_INACTIVE_STATUS        INT             DEFAULT 20;
DECLARE RES_NUM_SOW_BOAR_ALREADY_DISPOSED        INT             DEFAULT 21;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;



DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* medvac_brand.flag bits*/
DECLARE FLAG_BIT_MEDVAC_BRAND_IS_DELETED        INT             DEFAULT 1;
DECLARE FLAG_BIT_MEDVAC_BRAND_IS_VERIFIED       INT             DEFAULT 2;


/* medvac_type.flag bits*/
DECLARE FLAG_BIT_MEDVAC_TYPE_IS_DELETED          INT            DEFAULT 1;
DECLARE FLAG_BIT_MEDVAC_TYPE_IS_VERIFIED         INT            DEFAULT 2;



DECLARE MIN_COUNT_MEDVAC_BRAND_IS_VERIFIED      INT             DEFAULT 3;
DECLARE MIN_COUNT_MEDVAC_TYPE_IS_VERIFIED       INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';



DECLARE cur_account_id_to_check                 INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;



DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_is_disposed                INT             DEFAULT 0;


DECLARE cur_is_active_status                    INT             DEFAULT 0;


DECLARE cur_medvac_id                           INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;
DECLARE cur_count                               INT             DEFAULT 0;


DECLARE cur_u_brand_name                        VARCHAR(50)     DEFAULT '';
DECLARE cur_u_type_name                         VARCHAR(50)     DEFAULT '';
DECLARE cur_u_acc_medvac_name                   VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id
    
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    pig_production 
    WHERE   id = in_pig_prod_id
    LIMIT   1;
    
    SET cur_account_id_to_check = cur_pig_prod_account_id;

END IF;


IF in_sow_boar_id > 0 THEN 
    SELECT  
            account_id,
            pig_farm_id,
            is_disposed
            
    INTO    
            cur_sow_boar_account_id,
            cur_sow_boar_pig_farm_id,
            cur_sow_boar_is_disposed
    
    FROM    sow_boar
    WHERE   id = in_sow_boar_id;
    
    SET cur_account_id_to_check = cur_sow_boar_account_id;


END IF;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_id_to_check, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY, /* TODO */
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


/* Check sow_boar status*/
IF in_sow_boar_id > 0 THEN 
    IF cur_sow_boar_is_disposed > 0 THEN 
        SET res_num     = RES_NUM_SOW_BOAR_ALREADY_DISPOSED;
        SET res_code    = "RES_NUM_SOW_BOAR_ALREADY_DISPOSED";
        
        LEAVE process_user;
    END IF;
    
END IF;



/* Check pig_production status*/
IF in_pig_prod_id > 0 THEN
    
    SET cur_is_active_status = 0;
    CALL pig_prod_check_active_status(cur_pig_prod_status_id, cur_is_active_status);
    
    IF cur_is_active_status = 0 THEN 
        SET res_num     = RES_NUM_PIG_PROD_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_PIG_PROD_INACTIVE_STATUS";
    
        LEAVE process_user;
    END IF;
    
END IF;






/* Check for duplicate entry */
IF in_sow_boar_id > 0 THEN
    SELECT  id
    INTO    cur_medvac_id
    FROM    pig_medvac
    WHERE   sow_boar_id = in_sow_boar_id        AND
            date_medvac = in_date_medvac        AND 
            medvac_brand_id = in_medvac_brand_id AND
            medvac_type_id = in_medvac_type_id  AND
            acc_medvac_id = in_acc_medvac_id
    LIMIT   1;
ELSE
    SELECT  id
    INTO    cur_medvac_id
    FROM    pig_medvac
    WHERE   pig_prod_id = in_pig_prod_id AND
            date_medvac = in_date_medvac AND 
            medvac_brand_id = in_medvac_brand_id AND
            medvac_type_id = in_medvac_type_id  AND
            acc_medvac_id = in_acc_medvac_id
    LIMIT   1;

END IF;


IF cur_medvac_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



/* If done by user, user will be added to staff list.
Note: not all staff are users
*/
IF in_done_by_user > 0 THEN
    SELECT  pig_farm_staff_id,
            name_first,
            name_last
    
    INTO    cur_user_staff_id,
            cur_user_name_first,
            cur_user_name_last
    FROM    user 
    WHERE   id = in_user_id;
    
    
    IF cur_user_staff_id = 0 THEN 
        INSERT INTO pig_farm_staff (
            account_id,
            pig_farm_id,
            user_id,
            name,
            
            added_by_user_id
        ) VALUES (
            cur_sow_boar_account_id,
            cur_sow_boar_pig_farm_id,
            in_user_id,
            CONCAT(cur_user_name_first, ' ', cur_user_name_last),
            
            in_user_id
        );
        SELECT LAST_INSERT_ID() INTO cur_user_staff_id;
        
        
        UPDATE user SET 
            pig_farm_staff_id = cur_user_staff_id
        WHERE id = in_user_id;
        
    END IF;
    
    
    SET in_staff_id = cur_user_staff_id;
    
END IF;


/* These string copies of medvac_brand, medvac_type and medvac_name
are used for faster text search for medvac. 

Everytime a user type in key words for search in medvac entry,
it will search through these columns 

1.) u_brand_name
2.) u_type_name
3.) u_medvac_name
4.) u_medvac_notes

The medvac text search is performed using account_id not sow_boar_id, 
so this needs to be fast.

There is also a future plan to search for multiple accounts
with same pig_farm.address_level_2_id, which is even has more data sets to searched.

*/

SELECT  name
INTO    cur_u_brand_name 
FROM    medvac_brand
WHERE   id = in_medvac_brand_id;


SELECT  name
INTO    cur_u_type_name 
FROM    medvac_type
WHERE   id = in_medvac_type_id;


SELECT  name
INTO    cur_u_acc_medvac_name 
FROM    account_medvac
WHERE   id = in_acc_medvac_id;



INSERT INTO pig_medvac(
    
    account_id,
    
    sow_boar_id,
    pig_prod_id,
    
    pig_prod_pig_ops_id,
    health_issue_id,
    
    date_medvac,
    medvac_type_id,
    medvac_brand_id,
    acc_medvac_id,
    
    u_brand_name,
    u_type_name,
    u_acc_medvac_name,
    
    notes,
    
    staff_id,
    
    added_by_user_id

) VALUES (
    cur_sow_boar_account_id,

    in_sow_boar_id,
    in_pig_prod_id,
    
    in_pig_prod_pig_ops_id,
    in_health_issue_id,
    
    
    in_date_medvac,
    in_medvac_type_id,
    in_medvac_brand_id,
    in_acc_medvac_id,
    
    cur_u_brand_name,
    cur_u_type_name,
    cur_u_acc_medvac_name,

    in_notes,
    
    in_staff_id,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_medvac_id;


IF in_health_issue_id > 0 THEN 
    UPDATE pig_prod_notes SET 
        last_pig_medvac_id = cur_medvac_id
    WHERE id = in_health_issue_id;
END IF;



/* Insert INTO account_selection*/
SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_sow_boar_account_id AND 
        medvac_brand_id = in_medvac_brand_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        medvac_brand_id
    ) VALUES (
        cur_sow_boar_account_id,
        in_medvac_brand_id
    );
END IF;


/* Update medvac_brand counter. */
SELECT  COUNT(*)
INTO    cur_count
FROM    account_selection
WHERE   medvac_brand_id = in_medvac_brand_id;

UPDATE  medvac_brand SET
    account_counter = cur_count
WHERE id = in_medvac_brand_id;


/* Update medvac_brand.flag.FLAG_BIT_MEDVAC_BRAND_IS_VERIFIED*/
IF cur_count >= MIN_COUNT_MEDVAC_BRAND_IS_VERIFIED THEN 
    UPDATE medvac_brand SET
        flag = flag | FLAG_BIT_MEDVAC_BRAND_IS_VERIFIED
    WHERE id = in_medvac_brand_id;

END IF;



SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_sow_boar_account_id AND 
        medvac_type_id = in_medvac_type_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        medvac_type_id
    ) VALUES (
        cur_sow_boar_account_id,
        in_medvac_type_id
    );
END IF;


/* Update medvac_type counter. */
SELECT  COUNT(*)
INTO    cur_count
FROM    account_selection
WHERE   medvac_type_id = in_medvac_type_id;

UPDATE  medvac_type SET
    account_counter = cur_count
WHERE id = in_medvac_type_id;


/* Update medvac_type.flag.MIN_COUNT_MEDVAC_TYPE_IS_VERIFIED*/
IF cur_count >= MIN_COUNT_MEDVAC_TYPE_IS_VERIFIED THEN 
    UPDATE medvac_type SET
        flag = flag | MIN_COUNT_MEDVAC_TYPE_IS_VERIFIED
    WHERE id = in_medvac_type_id;

END IF;


IF in_sow_boar_id > 0 THEN 
    UPDATE sow_boar SET
        data_ver_num_medvac = data_ver_num_medvac + 1 
    WHERE id = in_sow_boar_id;
END IF;


IF in_pig_prod_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_medvac = data_ver_num_medvac + 1
    WHERE id = in_pig_prod_id;
END IF;


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_medvac_id                       AS medvac_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_medvac_update $$
CREATE PROCEDURE pig_medvac_update(
    in_user_id              INT,
    in_pig_medvac_id        INT,

    in_date_medvac          VARCHAR(10),
    in_medvac_brand_id      INT,
    in_medvac_type_id       INT,
    in_acc_medvac_id        INT,
    in_staff_id             INT,
    
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_medvac entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since January 8, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_INACTIVE_STATUS        INT             DEFAULT 20;
DECLARE RES_NUM_SOW_BOAR_INACTIVE_STATUS        INT             DEFAULT 21;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;






DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;





DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_medvac_account_id               INT             DEFAULT 0;
DECLARE cur_sow_boar_id                         INT             DEFAULT 0;
DECLARE cur_sow_boar_is_disposed                INT             DEFAULT 0;
DECLARE cur_sow_boar_sow_status_id              INT             DEFAULT 0;
DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_is_active_status                    INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT 
    a.account_id,
    a.sow_boar_id,
    b.is_disposed,
    b.sow_status_id,
    a.pig_prod_id,
    c.prod_status_id
INTO 
    cur_pig_medvac_account_id,
    cur_sow_boar_id,
    cur_sow_boar_is_disposed,
    cur_sow_boar_sow_status_id,
    cur_pig_prod_id,
    cur_pig_prod_status_id
    
    
FROM pig_medvac a 
LEFT OUTER JOIN sow_boar b          ON a.sow_boar_id = b.id
LEFT OUTER JOIN pig_production c    ON a.pig_prod_id = c.id

WHERE a.id = in_pig_medvac_id;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_medvac_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* Check pig_production status*/
IF cur_pig_prod_id > 0 THEN
    SET cur_is_active_status = 0;
    CALL pig_prod_check_active_status(cur_pig_prod_status_id, cur_is_active_status);
    
    IF cur_is_active_status = 0 THEN 
        SET res_num     = RES_NUM_PIG_PROD_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_PIG_PROD_INACTIVE_STATUS";
    
        LEAVE process_user;
    END IF;
END IF;


/* Check sow_boar status*/
IF cur_sow_boar_id > 0 THEN 
    IF cur_sow_boar_is_disposed > 0 THEN 
        SET res_num     = RES_NUM_SOW_BOAR_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_SOW_BOAR_INACTIVE_STATUS";
        
        LEAVE process_user;
    END IF;
    
END IF;


UPDATE pig_medvac  SET
    date_medvac         = in_date_medvac,
    
    medvac_brand_id     = in_medvac_brand_id,
    medvac_type_id      = in_medvac_type_id,
    acc_medvac_id       = in_acc_medvac_id,
    
    staff_id            = in_staff_id,
    notes               = in_notes,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_pig_medvac_id;


IF cur_sow_boar_id > 0 THEN 
    UPDATE sow_boar SET
        data_ver_num_medvac = data_ver_num_medvac + 1 
    WHERE id = cur_sow_boar_id;
END IF;


IF cur_pig_prod_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_medvac = data_ver_num_medvac + 1
    WHERE id = cur_pig_prod_id;
END IF;




END process_user;




SELECT 
    res_num             AS result_number,
    res_code            AS result_code,
    res_desc            AS result_desc;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_add $$
CREATE PROCEDURE pig_farm_add(
    in_user_id              INT,

    in_name                 VARCHAR(50),
    
    in_new_country_code     VARCHAR(5),
    in_new_country_name     VARCHAR(50),
    
    
    in_country_id           INT, 
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5)
    
)  

BEGIN

/** 
 * Will add pig farm entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_app_country_id                      INT             DEFAULT 0;


DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_flag                       INT             DEFAULT 0;
DECLARE cur_pig_farm_name                       VARCHAR(50)     DEFAULT '';

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
    
    BUSINESS_OBJ_ID_PIG_FARM,
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



/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_farm_id
FROM    pig_farm
WHERE   account_id = cur_user_account_id AND UPPER(name)  = UPPER(in_name)
LIMIT   1;

IF cur_pig_farm_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* Create new app_country if not yet created.*/
IF in_new_country_code IS NOT NULL THEN 
    SELECT  id 
    INTO    cur_app_country_id
    FROM    app_country
    WHERE   country_code = in_new_country_code
    LIMIT   1;
    
    IF cur_app_country_id = 0 THEN 
        INSERT INTO app_country(
            country_code,
            name
        )
        VALUES(
            in_new_country_code,
            in_new_country_name
        );
        
        SELECT LAST_INSERT_ID() INTO cur_app_country_id;
    
    END IF;
    
    SET in_country_id = cur_app_country_id;

END IF;



INSERT INTO pig_farm(
    account_id,
    flag,
    name,
    
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    latitude,
    longitude,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    1,    
    in_name,
    
    in_country_id,
    in_address_level_1_id,
    in_address_level_2_id,
    in_address_level_3_id,
    in_latitude,
    in_longitude,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_farm_id;


/*Insert into user_pig_farm*/
INSERT INTO user_pig_farm(
    pig_farm_id,
    user_id,
    added_by_user_id
) VALUES (
    cur_pig_farm_id,
    in_user_id,
    in_user_id
);



/* Count the farms already in the account*/
SELECT  COUNT(*)
INTO    cur_count
FROM    pig_farm
WHERE   account_id =  cur_user_account_id;


/* Update the account country based on the first pig_farm country. */
IF cur_count = 1 THEN 
    UPDATE account SET
        country_id      = in_country_id,
        default_farm_id = cur_pig_farm_id
    WHERE id = cur_user_account_id;

END IF;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_flag,
    cur_pig_farm_name
FROM pig_farm
WHERE id = cur_pig_farm_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_id                     AS pig_farm_id,
    cur_pig_farm_flag                   AS pig_farm_flag,
    cur_pig_farm_name                   AS pig_farm_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_update $$
CREATE PROCEDURE pig_farm_update(
    in_user_id              INT,
    in_pig_farm_id          INT,

    in_name                 VARCHAR(50),
    
    in_country_id           INT, 
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5)
    
)  

BEGIN

/** 
 * Will update pig farm entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_farm_account_id                     INT             DEFAULT 0;


DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_flag                       INT             DEFAULT 0;
DECLARE cur_pig_farm_name                       VARCHAR(50)     DEFAULT '';



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_farm_account_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_FARM,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



UPDATE pig_farm SET
    name                = in_name,
    
    country_id          = in_country_id,
    address_level_1_id  = in_address_level_1_id,
    address_level_2_id  = in_address_level_2_id,
    address_level_3_id  = in_address_level_3_id,
    latitude            = in_latitude,
    longitude           = in_longitude,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_pig_farm_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_flag,
    cur_pig_farm_name
FROM pig_farm
WHERE id = in_pig_farm_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_id                     AS pig_farm_id,
    cur_pig_farm_flag                   AS pig_farm_flag,
    cur_pig_farm_name                   AS pig_farm_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_balance_add $$
CREATE PROCEDURE sow_boar_balance_add(
    in_user_id              INT,
    in_pig_farm_id          INT,
    
    in_date_balance         VARCHAR(10),
    
    in_num_gestating        DECIMAL(5,1),
    in_num_finisher         DECIMAL(5,1)
)  

BEGIN

/** 
 * Will sow_boar_balance entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 7, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR_BALANCE        INT             DEFAULT 30;


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


DECLARE SOW_STATUS_ID_LACTATING                 INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_sows_total                          INT             DEFAULT 0;
DECLARE cur_boars_total                         INT             DEFAULT 0;
DECLARE cur_sows_lactating                      INT             DEFAULT 0;
DECLARE cur_sows_gestating                      INT             DEFAULT 0;



DECLARE cur_sow_boar_balance_id                 INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  account_id
INTO    cur_pig_farm_account_id
FROM    pig_farm 
WHERE   id = in_pig_farm_id;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SOW_BOAR_BALANCE,
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




/* Check for duplicate entry */

SELECT  id
INTO    cur_sow_boar_balance_id
FROM    sow_boar_balance
WHERE   pig_farm_id         = in_pig_farm_id    AND
        date_balance        = in_date_balance
LIMIT   1;
    


IF cur_sow_boar_balance_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/*
sow_boar.flag bits
DECLARE FLAG_BIT_SOW_BOAR_IS_DISPOSED           INT             DEFAULT 1;
DECLARE FLAG_BIT_SOW_BOAR_IS_EXTERNAL           INT             DEFAULT 2;

*/

/* Snap shot sows and boars*/
SELECT  COUNT(*)
INTO    cur_sows_total 
FROM    sow_boar 
WHERE   pig_farm_id = in_pig_farm_id AND sex = 'F' AND (flag & 3) = 0;

SELECT  COUNT(*)
INTO    cur_boars_total 
FROM    sow_boar 
WHERE   pig_farm_id = in_pig_farm_id AND sex = 'M' AND (flag & 3) = 0;


SELECT  COUNT(*)
INTO    cur_sows_lactating 
FROM    sow_boar 
WHERE   pig_farm_id = in_pig_farm_id AND sex = 'F' AND (flag & 3) = 0 AND 
        sow_status_id = SOW_STATUS_ID_LACTATING;

SET cur_sows_gestating  = cur_sows_total - cur_sows_lactating;


INSERT INTO sow_boar_balance(
    pig_farm_id,
    
    date_balance,
    
    num_sows,
    num_boars,
    num_sows_lactating,
    num_sows_gestating,
    
    num_gestating,   
    num_finisher,

    added_by_user_id
) VALUES (
    in_pig_farm_id,
    
    in_date_balance,
    
    cur_sows_total,
    cur_boars_total,
    cur_sows_lactating,
    cur_sows_gestating,
    
    in_num_gestating,
    in_num_finisher,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_sow_boar_balance_id;



UPDATE pig_farm SET
    last_sow_boar_balance_id = cur_sow_boar_balance_id
WHERE id = in_pig_farm_id;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_sow_boar_balance_id             AS sow_boar_balance_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_feed_buy_add $$
CREATE PROCEDURE pig_farm_feed_buy_add(
    in_user_id              INT,
    
    in_pig_farm_id          INT,
    
    in_date_buy             VARCHAR(10),
    in_feed_supplier_id     INT,
    in_other_cost           DECIMAL(8,2)
) 
 
BEGIN
/**
 * Will add pig_farm_feed_buy entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 2, 2026
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;

DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;

/* common_supplier.flag bits*/
DECLARE FLAG_BIT_SUPPLIER_IS_DELETED            INT             DEFAULT 1;
DECLARE FLAG_BIT_SUPPLIER_IS_VERIFIED           INT             DEFAULT 2;


DECLARE MIN_COUNT_SUPPLIER_IS_VERIFIED          INT             DEFAULT 3;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_feed_buy_id                INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  account_id
INTO    cur_pig_farm_account_id
FROM    pig_farm 
WHERE   id = in_pig_farm_id;

CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    BUSINESS_OBJ_ID_FEED_BUY,
    FLAG_BIT_OPERATION_ADD,
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user: BEGIN
IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


SELECT  id
INTO    cur_pig_farm_feed_buy_id
FROM    pig_farm_feed_buy
WHERE   pig_farm_id         = in_pig_farm_id    AND
        date_buy            = in_date_buy       AND
        feed_supplier_id    = in_feed_supplier_id
LIMIT   1;



IF cur_pig_farm_feed_buy_id = 0 THEN 
    INSERT INTO pig_farm_feed_buy(
        account_id,
        pig_farm_id,
        
        date_buy,
        feed_supplier_id,
        other_cost,
        
        added_by_user_id
    ) VALUES (
        cur_pig_farm_account_id,
        in_pig_farm_id,
        
        in_date_buy,
        in_feed_supplier_id,
        in_other_cost,
        
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_farm_feed_buy_id;

    SET cur_count = 0;

    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id = cur_pig_farm_account_id AND 
            feed_supplier_id = in_feed_supplier_id;

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            feed_supplier_id,
            added_by_user_id
        ) VALUES (
            cur_pig_farm_account_id, 
            in_feed_supplier_id,
            in_user_id
        );
    END IF;


    /*Compute common_supplier.flag.FLAG_BIT_SUPPLIER_IS_VERIFIED*/
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   (feed_supplier_id = in_feed_supplier_id OR
            semen_supplier_id = in_feed_supplier_id OR
            gilt_supplier_id  = in_feed_supplier_id) AND 
            
            account_id !=  cur_user_account_id;
            
    /* Update common_supplier.flag.FLAG_BIT_SUPPLIER_IS_VERIFIED*/
    IF cur_count >= MIN_COUNT_SUPPLIER_IS_VERIFIED THEN
        UPDATE common_supplier SET 
            flag = flag | FLAG_BIT_SUPPLIER_IS_VERIFIED
        WHERE id = in_feed_supplier_id;
    END IF;


    /* Update supplier account counter and usage*/
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   feed_supplier_id = in_feed_supplier_id;

    UPDATE  common_supplier SET 
        fs_account_counter  = cur_count,
        fs_usage_counter    = fs_usage_counter + 1
    WHERE id = in_feed_supplier_id;

ELSE
    UPDATE pig_farm_feed_buy SET
        other_cost          = in_other_cost,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP
    WHERE id = cur_pig_farm_feed_buy_id;

END IF;



UPDATE pig_farm SET 
    data_ver_num_feed_buy = data_ver_num_feed_buy + 1
WHERE id = in_pig_farm_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    cur_pig_farm_feed_buy_id            AS pig_farm_feed_buy_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_feed_buy_item_add $$
CREATE PROCEDURE pig_farm_feed_buy_item_add(
    in_user_id              INT,
    
    in_pig_farm_feed_buy_id INT,
    
    in_feed_type_id         INT,
    in_feed_brand_id        INT,
    
    in_quantity             INT,
    in_kg_per_unit          DECIMAL(5,1),
    
    in_unit_cost            DECIMAL(8,2),
    in_total_cost           DECIMAL(10,2)
)  

BEGIN

/** 
 * Will add pig_farm_feed_buy item into feed_buy table;.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 2, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;

/* feed_brand.flag bits*/
DECLARE FLAG_BIT_FEED_BRAND_IS_DELETED          INT             DEFAULT 1;
DECLARE FLAG_BIT_FEED_BRAND_IS_VERIFIED         INT             DEFAULT 2;

/* feed_buy.flag bits*/
DECLARE FLAG_BIT_FEED_BUY_IS_DELETED            INT             DEFAULT 1;


DECLARE MIN_COUNT_ACCOUNT_FEED_BRAND_IS_VERIFIED    INT         DEFAULT 3;
DECLARE MIN_COUNT_ACCOUNT_FEED_SUPPLIER_IS_VERIFIED INT         DEFAULT 3;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;

DECLARE cur_pf_feed_buy_date_buy                DATE            DEFAULT NULL;
DECLARE cur_pf_feed_buy_feed_supplier_id        INT             DEFAULT 0;


DECLARE cur_feed_buy_id                         INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;


DECLARE cur_feed_buy_total_cost                 DECIMAL(10,2)   DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.pig_farm_id,
        a.account_id 

INTO    cur_pig_farm_id,
        cur_pig_farm_account_id
        
FROM pig_farm_feed_buy a 
WHERE a.id = in_pig_farm_feed_buy_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
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



/* Check for duplicate entry */

SELECT  id
INTO    cur_feed_buy_id
FROM    feed_buy
WHERE   pig_farm_feed_buy_id    = in_pig_farm_feed_buy_id    AND
        feed_type_id            = in_feed_type_id   AND 
        feed_brand_id           = in_feed_brand_id
LIMIT   1;
    


IF cur_feed_buy_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


SELECT 
    date_buy,
    feed_supplier_id

INTO 
    cur_pf_feed_buy_date_buy,
    cur_pf_feed_buy_feed_supplier_id

FROM pig_farm_feed_buy
WHERE id = in_pig_farm_feed_buy_id;
    
    

INSERT INTO feed_buy(
    pig_farm_feed_buy_id,
    
    date_buy,
    
    feed_type_id,
    feed_brand_id,
    feed_supplier_id,
    
    quantity,
    kg_per_unit,
    kg_total,
    
    unit_cost,
    total_cost,
    
    added_by_user_id

) VALUES (
    in_pig_farm_feed_buy_id,
    
    cur_pf_feed_buy_date_buy,
    
    in_feed_type_id,
    in_feed_brand_id,
    cur_pf_feed_buy_feed_supplier_id,
    
    in_quantity,
    in_kg_per_unit,
    in_quantity * in_kg_per_unit,
    
    in_unit_cost,
    in_total_cost,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_buy_id;




/* Insert INTO account_selection*/
SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_pig_farm_account_id AND 
        feed_brand_id = in_feed_brand_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        feed_brand_id,
        added_by_user_id
    ) VALUES (
        cur_pig_farm_account_id,
        in_feed_brand_id,
        in_user_id
    );
END IF;




/* Update feed_brand counter. */
SELECT  COUNT(*)
INTO    cur_count
FROM    account_selection
WHERE   feed_brand_id = in_feed_brand_id;

UPDATE  feed_brand SET
    account_counter = cur_count
WHERE id = in_feed_brand_id;


/* Update feed_brand.flag.FLAG_BIT_FEED_BRAND_IS_VERIFIED*/
IF cur_count >= MIN_COUNT_ACCOUNT_FEED_BRAND_IS_VERIFIED THEN 
    UPDATE feed_brand SET
        flag = flag | FLAG_BIT_FEED_BRAND_IS_VERIFIED
    WHERE id = in_feed_brand_id;

END IF;


/* Add up all feeds cost related to pig_farm_feed_buy*/
SELECT  SUM(total_cost)
INTO    cur_feed_buy_total_cost
FROM    feed_buy
WHERE   pig_farm_feed_buy_id = in_pig_farm_feed_buy_id;

UPDATE pig_farm_feed_buy SET 
    total_feed_cost =  cur_feed_buy_total_cost
WHERE id = in_pig_farm_feed_buy_id;



UPDATE pig_farm SET 
    data_ver_num_feed_buy = data_ver_num_feed_buy + 1
WHERE id = cur_pig_farm_id;



END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_buy_id                     AS feed_buy_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_feed_buy_item_delete $$
CREATE PROCEDURE pig_farm_feed_buy_item_delete(
    in_user_id              INT,
    
    in_pig_farm_feed_buy_id INT,
    
    in_feed_type_id         INT,
    in_feed_brand_id        INT,
    
    in_quantity             INT,
    in_kg_per_unit          DECIMAL(5,1),
    
    in_unit_cost            DECIMAL(8,2),
    in_total_cost           DECIMAL(10,2)
)  

BEGIN

/** 
 * Will add pig_farm_feed_buy item into feed_buy table;.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 2, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;

/* feed_brand.flag bits*/
DECLARE FLAG_BIT_FEED_BRAND_IS_DELETED          INT             DEFAULT 1;
DECLARE FLAG_BIT_FEED_BRAND_IS_VERIFIED         INT             DEFAULT 2;


DECLARE MIN_COUNT_ACCOUNT_FEED_BRAND_IS_VERIFIED    INT         DEFAULT 3;
DECLARE MIN_COUNT_ACCOUNT_FEED_SUPPLIER_IS_VERIFIED INT         DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;

DECLARE cur_pf_feed_buy_date_buy                DATE            DEFAULT NULL;
DECLARE cur_pf_feed_buy_feed_supplier_id        INT             DEFAULT 0;


DECLARE cur_feed_buy_id                         INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;


DECLARE cur_feed_buy_total_cost                 DECIMAL(10,2)   DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.pig_farm_id,
        a.account_id 

INTO    cur_pig_farm_id,
        cur_pig_farm_account_id
        
FROM pig_farm_feed_buy a 
WHERE a.id = in_pig_farm_feed_buy_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
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



/* Check for duplicate entry */

SELECT  id
INTO    cur_feed_buy_id
FROM    feed_buy
WHERE   pig_farm_feed_buy_id    = in_pig_farm_feed_buy_id    AND
        feed_type_id            = in_feed_type_id   AND 
        feed_brand_id           = in_feed_brand_id
LIMIT   1;
    


IF cur_feed_buy_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


SELECT 
    date_buy,
    feed_supplier_id

INTO 
    cur_pf_feed_buy_date_buy,
    cur_pf_feed_buy_feed_supplier_id

FROM pig_farm_feed_buy
WHERE id = in_pig_farm_feed_buy_id;
    
    

INSERT INTO feed_buy(
    pig_farm_feed_buy_id,
    
    date_buy,
    
    feed_type_id,
    feed_brand_id,
    feed_supplier_id,
    
    quantity,
    kg_per_unit,
    kg_total,
    
    unit_cost,
    total_cost,
    
    added_by_user_id

) VALUES (
    in_pig_farm_feed_buy_id,
    
    cur_pf_feed_buy_date_buy,
    
    in_feed_type_id,
    in_feed_brand_id,
    cur_pf_feed_buy_feed_supplier_id,
    
    in_quantity,
    in_kg_per_unit,
    in_quantity * in_kg_per_unit,
    
    in_unit_cost,
    in_total_cost,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_buy_id;




/* Insert INTO account_selection*/
SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_pig_farm_account_id AND 
        feed_brand_id = in_feed_brand_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        feed_brand_id,
        added_by_user_id
    ) VALUES (
        cur_pig_farm_account_id,
        in_feed_brand_id,
        in_user_id
    );
END IF;




/* Update feed_brand counter. */
SELECT  COUNT(*)
INTO    cur_count
FROM    account_selection
WHERE   feed_brand_id = in_feed_brand_id;

UPDATE  feed_brand SET
    account_counter = cur_count
WHERE id = in_feed_brand_id;


/* Update feed_brand.flag.FLAG_BIT_FEED_BRAND_IS_VERIFIED*/
IF cur_count >= MIN_COUNT_ACCOUNT_FEED_BRAND_IS_VERIFIED THEN 
    UPDATE feed_brand SET
        flag = flag | FLAG_BIT_FEED_BRAND_IS_VERIFIED
    WHERE id = in_feed_brand_id;

END IF;


/* Add up all feeds cost related to pig_farm_feed_buy*/
SELECT  SUM(total_cost)
INTO    cur_feed_buy_total_cost
FROM    feed_buy
WHERE   pig_farm_feed_buy_id = in_pig_farm_feed_buy_id;

UPDATE pig_farm_feed_buy SET 
    total_feed_cost =  cur_feed_buy_total_cost
WHERE id = in_pig_farm_feed_buy_id;




END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_buy_id                     AS feed_buy_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_feed_buy_item_update $$
CREATE PROCEDURE pig_farm_feed_buy_item_update(
    in_user_id              INT,
    
    in_feed_buy_id          INT,
    
    in_feed_type_id         INT,
    in_feed_brand_id        INT,
    in_quantity             INT,
    in_kg_per_unit          DECIMAL(5,1),
    
    in_unit_cost            DECIMAL(8,2),
    in_total_cost           DECIMAL(8,2)
)  

BEGIN

/** 
 * Will update pig_farm_feed_buy_item entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 12, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;

/* feed_brand.flag bits*/
DECLARE FLAG_BIT_FEED_BRAND_IS_DELETED          INT             DEFAULT 1;
DECLARE FLAG_BIT_FEED_BRAND_IS_VERIFIED         INT             DEFAULT 2;


DECLARE MIN_COUNT_ACCOUNT_FEED_BRAND_IS_VERIFIED    INT         DEFAULT 3;
DECLARE MIN_COUNT_ACCOUNT_FEED_SUPPLIER_IS_VERIFIED INT         DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_pig_farm_feed_buy_id                INT             DEFAULT 0;
DECLARE cur_pig_farm_feed_buy_account_id        INT             DEFAULT 0;
DECLARE cur_pig_farm_id                         INT             DEFAULT 0;


DECLARE cur_feed_buy_id                         INT             DEFAULT 0;

DECLARE cur_feed_buy_total_cost                 DECIMAL(10,2)   DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.pig_farm_feed_buy_id,
        b.account_id,
        b.pig_farm_id 

INTO    cur_pig_farm_feed_buy_id,
        cur_pig_farm_feed_buy_account_id,
        cur_pig_farm_id
        
FROM feed_buy a 
LEFT OUTER JOIN pig_farm_feed_buy b ON a.pig_farm_feed_buy_id = b.id
WHERE a.id = in_feed_buy_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_feed_buy_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
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





UPDATE feed_buy SET
    feed_type_id        = in_feed_type_id,
    feed_brand_id       = in_feed_brand_id,
    
    quantity            = in_quantity,
    kg_per_unit         = in_kg_per_unit,
    kg_total            = in_quantity * in_kg_per_unit,
    
    unit_cost           = in_unit_cost,
    total_cost          = in_total_cost,
    
    last_update_user_id = in_user_id,
    dT_last_update      = CURRENT_DATE    
WHERE id = in_feed_buy_id;


/* Add up all feeds cost related to pig_farm_feed_buy*/
SELECT  SUM(total_cost)
INTO    cur_feed_buy_total_cost
FROM    feed_buy
WHERE   pig_farm_feed_buy_id = cur_pig_farm_feed_buy_id;

UPDATE pig_farm_feed_buy SET 
    total_feed_cost =  cur_feed_buy_total_cost
WHERE id = cur_pig_farm_feed_buy_id;



UPDATE pig_farm SET 
    data_ver_num_feed_buy = data_ver_num_feed_buy + 1
WHERE id = cur_pig_farm_id;



END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_buy_id                     AS feed_buy_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_feed_buy_update $$
CREATE PROCEDURE pig_farm_feed_buy_update(
    in_user_id              INT,
    
    in_pig_farm_feed_buy_id INT,
    
    in_date_buy             VARCHAR(10),
    in_feed_supplier_id     INT,
    in_other_cost           DECIMAL(8,2)
)  

BEGIN

/** 
 * Will update pig_farm_feed_buy entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 2, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;




DECLARE cur_pig_farm_feed_buy_id                INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.pig_farm_id,
        a.account_id 

INTO    cur_pig_farm_id,
        cur_pig_farm_account_id
        
FROM pig_farm_feed_buy a 
WHERE a.id = in_pig_farm_feed_buy_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
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



UPDATE pig_farm_feed_buy SET 
    date_buy            = in_date_buy,
    feed_supplier_id    = in_feed_supplier_id,
    other_cost          = in_other_cost,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_pig_farm_feed_buy_id;


/* propagate change to feed_buy*/
UPDATE feed_buy SET
    date_buy            = in_date_buy,
    feed_supplier_id    = in_feed_supplier_id,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE 
    pig_farm_feed_buy_id = in_pig_farm_feed_buy_id;


UPDATE pig_farm SET 
    data_ver_num_feed_buy = data_ver_num_feed_buy + 1
WHERE id = cur_pig_farm_id;


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_farm_feed_buy_id             AS pig_farm_feed_buy_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS app_analytics_add $$
CREATE PROCEDURE app_analytics_add(
    in_user_id              INT,

    in_app_function_id      INT
)  

BEGIN

/** 
 * Will add app_analytics entry to the system.
 * This is not a user initiated request but for system usage.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */


DECLARE cur_user_account_id                     INT             DEFAULT 0;


SELECT  account_id
INTO    cur_user_account_id
FROM    user
WHERE   id = in_user_id;

INSERT INTO app_analytics(
    account_id,
    user_id,
    app_function_id,
    date_usage
) VALUES (
    cur_user_account_id,
    in_user_id,
    in_app_function_id,
    CURRENT_DATE
);


SELECT 1;

END $$



DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_ops_update $$
CREATE PROCEDURE pig_prod_pig_ops_update(
    in_user_id                  INT,
   
    in_pig_prod_pig_ops_id      INT,
    in_staff_id                 INT,
    in_done_by_user             INT, 
    
    in_date                     VARCHAR(10),
    in_notes                    VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_pig_ops entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_BE_UDPATED               INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;

DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_operation_type     INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_notes_id           INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_prod_pig_ops_id                     INT             DEFAULT 0;

DECLARE cur_prod_notes                          VARCHAR(160)    DEFAULT NULL;


DECLARE cur_acc_pig_ops_name                    VARCHAR(50);
DECLARE cur_staff_name                          VARCHAR(50);
DECLARE cur_notes                               VARCHAR(200);

DECLARE added_new_staff                         INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        b.account_id,
        b.pig_farm_id,
        b.sow_id,
        a.pig_prod_id,
        a.operation_type,
        b.prod_status_id,
        a.notes_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_id,
        cur_pig_prod_pig_ops_operation_type,
        cur_pig_prod_status_id,
        cur_pig_prod_pig_ops_notes_id
        
FROM    pig_prod_pig_ops a
LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id
WHERE   a.id = in_pig_prod_pig_ops_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN


IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;



IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
    IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
        SET res_num     = RES_NUM_CANNOT_BE_UDPATED;
        SET res_code    = "RES_NUM_CANNOT_BE_UDPATED";
        
        LEAVE process_user;
    END IF;
END IF;



SELECT  b.name
INTO    cur_acc_pig_ops_name
FROM    pig_prod_pig_ops a 
LEFT OUTER JOIN account_pig_ops b ON a.account_pig_ops_id = b.id 
WHERE   a.id = in_pig_prod_pig_ops_id;


SELECT  name
INTO    cur_staff_name
FROM    pig_farm_staff
WHERE   id = in_staff_id;



IF cur_pig_prod_pig_ops_notes_id IS NULL OR cur_pig_prod_pig_ops_notes_id = 0 THEN 
    
    /* This is necessary as notes is optional; It will leave blank in table row 
     UI if no notes.*/


    SET cur_notes  = CONCAT('Pig operation(', cur_acc_pig_ops_name ,') done by ', cur_staff_name, '. ');


    IF in_notes IS NOT NULL THEN 
        SET cur_notes  = CONCAT(cur_notes, in_notes);
    END IF;


    /* Truncate notes if needed. */
    IF LENGTH(cur_notes) >= 160 THEN 
        SET cur_notes = SUBSTRING(cur_notes, 1, 159);
    END IF;

    
    /* Should relate to both sow and pig_prod*/
    IF cur_pig_prod_pig_ops_operation_type IN ( PIG_OPERATION_TYPE_GESTATING,
                                                PIG_OPERATION_TYPE_LACTATING_SOW) THEN
        INSERT INTO pig_prod_notes (
            account_id,
            pig_farm_id,
            
            
            pig_prod_id,
            sow_boar_id,
            production_group_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            
            cur_pig_prod_id,
            cur_pig_prod_sow_id,
            NULL,
            
            cur_notes,
            in_date,
            in_user_id
        );
    END iF;
    
    
    /** Should not relate to sow if operation is for piglets*/
    IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS THEN 
    
        INSERT INTO pig_prod_notes (
            account_id,
            pig_farm_id,
            
            pig_prod_id,
            sow_boar_id,
            production_group_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            
            cur_pig_prod_id,
            NULL,
            NULL,
            
            cur_notes,
            in_date,
            in_user_id
        );
    END IF;
    
    
    /** Should only relate to sow*/
    IF cur_pig_prod_pig_ops_operation_type IN ( PIG_OPERATION_TYPE_GILT_OPS,
                                                PIG_OPERATION_TYPE_WEANING_SOW_OPS) THEN
        INSERT INTO pig_prod_notes (
            account_id,
            pig_farm_id,
            
            pig_prod_id,
            sow_boar_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            
            NULL,
            cur_pig_prod_sow_id,
            
            cur_notes,
            in_date,
            in_user_id
        );
    
    END IF;


    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    UPDATE pig_prod_pig_ops SET
        notes_id            = cur_pig_prod_notes_id
    WHERE id = in_pig_prod_pig_ops_id;

ELSE
    
    
    UPDATE pig_prod_notes SET 
        date_notes          = in_date,
        notes               = in_notes,
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP
    WHERE id = cur_pig_prod_pig_ops_notes_id;

END IF;


/* If done by user, user will be added to staff list.
Note: not all staff are users
*/
IF in_done_by_user > 0 THEN
    SELECT  pig_farm_staff_id,
            name_first,
            name_last
    
    INTO    cur_user_staff_id,
            cur_user_name_first,
            cur_user_name_last
    FROM    user 
    WHERE   id = in_user_id;
    
    
    IF cur_user_staff_id = 0 THEN 
        INSERT INTO pig_farm_staff (
            account_id,
            pig_farm_id,
            user_id,
            name,
            
            added_by_user_id
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            in_user_id,
            CONCAT(cur_user_name_first, ' ', cur_user_name_last),
            
            in_user_id
        );
        SELECT LAST_INSERT_ID() INTO cur_user_staff_id;
        
        
        UPDATE user SET 
            pig_farm_staff_id = cur_user_staff_id
        WHERE id = in_user_id;
        
        SET added_new_staff = 1;
        
    END IF;
    
    
    SET in_staff_id = cur_user_staff_id;
    
END IF;


UPDATE pig_prod_pig_ops SET
    date_actual         = in_date,
    staff_id            = in_staff_id,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_pig_prod_pig_ops_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_pig_ops_id              AS pig_prod_pig_ops_id,
    added_new_staff                     AS added_new_staff,
    cur_pig_prod_pig_farm_id            AS pig_farm_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_ops_medvac_update $$
CREATE PROCEDURE pig_prod_pig_ops_medvac_update(
    in_user_id              INT,
   
    in_pig_prod_pig_ops_id  INT,
    in_staff_id             INT,
    in_done_by_user         INT,

    in_medvac_brand_id      INT,
    in_medvac_type_id       INT,
    in_acc_medvac_id        INT,
    
    in_date                 VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_pig_ops entry. This is the variation if the pigops is a medvac.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_SOW_BOAR_ALREADY_DISPOSED       INT             DEFAULT 20;

DECLARE RES_NUM_PIG_PROD_INACTIVE_STATUS        INT             DEFAULT 21;
DECLARE RES_NUM_CANNOT_BE_UDPATED               INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_sow_boar_id        INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_operation_type     INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_notes_id           INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_pig_medvac_id      INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_prod_pig_ops_id                     INT             DEFAULT 0;


DECLARE cur_sow_is_disposed                     INT             DEFAULT 0;

DECLARE cur_is_active_status                    INT             DEFAULT 0;

DECLARE cur_medvac_id                           INT             DEFAULT 0;

DECLARE cur_acc_pig_ops_name                    VARCHAR(50);
DECLARE cur_staff_name                          VARCHAR(50);
DECLARE cur_notes                               VARCHAR(200);

DECLARE added_new_staff                         INT             DEFAULT 0;


DECLARE cur_u_brand_name                        VARCHAR(50)     DEFAULT '';
DECLARE cur_u_type_name                         VARCHAR(50)     DEFAULT '';
DECLARE cur_u_acc_medvac_name                   VARCHAR(50)     DEFAULT '';
DECLARE cur_u_medvac_notes                      VARCHAR(160)    DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        b.account_id,
        b.pig_farm_id,
        a.pig_prod_id,
        b.sow_id,           /*This is pig_production.sow_id*/
        a.sow_boar_id,      /*This is pig_prod_pig_ops.sow_boar_id*/
        
        a.operation_type,
        b.prod_status_id,
        a.notes_id,
        a.pig_medvac_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_pig_ops_sow_boar_id,
        
        cur_pig_prod_pig_ops_operation_type,
        cur_pig_prod_status_id,
        cur_pig_prod_pig_ops_notes_id,
        cur_pig_prod_pig_ops_pig_medvac_id
        
FROM    pig_prod_pig_ops a
LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id
WHERE   a.id = in_pig_prod_pig_ops_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN


IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* Check sow_boar status*/
IF cur_pig_prod_pig_ops_sow_boar_id > 0 THEN
    /** Check sow_status if not yet disposed*/
    SELECT  is_disposed
    INTO    cur_sow_is_disposed
    FROM    sow_boar
    WHERE   id  = cur_pig_prod_pig_ops_sow_boar_id;
    
    
    IF cur_sow_is_disposed  > 0 THEN 
        SET res_num     = RES_NUM_SOW_BOAR_ALREADY_DISPOSED;
        SET res_code    = "RES_NUM_SOW_BOAR_ALREADY_DISPOSED";
        
        LEAVE process_user;
    END IF;
    
END IF;


/* Check pig_production status*/
IF cur_pig_prod_id > 0 THEN 
    SET cur_is_active_status = 0;
    CALL pig_prod_check_active_status(cur_pig_prod_status_id, cur_is_active_status);
    
    IF cur_is_active_status = 0 THEN 
        SET res_num     = RES_NUM_PIG_PROD_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_PIG_PROD_INACTIVE_STATUS";
    
        LEAVE process_user;
    END IF;


    IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
        IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
            SET res_num     = RES_NUM_CANNOT_BE_UDPATED;
            SET res_code    = "RES_NUM_CANNOT_BE_UDPATED";
            
            LEAVE process_user;
        END IF;
    END IF;
    
    
    IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS THEN 
        IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_LACTATING THEN 
            SET res_num     = RES_NUM_CANNOT_BE_UDPATED;
            SET res_code    = "RES_NUM_CANNOT_BE_UDPATED";
            
            LEAVE process_user;
        END IF;
    END IF;
    

END IF;


IF cur_pig_prod_pig_ops_notes_id IS NULL OR cur_pig_prod_pig_ops_notes_id = 0 THEN 
    
    /* This is necessary as notes is optional; It will leave blank in table row 
     UI if no notes.*/


    SELECT  b.name
    INTO    cur_acc_pig_ops_name
    FROM    pig_prod_pig_ops a 
    LEFT OUTER JOIN account_pig_ops b ON a.account_pig_ops_id = b.id 
    WHERE   a.id = in_pig_prod_pig_ops_id;


    SELECT  name
    INTO    cur_staff_name
    FROM    pig_farm_staff
    WHERE   id = in_staff_id;

    SET cur_notes  = CONCAT('Pig operation(', cur_acc_pig_ops_name ,') done by ', cur_staff_name, '. ');


    IF in_notes IS NOT NULL THEN 
        SET cur_notes  = CONCAT(cur_notes, in_notes);
    END IF;


    /* Truncate notes if needed. */
    IF LENGTH(cur_notes) >= 160 THEN 
        SET cur_notes = SUBSTRING(cur_notes, 1, 159);
    END IF;

    
    /* Should not relate to SOW if operation is for piglets*/
    IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS THEN 
        INSERT INTO pig_prod_notes (
            account_id,
            pig_farm_id,
            pig_prod_id,
            production_group_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_pig_prod_account_id,
            NULL,
            cur_pig_prod_id,
            NULL,
            
            cur_notes,
            in_date,
            in_user_id
        );
    ELSE
        INSERT INTO pig_prod_notes (
            account_id,
            sow_boar_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_sow_id,
            
            cur_notes,
            in_date,
            in_user_id
        );
    END IF;

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    UPDATE pig_prod_pig_ops SET
        notes_id            = cur_pig_prod_notes_id
    WHERE id = in_pig_prod_pig_ops_id;
    
    SET cur_pig_prod_pig_ops_notes_id = cur_pig_prod_notes_id;

ELSE
    UPDATE pig_prod_notes SET 
        date_notes          = in_date,
        notes               = in_notes,
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP
    WHERE id = cur_pig_prod_pig_ops_notes_id;

END IF;


/* If done by user, user will be added to staff list.
Note: not all staff are users
*/
IF in_done_by_user > 0 THEN
    SELECT  pig_farm_staff_id,
            name_first,
            name_last
    
    INTO    cur_user_staff_id,
            cur_user_name_first,
            cur_user_name_last
    FROM    user 
    WHERE   id = in_user_id;
    
    
    IF cur_user_staff_id = 0 THEN 
        INSERT INTO pig_farm_staff (
            account_id,
            pig_farm_id,
            user_id,
            name,
            
            added_by_user_id
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            in_user_id,
            CONCAT(cur_user_name_first, ' ', cur_user_name_last),
            
            in_user_id
        );
        SELECT LAST_INSERT_ID() INTO cur_user_staff_id;
        
        
        UPDATE user SET 
            pig_farm_staff_id = cur_user_staff_id
        WHERE id = in_user_id;
        
        SET added_new_staff = 1;
        
    END IF;
    
    
    SET in_staff_id = cur_user_staff_id;
    
END IF;


UPDATE pig_prod_pig_ops SET
    date_actual         = in_date,
    staff_id            = in_staff_id,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_pig_prod_pig_ops_id;



/* These string copies of medvac_brand, medvac_type and medvac_name
are used for faster text search for medvac. 

Everytime a user type in key words for search in medvac entry,
it will search through these columns 

1.) u_brand_name
2.) u_type_name
3.) u_medvac_name
4.) u_medvac_notes

The medvac text search is performed using account_id not sow_boar_id, 
so this needs to be fast.

There is also a future plan to search for multiple accounts
with same pig_farm.address_level_2_id, which is even has more data sets to searched.

*/

SELECT  name
INTO    cur_u_brand_name 
FROM    medvac_brand
WHERE   id = in_medvac_brand_id;


SELECT  name
INTO    cur_u_type_name 
FROM    medvac_type
WHERE   id = in_medvac_type_id;


SELECT  name
INTO    cur_u_acc_medvac_name 
FROM    account_medvac
WHERE   id = in_acc_medvac_id;





IF cur_pig_prod_pig_ops_pig_medvac_id IS NULL THEN 
    
    /* Relate to SOW if operation is related to sow. */
    IF cur_pig_prod_pig_ops_operation_type IN (
                                    PIG_OPERATION_TYPE_GESTATING,
                                    PIG_OPERATION_TYPE_LACTATING_SOW,
                                    PIG_OPERATION_TYPE_GILT_OPS) THEN

        INSERT INTO pig_medvac(
    
            pig_prod_pig_ops_id,
            
            sow_boar_id,
            
            date_medvac,
            medvac_type_id,
            medvac_brand_id,
            acc_medvac_id,
    
            u_brand_name,
            u_type_name,
            u_acc_medvac_name,
            
            notes,
                    
            staff_id,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_pig_ops_id,
            
            cur_pig_prod_sow_id,
            
            in_date,
            in_medvac_type_id,
            in_medvac_brand_id,
            in_acc_medvac_id,
            
            cur_u_brand_name,
            cur_u_type_name,
            cur_u_acc_medvac_name,
            
            in_notes,
            
            in_staff_id,
            
            in_user_id
        );

        SELECT LAST_INSERT_ID() INTO cur_medvac_id;
        
        UPDATE pig_prod_pig_ops SET 
            pig_medvac_id = cur_medvac_id
        WHERE id = in_pig_prod_pig_ops_id;
        
    END IF;
    
    
    /* Relate to PIG_PROD if operation is related to piglets. */
    IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS THEN
        INSERT INTO pig_medvac(
    
            pig_prod_pig_ops_id,
            
            pig_prod_id,
            
            date_medvac,
            medvac_type_id,
            medvac_brand_id,
            acc_medvac_id,
    
            u_brand_name,
            u_type_name,
            u_acc_medvac_name,
            
            notes,
            
            
            staff_id,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_pig_ops_id,
            
            cur_pig_prod_id,
            
            in_date,
            in_medvac_type_id,
            in_medvac_brand_id,
            in_acc_medvac_id,
            
            cur_u_brand_name,
            cur_u_type_name,
            cur_u_acc_medvac_name,
            
            in_notes,
            
            in_staff_id,
            
            in_user_id
        );

        SELECT LAST_INSERT_ID() INTO cur_medvac_id;
        
        UPDATE pig_prod_pig_ops SET 
            pig_medvac_id = cur_medvac_id
        WHERE id = in_pig_prod_pig_ops_id;
    END IF;

ELSE
    /* Update MEDVAC*/
    
    UPDATE pig_medvac  SET
        date_medvac         = in_date,
        
        medvac_brand_id     = in_medvac_brand_id,
        medvac_type_id      = in_medvac_type_id,
        acc_medvac_id       = in_acc_medvac_id,
        
        staff_id            = in_staff_id,
        notes               = in_notes,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP
    WHERE id = cur_pig_prod_pig_ops_pig_medvac_id;


      
END IF;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_pig_ops_id              AS pig_prod_pig_ops_id,
    added_new_staff                     AS added_new_staff,
    cur_pig_prod_pig_farm_id            AS pig_farm_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_ops_add $$
CREATE PROCEDURE pig_prod_pig_ops_add(
    in_user_id              INT,
    
    in_account_id           INT,
    in_operation_type       INT,
    in_pig_prod_id          INT,
    in_date_reference       VARCHAR(10)
)  

BEGIN

/** 
 * A sub procedure to create pig_prod_pig_ops entries.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 30, 2025
 *
 */

DECLARE cur_account_flag_settings               INT             DEFAULT 0;
DECLARE cur_account_pig_ops_id                  INT             DEFAULT 0;
DECLARE cur_account_pig_ops_num_days            INT             DEFAULT 0;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_ops CURSOR FOR
    SELECT  id,
            num_days_since
    FROM    account_pig_ops
    WHERE   account_id = in_account_id      AND 
            operation_type = in_operation_type AND 
            (flag & 1) = 0
    ORDER BY num_days_since ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;


    
SET l_last_row_fetched=0;
OPEN c_account_pig_ops;   
    

loop_here: LOOP
    FETCH c_account_pig_ops INTO 
        cur_account_pig_ops_id,
        cur_account_pig_ops_num_days;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;


    /* Default*/
    SET num_days_to_add = cur_account_pig_ops_num_days;
    
	/* Need to adjust Day 1 counting.*/
    IF  in_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS OR 
        in_operation_type = PIG_OPERATION_TYPE_LACTATING_SOW THEN 
        
        IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH > 0 THEN 
            SET num_days_to_add = cur_account_pig_ops_num_days - 1;
        ELSE
            SET num_days_to_add = cur_account_pig_ops_num_days;
        END IF;
    END IF;
    
    
    IF in_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
        IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_INSEM > 0 THEN 
            SET num_days_to_add = cur_account_pig_ops_num_days - 1;
        ELSE
            SET num_days_to_add = cur_account_pig_ops_num_days;
        END IF;
    END IF;
    

    INSERT INTO pig_prod_pig_ops(
        pig_prod_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        in_pig_prod_id,
        cur_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(in_date_reference, INTERVAL num_days_to_add DAY)
    );
    

END LOOP loop_here;
 
CLOSE c_account_pig_ops;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_update $$
CREATE PROCEDURE account_update(
    in_user_id                  INT,
    
    in_name                     VARCHAR(100)
    
)

BEGIN

/** 
 * Will update account
 * @author Jack Wong
 * @since August 10, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;
DECLARE RES_NUM_USER_IS_INACTIVE                INT             DEFAULT 1;
DECLARE RES_NUM_USER_HAS_NO_ACCOUNT             INT             DEFAULT 2;
DECLARE RES_NUM_ACCOUNT_DISABLED                INT             DEFAULT 3;
DECLARE RES_NUM_ACCOUNT_STATUS_TRIAL_EXPIRED    INT             DEFAULT 4;
DECLARE RES_NUM_ACCOUNT_STATUS_UNPAID_BILL      INT             DEFAULT 5;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;


DECLARE BUSINESS_OBJ_ID_ACCOUNT                	INT             DEFAULT 2;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;
DECLARE cur_account_status_name                 VARCHAR(50);
DECLARE cur_account_name                        VARCHAR(100); 
DECLARE cur_account_date_trial_start            DATE;
DECLARE cur_account_date_trial_end              DATE;




DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";

CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, 
    
    BUSINESS_OBJ_ID_ACCOUNT,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);




process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



UPDATE account SET
    name                = in_name,

    data_ver_num_account = data_ver_num_account  + 1, 
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = cur_user_account_id;


/* Insert app_audit_log. */
SET s_desc = CONCAT("old_acc_name = ", cur_account_name, "; new_acc_name = ",
    in_name);

INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_user_id,
    cur_user_account_id,
    AUDIT_ACTION_UPDATE,
    s_desc,
    CURRENT_DATE
);


END process_user;


SELECT
    a.name,
    a.flag,
    a.status_id,
    b.name,
    a.date_trial_start,
    a.date_trial_end
INTO
    cur_account_name,
    cur_account_flag,
    cur_account_status_id,
    cur_account_status_name,
    cur_account_date_trial_start,
    cur_account_date_trial_end
FROM account a
LEFT OUTER JOIN account_status b ON a.status_id = b.id
WHERE a.id = cur_user_account_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS acc_id,
    cur_account_name                    AS acc_name,
    cur_account_flag                    AS acc_flag,
    cur_account_status_id               AS acc_status_id,
    cur_account_status_name             AS acc_status_name,
    cur_account_date_trial_start        AS date_trial_start,
    cur_account_date_trial_end          AS date_trial_end;




END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_update_settings $$
CREATE PROCEDURE account_update_settings(
    in_user_id                  INT,
    
    in_day_1_on_dob             INT,
    in_day_1_on_insem           INT,
    
    in_days_wean                INT,
    
    in_days_harvest_from_birth  INT,
    in_days_harvest_from_wean   INT,
    
    in_weight_unit              VARCHAR(4)
)

BEGIN

/** 
 * Will update account
 * @author Jack Wong
 * @since September 13, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;


DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* account.flag_setting bits
FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH
0 = Date of birth is counted as DAY 0
1 = Date of birth is counted as DAY 1; default

FLAG_BIT_DAY_1_ON_DATE_OF_INSEM
0 = Date of insemination is counted as DAY 0; default
1 = Date of insemination is counted as DAY 1;


*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_flag_settings               INT             DEFAULT 0;

DECLARE cur_account_days_wean                   INT             DEFAULT 0;
DECLARE cur_account_days_harvest_from_birth     INT             DEFAULT NULL;
DECLARE cur_account_days_harvest_from_wean      INT             DEFAULT NULL;
    
DECLARE cur_account_weight_unit                 VARCHAR(4)      DEFAULT NULL;
DECLARE cur_account_currency                    VARCHAR(4)      DEFAULT NULL;
    
    
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT NULL;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT NULL;
DECLARE cur_account_settings_update             DATETIME        DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";

CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, 
    
    BUSINESS_OBJ_ID_ACCOUNT,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);




process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account
WHERE   id = cur_user_account_id;

IF in_day_1_on_dob > 0 THEN  
    SET cur_account_flag_settings = cur_account_flag_settings | FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH;
ELSE
    SET cur_account_flag_settings = cur_account_flag_settings & ~FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH;
END IF;

IF in_day_1_on_insem > 0 THEN 
    SET cur_account_flag_settings = cur_account_flag_settings | FLAG_BIT_DAY_1_ON_DATE_OF_INSEM;
ELSE
    SET cur_account_flag_settings = cur_account_flag_settings & ~FLAG_BIT_DAY_1_ON_DATE_OF_INSEM;
END IF;



UPDATE account SET
    flag_settings                   = cur_account_flag_settings,
    num_days_wean                   = in_days_wean,
    num_days_harvest_from_birth     = in_days_harvest_from_birth,
    num_days_harvest_from_wean      = in_days_harvest_from_wean,
        
    weight_unit                     = in_weight_unit,
    
    last_update_settings_user_id    = in_user_id,
    dt_last_update_settings         = CURRENT_TIMESTAMP,
    
    data_ver_num_account            = data_ver_num_account + 1
WHERE id = cur_user_account_id;



END process_user;

SELECT 
    flag_settings,
    num_days_wean,
    num_days_harvest_from_birth,
    num_days_harvest_from_wean,
    
    weight_unit,
    currency
    
INTO 
    cur_account_flag_settings,
    cur_account_days_wean,
    cur_account_days_harvest_from_birth,
    cur_account_days_harvest_from_wean,
    
    cur_account_weight_unit,
    cur_account_currency

FROM account 

WHERE id = cur_user_account_id;
    

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_flag_settings           AS account_flag_settings,
    cur_account_days_wean               AS days_wean,
    cur_account_days_harvest_from_birth AS days_harvest_from_birth,
    cur_account_days_harvest_from_wean  AS days_harvest_from_wean,
    
    cur_account_weight_unit             AS weight_unit,
    cur_account_currency                AS currency;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_lactating_ops_create $$
CREATE PROCEDURE account_lactating_ops_create(
    in_account_id               INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 19, 2025
 *
 */


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC      INT             DEFAULT 2;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;



/* Default account lactating piglets operation; num_days since birth*/
DECLARE LACTATING_OPS_NUM_DAYS_CUT_TEETH        INT             DEFAULT 1;
DECLARE LACTATING_OPS_NUM_DAYS_CUT_TAIL         INT             DEFAULT 3;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_IRON_1    INT             DEFAULT 3;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_IRON_2    INT             DEFAULT 13;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_VITA_1    INT             DEFAULT 14;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_VITA_2    INT             DEFAULT 21;
DECLARE LACTATING_OPS_NUM_DAYS_CASTRATION       INT             DEFAULT 22;
DECLARE LACTATING_OPS_NUM_DAYS_DEWORM           INT             DEFAULT 25;


/* Default account lactating sow operation; num_days since birth*/
DECLARE LACTATING_SOW_OPS_NUM_DAYS_DEWORM       INT             DEFAULT 30;




/* Create default gestating_operation for the account.*/
INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    
    name,
    short_name,
    description
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_CUT_TEETH,
    
    "Cut Teeth",
    "Cut Teeth",
    "Cut Teeth"
);


INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    
    name,
    short_name,
    description
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_CUT_TAIL,
    
    "Cut Tail",
    "Cut Tail",
    "Cut Tail"
);



INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_INJECT_IRON_1,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,

    "Inject Iron_1",
    "InjIron1"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_INJECT_IRON_2,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Inject Iron_2",
    "InjIron2"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    flag,
    
    num_days_since,
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_INJECT_VITA_1,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Inject Vitamins_1",
    "InjVita1"
);


INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_INJECT_VITA_2,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Inject Vitamins_2",
    "InjVita2"
);


INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_CASTRATION,
    
    "Castration",
    "Castration"
);


INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_DEWORM,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Deworm",
    "Deworm"
);

UPDATE account SET 
    ver_num_lactating_piglets_ops = 1
WHERE id = in_account_id;



INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING_SOW,
    1,
    LACTATING_SOW_OPS_NUM_DAYS_DEWORM,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Deworm",
    "Deworm"
);

UPDATE account SET 
    ver_num_lactating_sow_ops = 1
WHERE id = in_account_id;




END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_gestating_ops_create $$
CREATE PROCEDURE account_gestating_ops_create(
    in_account_id               INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 19, 2025
 *
 */

/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC      INT             DEFAULT 2;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* Default account gestating operation; num_days since insemination*/
DECLARE GESTATING_OPS_NUM_DAYS_CHECK_REHEAT     INT             DEFAULT 21;
DECLARE GESTATING_OPS_NUM_DAYS_INJECT_IRON      INT             DEFAULT 80;
DECLARE GESTATING_OPS_NUM_DAYS_DEWORM           INT             DEFAULT 100;





/* Create default gestating_operation for the account.*/
INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    1,
    GESTATING_OPS_NUM_DAYS_CHECK_REHEAT,
    "Check Reheat",
    "Check Reheat"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    1,
    GESTATING_OPS_NUM_DAYS_INJECT_IRON,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Inject Iron",
    "Inject Iron"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    1,
    GESTATING_OPS_NUM_DAYS_DEWORM,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Deworm",
    "Deworm"
);

UPDATE account SET 
    ver_num_gestating_ops = 1
WHERE id = in_account_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_register $$
CREATE PROCEDURE account_register(
    in_user_id              INT,
    
    in_country_id           INT,
    in_name                 VARCHAR(100)
)  

BEGIN

/** 
 * Will add account entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 8, 2025
 *
 */

DECLARE LOV_ID_ACCOUNT_NUMDAYS_FREE_TRIAL       INT             DEFAULT 1;


DECLARE RES_NUM_SUCCESS                             INT         DEFAULT 0;

DECLARE RES_NUM_ACCOUNT_ALREADY_REGISTERED_FOR_USER INT         DEFAULT 21;
DECLARE RES_NUM_DUPLICATE_ENTRY                     INT         DEFAULT 22;



DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


/* account.flag bits
bit 0: FLAG_BIT_ACCOUNT_ENABLE
bit 1: FLAG_BIT_FREE_TRIAL_FINISHED
bit 2:
bit 3:  

bit 4:  FLAG_BIT_ACCOUNT_IS_BILL_EXEMPTED
0 = not exempted has to pay bill
1 = exempted



bit 16: COMPANY_OWNED ACCOUNT

*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;

DECLARE ACCOUNT_STATUS_ID_ON_TRIAL              INT             DEFAULT 1;
DECLARE ACCOUNT_STATUS_ID_TRIAL_EXPIRED         INT             DEFAULT 2;
DECLARE ACCOUNT_STATUS_ID_UNPAID_BILL           INT             DEFAULT 3;







/* account.flag_setting bits
bit 0: FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH
0 = Date of birth is counted as DAY 0
1 = Date of birth is counted as DAY 1; default

bit 1: FLAG_BIT_DAY_1_ON_DATE_OF_INSEM
0 = Date of insemination is counted as DAY 0; default
1 = Date of insemination is counted as DAY 1;


*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;




DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";



DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_account_id                     INT             DEFAULT 0;

DECLARE cur_num_days_trial                      INT             DEFAULT 0;


DECLARE cur_account_id                          INT             DEFAULT 0;
DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;
DECLARE cur_account_status_name                 VARCHAR(50);
DECLARE cur_account_name                        VARCHAR(100); 
DECLARE cur_account_date_trial_start            DATE;
DECLARE cur_account_date_trial_end              DATE;

DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    0, /* user has no account yet*/
    0,
    
    BUSINESS_OBJ_ID_ACCOUNT,
    FLAG_BIT_OPERATION_ADD,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN


IF cur_user_account_id > 0 THEN
    SET res_num     = RES_NUM_ACCOUNT_ALREADY_REGISTERED_FOR_USER;
    SET res_code    = "RES_NUM_ACCOUNT_ALREADY_REGISTERED_FOR_USER";
    
    LEAVE process_user;
END IF;


SELECT  val_int 
INTO    cur_num_days_trial
FROM    a01_list_of_values
WHERE   id = LOV_ID_ACCOUNT_NUMDAYS_FREE_TRIAL;




INSERT INTO account(
    name,
    country_id,
    flag,
    
    flag_settings,
    
    status_id,
    date_trial_start,
    date_trial_end,
    
    added_by_user_id
    
) VALUES (
    in_name,
    in_country_id,
    1,
    
    FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH,
    
    ACCOUNT_STATUS_ID_ON_TRIAL,
    CURRENT_DATE,
    DATE_ADD(CURRENT_DATE, INTERVAL cur_num_days_trial DAY),
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_id;


CALL account_user_groups_create(cur_account_id);


SELECT  id 
INTO    cur_user_group_id
FROM    user_group
WHERE   account_id = cur_account_id AND group_num = 1;


/* The user that registers the account is an account admin. */
UPDATE user SET
    account_id      = cur_account_id,
    user_group_id   = cur_user_group_id,
    flag            = flag | FLAG_BIT_USER_IS_ACCOUNT_ADMIN
WHERE id = in_user_id;


CALL account_gestating_ops_create(cur_account_id);

CALL account_lactating_ops_create(cur_account_id);

CALL account_gilt_ops_create(cur_account_id);


/* Insert app_audit_log. */
SET s_desc = CONCAT("Account registered; acc_name = ", in_name);
INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_user_id,
    cur_account_id,
    AUDIT_ACTION_ADD,
    s_desc,
    CURRENT_DATE
); 


SET s_desc = "User set to ACCOUNT ADMIN";
INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_user_id,
    cur_account_id,
    AUDIT_ACTION_ADD,
    s_desc,
    CURRENT_DATE
); 


END process_user;


SELECT
    a.name,
    a.flag,
    a.status_id,
    b.name,
    a.date_trial_start,
    a.date_trial_end
INTO
    cur_account_name,
    cur_account_flag,
    cur_account_status_id,
    cur_account_status_name,
    cur_account_date_trial_start,
    cur_account_date_trial_end
FROM account a
LEFT OUTER JOIN account_status b ON a.status_id = b.id
WHERE a.id = cur_account_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_id                      AS acc_id,
    cur_account_name                    AS acc_name,
    cur_account_flag                    AS acc_flag,
    cur_account_status_id               AS acc_status_id,
    cur_account_status_name             AS acc_status_name,
    cur_account_date_trial_start        AS date_trial_start,
    cur_account_date_trial_end          AS date_trial_end;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_gilt_ops_create $$
CREATE PROCEDURE account_gilt_ops_create(
    in_account_id               INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 12, 2025
 *
 */

/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC      INT             DEFAULT 2;

DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;



/* Default account lactating piglets operation; num_days since birth*/
DECLARE GILT_OPS_NUM_DAYS_HCV                   INT             DEFAULT 161;
DECLARE GILT_OPS_NUM_DAYS_PLE                   INT             DEFAULT 182;
DECLARE GILT_OPS_NUM_DAYS_PCV                   INT             DEFAULT 189;





/* Create default gestating_operation for the account.*/
INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name,
    description
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GILT_OPS,
    1,
    GILT_OPS_NUM_DAYS_HCV,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "HCV Vaccine",
    "HCV Vac",
    "Inject HCV vaccine"
);


INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name,
    description
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GILT_OPS,
    1,
    GILT_OPS_NUM_DAYS_PLE,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "PLE Vaccine",
    "PLE Vac",
    "Inject PLE vaccine"
);



INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name,
    description
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GILT_OPS,
    1,
    GILT_OPS_NUM_DAYS_PCV,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "PCV Vaccine",
    "PCV Vac",
    "Inject PCV vaccine"
);


UPDATE account SET 
    ver_num_gilt_ops = 1
WHERE id = in_account_id;




END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_user_groups_create $$
CREATE PROCEDURE account_user_groups_create(
    in_account_id               INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 19, 2025
 *
 */


DECLARE ACCOUNT_USER_GROUP_ADMIN                INT             DEFAULT 1;
DECLARE ACCOUNT_USER_GROUP_MANAGEMENT           INT             DEFAULT 2;
DECLARE ACCOUNT_USER_GROUP_OPERATIONS           INT             DEFAULT 3;
DECLARE ACCOUNT_USER_GROUP_FARM_STAFF           INT             DEFAULT 4;


/* These are the tables that are editable by users and need access restrictions; */

/* This is read from a02_business_object table. 

Business object with ids between 1 to 32 will have the access flags to be saved 
in user_group.flag_business_obj_1ect_1;

Business object with ids between 33 to 64 will have the access flags to be saved 
in user_group.flag_business_obj_1ect_1;



*/
DECLARE BUSINESS_OBJ_ID_USER                    INT             DEFAULT 1;
DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_REQUEST         INT             DEFAULT 3;
DECLARE BUSINESS_OBJ_ID_USER_GROUP              INT             DEFAULT 4;

DECLARE BUSINESS_OBJ_ID_ACCOUNT_TRANSLATION     INT             DEFAULT 5;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_BILLING         INT             DEFAULT 6;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER       INT             DEFAULT 7;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 8;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;
DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF          INT             DEFAULT 10;

DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;



DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;
DECLARE BUSINESS_OBJ_ID_FEED_BALANCE            INT             DEFAULT 18;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;
DECLARE BUSINESS_OBJ_ID_SEMEN_SOURCE            INT             DEFAULT 20;
DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_AI             INT             DEFAULT 22;



DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_ADD        INT             DEFAULT 27;

DECLARE BUSINESS_OBJ_ID_PIG_DEAD_TYPE           INT             DEFAULT 28;
DECLARE BUSINESS_OBJ_ID_RESERVED_1              INT             DEFAULT 29;

DECLARE BUSINESS_OBJ_ID_SOW_BOAR_BALANCE        INT             DEFAULT 30;
DECLARE BUSINESS_OBJ_ID_RESERVED_2              INT             DEFAULT 31;
DECLARE BUSINESS_OBJ_ID_RESERVED_3              INT             DEFAULT 32;


DECLARE BUSINESS_OBJ_ID_PIG_PEN                 INT             DEFAULT 33;
DECLARE BUSINESS_OBJ_ID_PRODUCTION_GROUP        INT             DEFAULT 34;




/* Admin users can access all business objects, 2^32 -1 or 0xFFFF FFFF*/
DECLARE FLAG_BUSINESS_OBJ_ADMIN                 BIGINT          DEFAULT 4294967295;
DECLARE FLAG_BUSINESS_OBJ_MANAGEMENT_1          BIGINT          DEFAULT 0;
DECLARE FLAG_BUSINESS_OBJ_OPERATIONS_1          BIGINT          DEFAULT 0;

DECLARE FLAG_BUSINESS_OBJ_MANAGEMENT_2          BIGINT          DEFAULT 0;
DECLARE FLAG_BUSINESS_OBJ_OPERATIONS_2          BIGINT          DEFAULT 0;




DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE OPERATION_ADD_UPDATE_DELETE             INT             DEFAULT 7;
DECLARE OPERATION_ADD_UPDATE_ONLY               INT             DEFAULT 3;




SELECT SUM(a.flag_val)
INTO FLAG_BUSINESS_OBJ_MANAGEMENT_1
FROM (
    SELECT  POWER(2, bit_num) AS flag_val
    FROM    a02_business_object
    WHERE   id IN ( BUSINESS_OBJ_ID_USER,
                    BUSINESS_OBJ_ID_ACCOUNT_REQUEST,
                    
                    BUSINESS_OBJ_ID_ACCOUNT_TRANSLATION,
                    BUSINESS_OBJ_ID_ACCOUNT_BILLING,
                    BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER,
                    BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS,
                    
                                        
                    BUSINESS_OBJ_ID_PIG_FARM,
                    BUSINESS_OBJ_ID_PIG_FARM_STAFF,
                    BUSINESS_OBJ_ID_PIG_RACE_LINE, 
                    

                    BUSINESS_OBJ_ID_FEED_BUY,
                    BUSINESS_OBJ_ID_FEED_BALANCE,
                    
                    
                    BUSINESS_OBJ_ID_SOW_BOAR, 
                    BUSINESS_OBJ_ID_SEMEN_SOURCE,
                    BUSINESS_OBJ_ID_PIG_PRODUCTION,
                    BUSINESS_OBJ_ID_PIG_PROD_AI,
                    
                    
                    BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS,
                    BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD,
                    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
                    BUSINESS_OBJ_ID_PIG_PROD_HARVEST,
                    BUSINESS_OBJ_ID_PIG_PROD_PIG_ADD,
                    
                    BUSINESS_OBJ_ID_SOW_BOAR_BALANCE
                    
                )
    ) a;
    


SELECT SUM(a.flag_val)
INTO FLAG_BUSINESS_OBJ_MANAGEMENT_2
FROM (
    SELECT  POWER(2, bit_num) AS flag_val
    FROM    a02_business_object
    WHERE   id IN ( BUSINESS_OBJ_ID_PIG_PEN,
                    BUSINESS_OBJ_ID_PRODUCTION_GROUP
                    
                )
    ) a;


IF FLAG_BUSINESS_OBJ_MANAGEMENT_2 IS NULL THEN 
    SET FLAG_BUSINESS_OBJ_MANAGEMENT_2 = 0;
END IF;


    
    
SELECT SUM(a.flag_val)
INTO FLAG_BUSINESS_OBJ_OPERATIONS_1
FROM (
    SELECT  POWER(2, bit_num) AS flag_val
    FROM    a02_business_object
    WHERE   id IN ( BUSINESS_OBJ_ID_SOW_BOAR,
                    BUSINESS_OBJ_ID_PIG_PRODUCTION,
                    BUSINESS_OBJ_ID_PIG_PROD_AI,
                    
                    BUSINESS_OBJ_ID_FEED_BALANCE, 

                    BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS,

                    BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD,
                    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
                    BUSINESS_OBJ_ID_PIG_PROD_HARVEST,
                    
                    BUSINESS_OBJ_ID_SOW_BOAR_BALANCE
                )
    ) a;


SELECT SUM(a.flag_val)
INTO FLAG_BUSINESS_OBJ_OPERATIONS_2
FROM (
    SELECT  POWER(2, bit_num) AS flag_val
    FROM    a02_business_object
    WHERE   id IN ( BUSINESS_OBJ_ID_PRODUCTION_GROUP
                )
    ) a;

IF FLAG_BUSINESS_OBJ_OPERATIONS_2 IS NULL THEN 
    SET FLAG_BUSINESS_OBJ_OPERATIONS_2 = 0;
END IF;




/* Create account default user_groups. Each account will have a fix 
number of user groups*/
INSERT INTO user_group(
    account_id,
    group_num,
    flag_business_obj_1,
    flag_business_obj_2,
    name,
    
    flag_priv_user,
    flag_priv_account,
    flag_priv_acc_request,
    flag_priv_user_group,
    
    flag_priv_acc_translation,
    flag_priv_acc_billing,
    flag_priv_acc_pig_buyer,
    flag_priv_acc_pig_ops,
    
    flag_priv_pig_farm,
    flag_priv_pig_farm_staff,
    flag_priv_pig_race,
    flag_priv_pig_race_line,
    
    flag_priv_semen_supplier,
    flag_priv_feed_supplier,
    flag_priv_feed_brand,
    flag_priv_feed_type,
    flag_priv_feed_buy,
    flag_priv_feed_balance,
    
    flag_priv_sow_boar,
    flag_priv_semen_source,
    flag_priv_pig_production,
    flag_priv_pig_prod_ai,
    
    flag_priv_pig_prod_pig_ops,
    flag_priv_pig_prod_pig_dead,
    flag_priv_pig_prod_notes,
    flag_priv_pig_prod_harvest,
    flag_priv_pig_prod_pig_add,
    
    flag_priv_sow_boar_balance,
    
    flag_priv_pig_pen
    

) VALUES (
    in_account_id,
    ACCOUNT_USER_GROUP_ADMIN,
    FLAG_BUSINESS_OBJ_ADMIN,
    FLAG_BUSINESS_OBJ_ADMIN,
    'Admin',
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    

    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE
);


INSERT INTO user_group(
    account_id,
    group_num,
    flag_business_obj_1,
    flag_business_obj_2,
    name,
    
    flag_priv_user,
    flag_priv_account,
    flag_priv_acc_request,
    flag_priv_user_group,
    
    flag_priv_acc_translation,
    flag_priv_acc_billing,
    flag_priv_acc_pig_buyer,
    flag_priv_acc_pig_ops,
    
    flag_priv_pig_farm,
    flag_priv_pig_farm_staff,
    flag_priv_pig_race,
    flag_priv_pig_race_line,
    
    flag_priv_semen_supplier,
    flag_priv_feed_supplier,
    flag_priv_feed_brand,
    flag_priv_feed_type,
    flag_priv_feed_buy,
    flag_priv_feed_balance,
    
    flag_priv_sow_boar,
    flag_priv_semen_source,
    flag_priv_pig_production,
    flag_priv_pig_prod_ai,
    

    flag_priv_pig_prod_pig_ops,
    flag_priv_pig_prod_pig_dead,
    flag_priv_pig_prod_notes,
    flag_priv_pig_prod_harvest,
    flag_priv_pig_prod_pig_add,
    
    flag_priv_sow_boar_balance,
    
    flag_priv_pig_pen
    
) VALUES (
    in_account_id,
    ACCOUNT_USER_GROUP_MANAGEMENT,
    FLAG_BUSINESS_OBJ_MANAGEMENT_1,
    FLAG_BUSINESS_OBJ_MANAGEMENT_2,
    'Management',
    
    OPERATION_ADD_UPDATE_ONLY,
    0,
    OPERATION_ADD_UPDATE_DELETE,
    0,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    

    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE
);


INSERT INTO user_group(
    account_id,
    group_num,
    flag_business_obj_1,
    flag_business_obj_2,
    name,
    
    
    flag_priv_sow_boar,
    flag_priv_pig_production,
    
    flag_priv_feed_balance,
    
    flag_priv_pig_prod_pig_ops,
    flag_priv_pig_prod_pig_dead,
    flag_priv_pig_prod_notes,
    flag_priv_pig_prod_harvest,
    
    flag_priv_sow_boar_balance
    
) VALUES (
    in_account_id,
    ACCOUNT_USER_GROUP_OPERATIONS,
    FLAG_BUSINESS_OBJ_OPERATIONS_1,
    FLAG_BUSINESS_OBJ_OPERATIONS_2,
    'Operations',
    
   
    OPERATION_ADD_UPDATE_ONLY,
    OPERATION_ADD_UPDATE_ONLY,
    
    OPERATION_ADD_UPDATE_ONLY,
    
    OPERATION_ADD_UPDATE_ONLY,
    OPERATION_ADD_UPDATE_ONLY,
    OPERATION_ADD_UPDATE_ONLY,
    OPERATION_ADD_UPDATE_ONLY,
    
    OPERATION_ADD_UPDATE_ONLY
);





END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_request_add_farms_to_user $$
CREATE PROCEDURE user_request_add_farms_to_user(
    in_account_id           INT,
    in_requesting_user_id   INT,
    in_approving_user_id    INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since March 7, 2026
 *
 */

DECLARE cur_pig_farm_id                         INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;



DECLARE l_last_row_fetched TINYINT;
DECLARE c_pig_farm CURSOR FOR
    SELECT  id
    FROM    pig_farm
    WHERE   account_id      = in_account_id 
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 




    
SET l_last_row_fetched=0;
OPEN c_pig_farm;   
    

loop_here: LOOP
    FETCH c_pig_farm INTO 
        cur_pig_farm_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    SET cur_count = 0;

    SELECT  COUNT(*)
    INTO    cur_count
    FROM    user_pig_farm
    WHERE   pig_farm_id = cur_pig_farm_id AND user_id = in_requesting_user_id;
    
    
    IF cur_count = 0 THEN 

        INSERT INTO user_pig_farm(
            pig_farm_id,
            user_id,
            added_by_user_id
        ) VALUES (
            cur_pig_farm_id,
            in_requesting_user_id,
            in_approving_user_id
        );
    END IF;

END LOOP loop_here;
 
CLOSE c_pig_farm;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_request_join_account $$
CREATE PROCEDURE user_request_join_account(
    in_access_code_id           INT,
    in_requesting_user_id       INT
)

BEGIN

/** 
 * @author Jack Wong
 * @since August 11, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_USER_IS_INACTIVE                INT             DEFAULT 1;
DECLARE RES_NUM_USER_NOT_EMAIL_VERIFIED         INT             DEFAULT 2;
DECLARE RES_NUM_USER_NOT_ACCOUNT_ADMIN          INT             DEFAULT 3;
DECLARE RES_NUM_USER_NO_ACCOUNT_SET             INT             DEFAULT 4;

DECLARE RES_NUM_USER_ALREADY_HAS_ACCOUNT        INT             DEFAULT 8;
DECLARE RES_NUM_INVALID_ACCESS_CODE             INT             DEFAULT 9; 

DECLARE RES_NUM_ACCOUNT_DISABLED                INT             DEFAULT 11;
DECLARE RES_NUM_ACCOUNT_STATUS_TRIAL_EXPIRED    INT             DEFAULT 12;
DECLARE RES_NUM_ACCOUNT_STATUS_UNPAID_BILL      INT             DEFAULT 13;



DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 50;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;


DECLARE ACCOUNT_STATUS_ID_ON_TRIAL              INT             DEFAULT 1;
DECLARE ACCOUNT_STATUS_ID_TRIAL_EXPIRED         INT             DEFAULT 2;
DECLARE ACCOUNT_STATUS_ID_UNPAID_BILL           INT             DEFAULT 3;


DECLARE USER_REQUEST_STATUS_ID_PENDING          INT             DEFAULT 1;
DECLARE USER_REQUEST_STATUS_ID_APPROVED         INT             DEFAULT 2;
DECLARE USER_REQUEST_STATUS_ID_REJECTED         INT             DEFAULT 3;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_email                          VARCHAR(100);

DECLARE cur_access_code_account_id              INT             DEFAULT 0;
DECLARE cur_access_code_user_group_id           INT             DEFAULT 0;
DECLARE cur_access_code_used_by_user_id         INT             DEFAULT 0;


DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;
DECLARE cur_account_default_farm_id             INT             DEFAULT 0;
 



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        flag,
        email
        
INTO    cur_user_account_id,
        cur_user_flag,
        cur_user_email
FROM    user 
WHERE   id = in_requesting_user_id;


process_user : BEGIN

/* Check user*/
IF cur_user_flag & FLAG_BIT_USER_IS_ACTIVE = 0 THEN 
    SET res_num     = RES_NUM_USER_IS_INACTIVE;
    SET res_code    = "RES_NUM_USER_IS_INACTIVE";

    LEAVE process_user;
END IF;



IF cur_user_account_id > 0 THEN 
    SET res_num     = RES_NUM_USER_ALREADY_HAS_ACCOUNT;
    SET res_code    = "RES_NUM_USER_ALREADY_HAS_ACCOUNT";

    LEAVE process_user;
END IF;



SELECT  account_id,
        user_group_id,
        used_by_user_id
        
INTO    cur_access_code_account_id,
        cur_access_code_user_group_id,
        cur_access_code_used_by_user_id

FROM    account_access_code

WHERE id = in_access_code_id;


IF cur_access_code_used_by_user_id > 0 THEN 
    SET res_num     = RES_NUM_INVALID_ACCESS_CODE;
    SET res_code    = "RES_NUM_INVALID_ACCESS_CODE";
    SET res_desc    = "Already Used";
    
    LEAVE process_user;
END IF;

    

/* Check account*/
SELECT 
    flag,
    status_id,
    default_farm_id
    name
INTO
    cur_account_flag,
    cur_account_status_id,
    cur_account_default_farm_id
    
FROM account
WHERE id = cur_access_code_account_id;


IF cur_account_flag & FLAG_BIT_ACCOUNT_ENABLE = 0 THEN 
    SET res_num     = RES_NUM_ACCOUNT_DISABLED;
    SET res_code    = "RES_NUM_ACCOUNT_DISABLED";
    
    IF cur_account_status_id = ACCOUNT_STATUS_ID_UNPAID_BILL THEN
        SET res_num     = RES_NUM_ACCOUNT_STATUS_UNPAID_BILL;
        SET res_code    = "RES_NUM_ACCOUNT_STATUS_UNPAID_BILL";
    
    END IF;
    
    LEAVE process_user;
END IF;




/* Update User*/
UPDATE user SET 
    account_id              = cur_access_code_account_id,
    user_group_id           = cur_access_code_user_group_id,
    account_access_code_id  = in_access_code_id
WHERE 
    id = in_requesting_user_id;

INSERT INTO user_pig_farm(
    pig_farm_id,
    user_id,
    added_by_user_id
) VALUES(
    cur_account_default_farm_id,
    in_requesting_user_id,
    in_requesting_user_id
);



/* Update account_access_code*/
UPDATE account_access_code SET
    used_by_user_id = in_requesting_user_id
WHERE id = in_access_code_id;



END process_user;


SELECT  account_id
INTO    cur_user_account_id
FROM    user
WHERE   id =  in_requesting_user_id;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS user_account_id,
    cur_user_email                      AS user_email;


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_request_join_account_approve $$
CREATE PROCEDURE user_request_join_account_approve(
    in_approving_user_id        INT,
    
    in_user_request_id          INT,
    in_user_group_num           INT,
    
    in_is_approved              INT,
    
    in_pig_farm_id              INT
    
)

BEGIN

/** 
 * Will approve user_request to join user to account; 
 * This is initiated by the account admin user.
 * @author Jack Wong
 * @since August 11, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;




DECLARE RES_NUM_USER_REQUEST_ALREADY_APPROVED   INT             DEFAULT 20;



DECLARE BUSINESS_OBJ_ID_USER                    INT             DEFAULT 1;




DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE USER_REQUEST_STATUS_ID_PENDING          INT             DEFAULT 1;
DECLARE USER_REQUEST_STATUS_ID_APPROVED         INT             DEFAULT 2;
DECLARE USER_REQUEST_STATUS_ID_REJECTED         INT             DEFAULT 3;





DECLARE cur_user_req_status_id                   INT             DEFAULT 0;
DECLARE cur_user_req_account_id                  INT             DEFAULT 0;
DECLARE cur_user_req_requesting_user_id          INT             DEFAULT 0;
DECLARE cur_user_req_dt_approved                 DATETIME        DEFAULT NULL;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;

DECLARE cur_approving_user_email                VARCHAR(100)    DEFAULT NULL;
DECLARE cur_approving_user_name_last            VARCHAR(50)     DEFAULT NULL;
DECLARE cur_approving_user_name_first           VARCHAR(50)     DEFAULT NULL;




DECLARE cur_requesting_user_email               VARCHAR(100)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        status_id,
        account_id,
        requesting_user_id
INTO    
        cur_user_req_status_id,
        cur_user_req_account_id,
        cur_user_req_requesting_user_id
        
FROM    user_request
WHERE   id = in_user_request_id;


CALL basic_user_check(
    in_approving_user_id, 
    1, 
    cur_user_req_account_id,
    
    BUSINESS_OBJ_ID_USER,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);



process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_user_req_status_id = USER_REQUEST_STATUS_ID_APPROVED THEN
    SET res_num     = RES_NUM_USER_REQUEST_ALREADY_APPROVED;
    SET res_code    = "RES_NUM_USER_REQUEST_ALREADY_APPROVED";

    LEAVE process_user;
END IF;

IF in_is_approved > 0 THEN
    SET cur_user_req_status_id = USER_REQUEST_STATUS_ID_APPROVED;
ELSE
    SET cur_user_req_status_id = USER_REQUEST_STATUS_ID_REJECTED;
END IF;
 
UPDATE user_request SET
    status_id           = cur_user_req_status_id,
    approved_by_user_id = in_approving_user_id,
    dt_approved         = CURRENT_TIMESTAMP
WHERE id = in_user_request_id;



IF in_is_approved > 0 THEN 
    SELECT  id
    INTO    cur_user_group_id
    FROM    user_group
    WHERE   account_id = cur_user_req_account_id AND 
            group_num = in_user_group_num;


    /* Update approved user. */
    UPDATE user SET
        account_id          = cur_user_req_account_id,
        user_group_id       = cur_user_group_id,
        user_req_join_acc_id= NULL
    WHERE id = cur_user_req_requesting_user_id;


    IF in_pig_farm_id > 0 THEN 
        SET cur_count = 0;

        SELECT  COUNT(*)
        INTO    cur_count
        FROM    user_pig_farm
        WHERE   pig_farm_id = in_pig_farm_id AND user_id = cur_user_req_requesting_user_id;
        
        
        IF cur_count = 0 THEN 

            INSERT INTO user_pig_farm(
                pig_farm_id,
                user_id,
                added_by_user_id
            ) VALUES (
                in_pig_farm_id,
                cur_user_req_requesting_user_id,
                in_approving_user_id
            );
        END IF;


        
    ELSE
        /* Add all account pig farms to cur_user_req_requesting_user_id */
        CALL user_request_add_farms_to_user(
            cur_user_req_account_id,
            cur_user_req_requesting_user_id,
            in_approving_user_id
        );
    END IF;
    

END IF;



SELECT  email 
INTO    cur_requesting_user_email
FROM user
WHERE   id = cur_user_req_requesting_user_id;


END process_user;


SELECT  
        a.status_id,

        c.email,
        c.name_last,
        c.name_first,
        a.dt_approved
INTO    
        cur_user_req_status_id,

        cur_approving_user_email,
        cur_approving_user_name_last,
        cur_approving_user_name_first,
        cur_user_req_dt_approved
        
FROM    user_request a 
LEFT OUTER JOIN user c ON a.approved_by_user_id = c.id
WHERE   a.id = in_user_request_id;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_user_request_id                  AS user_req_id,
    cur_user_req_status_id              AS user_req_status_id,
    
    cur_approving_user_email            AS approving_user_email, 
    cur_approving_user_name_last        AS approving_user_name_last,
    cur_approving_user_name_first       AS approving_user_name_first,
    cur_user_req_dt_approved            AS acc_req_dt_approved,
    
    cur_user_req_requesting_user_id     AS requesting_user_id,
    cur_requesting_user_email           AS requesting_user_email;


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_resend_verify_code $$
CREATE PROCEDURE user_resend_verify_code(
    in_unverified_user_id   INT, /* Only one of this is not NULL and > 0. */
    in_user_id              INT /* Only one of this is not NULL and > 0. */
    
)

BEGIN

/** 
 * Will create user_verify entry.
 * @author Jack Wong
 * @since March 17, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE NUM_MINUTES_CODE_EXPIRY                 INT             DEFAULT 5;





/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;



DECLARE cur_user_verify_id                      INT             DEFAULT 0;
DECLARE cur_user_email                          VARCHAR(50)     DEFAULT 0;


DECLARE cur_user_verify_code                    INT             DEFAULT 0;
DECLARE cur_user_verify_code_ts_expiry          BIGINT          DEFAULT 0;
DECLARE cur_user_verify_code_dt_expiry          DATETIME        DEFAULT NULL;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



IF in_unverified_user_id > 0 THEN 
    SELECT  email
     
    INTO    cur_user_email
    
    FROM    user_unverified 
      
    WHERE   id = in_unverified_user_id;

ELSE
    SELECT  email
     
    INTO    cur_user_email
    
    FROM    user
      
    WHERE   id = in_user_id;

END IF;


SET res_num      = 0;
SET res_code     = 'SUCCESS';
        



process_user : BEGIN


/* Create verification code to be sent to user email.*/
SET cur_user_verify_code = ROUND(100000 + RAND() * (999000 - 100000));
    
    
/* Add NUM_MINUTES_CODE_EXPIRY from NOW*/ 
INSERT INTO user_verify(
    email,
    auth_code,
    ts_expiry,
    dt_expiry
) VALUES (
    cur_user_email,
    cur_user_verify_code,
    UNIX_TIMESTAMP(DATE_ADD(NOW(), INTERVAL NUM_MINUTES_CODE_EXPIRY MINUTE)),  /* UNIX timestamp expiry */
    DATE_ADD(NOW(), INTERVAL NUM_MINUTES_CODE_EXPIRY MINUTE)                   /* Datetime expiry */
);
SELECT LAST_INSERT_ID() INTO cur_user_verify_id;
    
    
IF in_unverified_user_id > 0 THEN 
    UPDATE user_unverified SET 
        user_verify_id = cur_user_verify_id
    WHERE id = in_unverified_user_id;
    
ELSE
    UPDATE user SET 
        last_user_verify_id = cur_user_verify_id
    WHERE id = in_user_id;

END IF;


SELECT  ts_expiry,
        dt_expiry
        
INTO    cur_user_verify_code_ts_expiry,
        cur_user_verify_code_dt_expiry

FROM    user_verify
WHERE   id = cur_user_verify_id;


      
      
END process_user;


    

SELECT  
    res_num                         AS result_num,
    res_code                        AS result_code,
    res_desc                        AS result_desc,
    
    0                               AS user_id,
    0                               AS user_account_id,
    0                               AS user_flag,
    
    in_unverified_user_id           AS user_unverified_id,
    cur_user_verify_id              AS user_verify_code_id,                  
    cur_user_verify_code            AS user_verify_code,
    cur_user_verify_code_ts_expiry  AS code_ts_expiry,
    cur_user_verify_code_dt_expiry  AS code_dt_expiry,
    NUM_MINUTES_CODE_EXPIRY         AS expiry_minutes,
    
    cur_user_email                  AS user_email;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_is_verified $$
CREATE PROCEDURE user_is_verified(
    in_user_unverified_id   INT,
    
    in_viewport_width       INT,
    in_viewport_height      INT,
    in_ip_address           VARCHAR(24)
)  

BEGIN

/** 
 * Will create user login entry. 
 *
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since March 1, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


DECLARE cur_user_id                             INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_login_id                       INT             DEFAULT 0;


DECLARE cur_user_signup_country_id              INT             DEFAULT 0;
DECLARE cur_user_signup_country_code            VARCHAR(5)      DEFAULT NULL;
DECLARE cur_user_login_loc_trace_id             INT             DEFAULT 0;
DECLARE cur_user_email                          VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";





process_user : BEGIN

SELECT 
    a.signup_country_id,
    b.country_code,
    a.login_loc_trace_id,
    a.email 
INTO 
    cur_user_signup_country_id,
    cur_user_signup_country_code,
    cur_user_login_loc_trace_id,
    cur_user_email
FROM user_unverified a
LEFT OUTER JOIN app_country b ON a.signup_country_id = b.id
WHERE a.id = in_user_unverified_id;


IF cur_user_email IS NOT NULL THEN 
    SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE + FLAG_BIT_USER_EMAIL_VERIFIED;

    INSERT INTO user(
        email,
        
        flag,
        login_count
    )
    VALUES (
        cur_user_email,
        
        cur_user_flag,
        1
    );
    
    SELECT LAST_INSERT_ID() INTO cur_user_id;
    
    
    DELETE FROM user_unverified
    WHERE id = in_user_unverified_id;
    
    
    UPDATE app_country SET
        signup_count = signup_count + 1
    WHERE id = cur_country_id;
    
    
    /** Will also create a user_login entry and user should be automatically logged in*/
    INSERT INTO user_login(
        user_id,
        
        viewport_width,
        viewport_height,
        
        ip_address,
        country_code_login,
        login_loc_trace_id
    ) 
    VALUES (
        cur_user_id,
        
        in_viewport_width,
        in_viewport_height,
        
        in_ip_address,
        cur_user_signup_country_code,
        cur_user_login_loc_trace_id     
    );
    
END IF;



SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id        = cur_user_id;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_id                         AS user_id,
    0                                   AS user_account_id,
    cur_user_flag                       AS user_flag;



END process_user;



SELECT 
    
    cur_user_login_id                   AS user_login_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_update_login $$
CREATE PROCEDURE user_update_login(
    in_user_id              INT,
    
    
    in_login_country_code   VARCHAR(3),  /* This should be in upper case*/
    in_login_country_name   VARCHAR(50),
    in_login_city           VARCHAR(50), /* This should be in upper case*/
    in_login_region         VARCHAR(50), /* This should be in upper case*/
    
    
    in_viewport_width       INT,
    in_viewport_height      INT,
    in_ip_address           VARCHAR(24),
    
    in_is_mobile            INT,
    in_is_webview           INT,
    
    in_browser              VARCHAR(50),
    in_browser_version      VARCHAR(20),
    in_webview_platform     VARCHAR(30),
    in_os                   VARCHAR(50),
    in_os_version           VARCHAR(20),
    in_device               VARCHAR(50),
    in_device_type          VARCHAR(20)
    
)  

BEGIN


DECLARE cur_country_id                          INT             DEFAULT 0;
DECLARE cur_login_loc_trace_id                  INT             DEFAULT 0;

DECLARE cur_user_last_user_login_id             INT             DEFAULT 0;
DECLARE cur_user_last_user_login_ip_address     VARCHAR(24)     DEFAULT NULL;
DECLARE cur_user_last_user_login_country_code   VARCHAR(5)      DEFAULT NULL;

DECLARE cur_user_login_id                       INT             DEFAULT 0;
    
DECLARE cur_count                               INT             DEFAULT 0;                                  


SELECT  id
INTO    cur_country_id
FROM    app_country 
WHERE   country_code = in_login_country_code;


IF cur_country_id = 0 THEN 
    INSERT INTO app_country(
        country_code,
        name
    )
    VALUES(
        in_login_country_code,
        in_login_country_name
    );
    
    SELECT LAST_INSERT_ID() INTO cur_country_id;
END IF;



/** Save IP location trace*/
IF in_login_city IS NOT NULL AND in_login_region IS NOT NULL THEN 
    SELECT  id 
    INTO    cur_login_loc_trace_id
    FROM    user_login_ip_loc_trace
    WHERE   app_country_id      = cur_country_id AND
            ip_loc_trace_city   = in_login_city AND 
            ip_loc_trace_region = in_login_region
    LIMIT   1;

ELSE
    IF in_login_city IS NOT NULL THEN
        SELECT  id 
        INTO    cur_login_loc_trace_id
        FROM    user_login_ip_loc_trace
        WHERE   app_country_id      = cur_country_id AND
                ip_loc_trace_city   = in_login_city AND 
                ip_loc_trace_region = NULL
        LIMIT   1;
    END IF;
    
    IF in_login_region IS NOT NULL THEN
        SELECT  id 
        INTO    cur_login_loc_trace_id
        FROM    user_login_ip_loc_trace
        WHERE   app_country_id      = cur_country_id AND
                ip_loc_trace_region = in_login_region AND 
                ip_loc_trace_city   = NULL
        LIMIT   1;
    END IF;
        
END IF;



IF cur_login_loc_trace_id = 0 THEN 
    INSERT INTO user_login_ip_loc_trace (
        app_country_id,
        ip_loc_trace_city,
        ip_loc_trace_region
    ) VALUES(
        cur_country_id,
        in_login_city,
        in_login_region
    );
    
    SELECT LAST_INSERT_ID() INTO cur_login_loc_trace_id;
END IF;



SELECT  a.last_user_login_id,
        b.ip_address,
        b.country_code_login
        
INTO    cur_user_last_user_login_id,
        cur_user_last_user_login_ip_address,
        cur_user_last_user_login_country_code

FROM    user a
LEFT OUTER JOIN user_login b ON a.last_user_login_id = b.id
WHERE   a.id = in_user_id;


/* Solution for already deleted entries*/
SELECT  COUNT(*)
INTO    cur_count
FROM    user_login
WHERE   id = cur_user_last_user_login_id;

IF cur_count = 1 THEN 
    /** Entry still existing*/
    IF in_ip_address IS NOT  NULL THEN 
        UPDATE user_login SET
          
            country_code_login      = in_login_country_code,
            login_loc_trace_id      = cur_login_loc_trace_id,
                                     
            viewport_width          = in_viewport_width,       
            viewport_height         = in_viewport_height,      
            ip_address              = in_ip_address,           
                                     
            is_mobile               = in_is_mobile,            
            is_webview              = in_is_webview,           
                                     
            browser                 = in_browser,              
            browser_version         = in_browser_version,      
            webview_platform        = in_webview_platform,     
            os                      = in_os,                   
            os_version              = in_os_version,           
            device                  = in_device,               
            device_type             = in_device_type,
            
            date_login              = CURRENT_DATE          
        WHERE id = cur_user_last_user_login_id;
        
        SET cur_user_login_id = cur_user_last_user_login_id;
    END IF;
END IF;



IF in_ip_address IS NOT  NULL THEN 

    IF cur_count = 0 OR cur_user_last_user_login_ip_address != in_ip_address THEN 
        

        INSERT user_login(
            user_id,
        
            country_code_login,
            login_loc_trace_id, 
                               
            viewport_width,     
            viewport_height,    
            ip_address,         
                               
            is_mobile,          
            is_webview,         
                               
            browser,            
            browser_version,    
            webview_platform,   
            os,                 
            os_version,         
            device,             
            device_type,        
            
            date_login         
        ) VALUES (
            in_user_id,
        
            in_login_country_code,
            cur_login_loc_trace_id,     
            
            
            in_viewport_width,    
            in_viewport_height,   
            in_ip_address,        
            
            in_is_mobile,         
            in_is_webview,        
            
            in_browser,           
            in_browser_version,   
            in_webview_platform,  
            in_os,                
            in_os_version,        
            in_device,            
            in_device_type,
            
            CURRENT_DATE          
        );
        
        SELECT LAST_INSERT_ID() INTO cur_user_login_id;
        
        UPDATE user SET 
            last_user_login_id =  cur_user_login_id,
            login_count = login_count +1
        WHERE id = in_user_id;

    END IF;

END IF;

SELECT cur_user_login_id    AS  user_login_id; 


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_pig_farm_add $$
CREATE PROCEDURE user_pig_farm_add(
    in_user_id              INT,
    
    in_pig_farm_id          INT,
    in_user_id_to_add       INT
)  

BEGIN

/** 
 * Will add user_id into a pig_farm.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;




/* account_selection.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED   INT             DEFAULT 1;


DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_farm_account_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id,
    
    0,
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


SELECT  COUNT(*) 
INTO    cur_count 
FROM    user_pig_farm
WHERE   pig_farm_id = in_pig_farm_id AND user_id = in_user_id_to_add;

IF cur_count > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/*Insert into user_pig_farm*/
INSERT INTO user_pig_farm(
    pig_farm_id,
    user_id,
    added_by_user_id
) VALUES (
    in_pig_farm_id,
    in_user_id_to_add,
    in_user_id
);



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_verify_email $$
CREATE PROCEDURE user_verify_email(
    in_unverified_user_id   INT, /* Only one of this is not NULL and > 0. */
    in_user_id              INT, /* Only one of this is not NULL and > 0. */
    
    in_auth_code            INT,
    
    in_viewport_width       INT,
    in_viewport_height      INT,
    
    in_ip_address           VARCHAR(24)
    
)

BEGIN

/** 
 * Will verify  user email.
 * @author Jack Wong
 * @since March 4, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_CANNOT_FIND_VERIFICATION        INT             DEFAULT 1;
DECLARE RES_NUM_INVALID_CODE                    INT             DEFAULT 2;
DECLARE RES_NUM_CODE_EXPIRED                    INT             DEFAULT 3;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;




DECLARE cur_unix_timestamp                      BIGINT          DEFAULT 0;


DECLARE cur_user_verify_id                      INT             DEFAULT 0;
DECLARE cur_user_signup_country_id              INT             DEFAULT 0;
DECLARE cur_user_login_loc_trace_id             INT             DEFAULT 0;
        
DECLARE cur_user_email                          VARCHAR(50)     DEFAULT 0;
DECLARE cur_user_verify_code                    INT             DEFAULT 0;
DECLARE cur_user_verify_ts_expiry               BIGINT          DEFAULT 0;


DECLARE cur_user_id                             INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET cur_unix_timestamp      = UNIX_TIMESTAMP();


IF in_unverified_user_id > 0  THEN 
    SELECT  a.user_verify_id,
            a.signup_country_id,
            a.login_loc_trace_id,
            
            b.email,
            b.auth_code,
            b.ts_expiry
     
    INTO    
            cur_user_verify_id,
            cur_user_signup_country_id,
            cur_user_login_loc_trace_id,
            
            cur_user_email,
            cur_user_verify_code,
            cur_user_verify_ts_expiry
    FROM    user_unverified a
    LEFT OUTER JOIN  user_verify b ON a.user_verify_id = b.id   
    WHERE   a.id = in_unverified_user_id;


ELSE
    SELECT  a.last_user_verify_id,
            
            b.auth_code,
            b.ts_expiry
     
    INTO    
            cur_user_verify_id,
            
            cur_user_verify_code,
            cur_user_verify_ts_expiry
    FROM    user a
    LEFT OUTER JOIN  user_verify b ON a.last_user_verify_id = b.id   
    WHERE   a.id = in_user_id;

END IF;


SET res_num      = 0;
SET res_code     = 'SUCCESS';
        



process_user : BEGIN

IF cur_user_verify_id = 0 THEN 
    SET res_num     = RES_NUM_CANNOT_FIND_VERIFICATION;
    SET res_code    = "RES_NUM_CANNOT_FIND_VERIFICATION";
    
    LEAVE process_user;
END IF;

            
IF cur_user_verify_code = in_auth_code THEN 
    IF cur_unix_timestamp > cur_user_verify_ts_expiry THEN 
        SET res_num      = RES_NUM_CODE_EXPIRED;
        SET res_code     = 'RES_NUM_CODE_EXPIRED';
    ELSE
        
        /* Update code verification*/
        UPDATE user_verify SET
            dt_verified         = CURRENT_TIMESTAMP
        WHERE id = cur_user_verify_id;
        
        
        IF in_unverified_user_id > 0 THEN 
            /* Covert user from unverified user to verified user.*/
            SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE + FLAG_BIT_USER_EMAIL_VERIFIED;
        

            INSERT INTO user(
                email,
                
                flag,
                login_count,
                
                signup_country_id
            ) VALUES (
                cur_user_email,
                
                cur_user_flag,
                1,
                
                cur_user_signup_country_id
            );

            SELECT LAST_INSERT_ID() INTO cur_user_id;
            
            
            UPDATE app_country SET
                signup_count = signup_count + 1
            WHERE id = cur_user_signup_country_id;



            /** Will also create a user_login entry and user should be automatically logged in*/
            INSERT INTO user_login(
                user_id,
                
                viewport_width,
                viewport_height,
                
                ip_address,
                country_code_login,
                login_loc_trace_id
            ) 
            VALUES (
                cur_user_id,
                
                in_viewport_width,
                in_viewport_height,
                
                in_ip_address,
                cur_user_signup_country_id,
                cur_user_login_loc_trace_id     
            );


            /* Delete unverified user*/
            DELETE FROM user_unverified 
            WHERE id = in_unverified_user_id;
        
        ELSE
            SET cur_user_id = in_user_id;
        
        END IF;
        
        
    END IF;
ELSE
    SET res_num      = RES_NUM_INVALID_CODE;
    SET res_code     = 'RES_NUM_INVALID_CODE';
END IF;



END process_user;


SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id = cur_user_id;
    

SELECT  
    res_num                     AS result_num,
    res_code                    AS result_code,
    res_desc                    AS result_desc,
    
    cur_user_id                 AS user_id,
    cur_user_flag               AS user_flag;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_register_or_login $$
CREATE PROCEDURE user_register_or_login(
    in_login_social_media_id INT,
    in_social_media_user_id VARCHAR(120),/* This should be NULL if in_login_social_media_id is 0 or NULL*/

    in_acc_access_code_id   INT,
    in_acc_access_code      VARCHAR(10),


    in_name                 VARCHAR(80),
    in_name_last            VARCHAR(50),
    in_name_first           VARCHAR(50),
    
    in_email                VARCHAR(50),
    
    in_login_country_code   VARCHAR(3),  /* This should be in upper case*/
    in_login_country_name   VARCHAR(50),
    in_login_city           VARCHAR(50), /* This should be in upper case*/
    in_login_region         VARCHAR(50), /* This should be in upper case*/
    
    
    in_viewport_width       INT,
    in_viewport_height      INT,
    in_ip_address           VARCHAR(24),
    
    in_is_mobile            INT,
    in_is_webview           INT,
    
    in_browser              VARCHAR(50),
    in_browser_version      VARCHAR(20),
    in_webview_platform     VARCHAR(30),
    in_os                   VARCHAR(50),
    in_os_version           VARCHAR(20),
    in_device               VARCHAR(50),
    in_device_type          VARCHAR(20)
            
)  

BEGIN

/**
2026-03-18: Notes on login without email or social media.

1.) The previous flow of users who wish to join a pig farm account is
- create user (via email or social media).
- then request an account access; these users need to input the account code of the farm account.
- then the account owner codes access to the user via user_request table.
- this is the default flow and is working.


User creation via pre approved tokens.
======================================

As of this writing the social media login proves to be challenging as it requires 
business papers and will take time to review the process.

2.) So another solution is explored. Only the account owner (which is likely 
the farm owner or manager) needs an email to register. 


3.) The owner can create pre approved tokens who wants  to access the farm data
and has a pre assigned role.

The user who needs to register this method must provide

1.) user first name - filled up by user
2.) user last name - filled up by user
3.) token_id - this is given by the farm account owner to user. This is saved 
in account_access_code table; 

There is still some deliberation if this is a one-time access and cannot be 
recycled. But as of this writing this is assumed resusable until revoked by farm  
manager.


This access can elevate a user to a Manager or Admin role as well; in this case
there should be a mechanism to force the user to have an email for recovery
purposes.

*/


/** 
 * Will create user entry. This is usually used when a user registers from
 * a mobile app or web application. All parameter input cannot be null or empty.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 8, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_INVALID_ACCESS_CODE             INT             DEFAULT 1;
DECLARE RES_NUM_INVALID_USER_NAME               INT             DEFAULT 2;          

DECLARE NUM_MINUTES_CODE_EXPIRY                 INT             DEFAULT 5;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT NULL;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT NULL;


DECLARE cur_access_code_account_id              INT             DEFAULT 0;
DECLARE cur_access_code_user_group_id           INT             DEFAULT 0;
DECLARE cur_access_code_used_by_user_id         INT             DEFAULT 0;

DECLARE cur_account_default_farm_id             INT             DEFAULT 0;


DECLARE cur_user_unverified_id                  INT             DEFAULT 0;
DECLARE cur_user_verify_id                      INT             DEFAULT 0; 

DECLARE cur_user_verify_code                    INT             DEFAULT NULL;
DECLARE cur_user_verify_code_ts_expiry          BIGINT          DEFAULT 0;
DECLARE cur_user_verify_code_dt_expiry          DATETIME        DEFAULT NULL;
    

DECLARE cur_user_id                             INT             DEFAULT 0;
DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


DECLARE cur_user_login_id                       INT             DEFAULT 0;
DECLARE cur_user_using_social_media_id          INT             DEFAULT 0;


/* Resolves user from either email or social ID */
DECLARE use_this_user_id                        INT             DEFAULT 0;


DECLARE cur_country_id                          INT             DEFAULT 0;
DECLARE cur_login_loc_trace_id                  INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


/** Save country if not yet saved;*/
IF in_login_country_code IS NOT NULL THEN

    SELECT  id
    INTO    cur_country_id
    FROM    app_country 
    WHERE   country_code = in_login_country_code;


    IF cur_country_id = 0 THEN 
        INSERT INTO app_country(
            country_code,
            name
        )
        VALUES(
            in_login_country_code,
            in_login_country_name
        );
        
        SELECT LAST_INSERT_ID() INTO cur_country_id;
    END IF;



    /** Save IP location trace*/
    IF in_login_city IS NOT NULL AND in_login_region IS NOT NULL THEN 
        SELECT  id 
        INTO    cur_login_loc_trace_id
        FROM    user_login_ip_loc_trace
        WHERE   app_country_id      = cur_country_id AND
                ip_loc_trace_city   = in_login_city AND 
                ip_loc_trace_region = in_login_region
        LIMIT   1;

    ELSE
        IF in_login_city IS NOT NULL THEN
            SELECT  id 
            INTO    cur_login_loc_trace_id
            FROM    user_login_ip_loc_trace
            WHERE   app_country_id      = cur_country_id AND
                    ip_loc_trace_city   = in_login_city AND 
                    ip_loc_trace_region = NULL
            LIMIT   1;
        END IF;
        
        IF in_login_region IS NOT NULL THEN
            SELECT  id 
            INTO    cur_login_loc_trace_id
            FROM    user_login_ip_loc_trace
            WHERE   app_country_id      = cur_country_id AND
                    ip_loc_trace_region = in_login_region AND 
                    ip_loc_trace_city   = NULL
            LIMIT   1;
        END IF;
            
    END IF;



    IF cur_login_loc_trace_id = 0 THEN 
        INSERT INTO user_login_ip_loc_trace (
            app_country_id,
            ip_loc_trace_city,
            ip_loc_trace_region
        ) VALUES(
            cur_country_id,
            in_login_city,
            in_login_region
        );
        
        SELECT LAST_INSERT_ID() INTO cur_login_loc_trace_id;
    END IF;

END IF;



/* Trust to only to God; everything else is unverified until proven otherwise.*/
/* Only verified emails are inserted into user table; not verified are assumed garbage.*/


IF in_email IS NOT NULL THEN 
    /* Check first if email is in the user_unverified*/
    SELECT  id
    INTO    cur_user_unverified_id
    FROM    user_unverified
    WHERE   email        = in_email
    LIMIT   1;


    /* Check email if already in user table.*/
    SELECT  id,
            account_id,
            flag

    INTO    cur_user_id,
            cur_user_account_id,
            cur_user_flag

    FROM    user
    WHERE   email        = in_email
    LIMIT   1;

END IF;



process_user : BEGIN

/* Check if user is login using access_code. */
IF in_acc_access_code_id IS NOT NULL THEN 
    SELECT  account_id,
            user_group_id,
            used_by_user_id
    
    INTO    cur_access_code_account_id,
            cur_access_code_user_group_id,
            cur_access_code_used_by_user_id
    
    FROM account_access_code
    WHERE id =  in_acc_access_code_id;
    
    
    /** TODO more checks*/
    
    IF cur_access_code_account_id = 0 THEN 
        SET res_num     = RES_NUM_INVALID_ACCESS_CODE;
        SET res_code    = "RES_NUM_INVALID_ACCESS_CODE";
    
        LEAVE process_user;
    END IF;
    
    
    IF cur_access_code_used_by_user_id > 0 THEN 
        SELECT  LOWER(name_last),
                LOWER(name_first)
                
        INTO    cur_user_name_last,
                cur_user_name_first
        
        FROM user
        WHERE id =  cur_access_code_used_by_user_id;
        
        
        /* Staff relogin*/
        IF  LOWER(in_name_last) = cur_user_name_last AND
            LOWER(in_name_first) = cur_user_name_first THEN 
            
            
            /** Will also create a user_login entry and user should be automatically logged in.
            
            There are some noise in this data as it contains
            
            - screen dimension,
            - ip_trace location
            - browser and device details
            
            if no screen dimension OR no country 
                it is just noise, dont save.
            
            */
            
            IF  in_login_country_code   IS NOT NULL  AND
                in_viewport_width       IS NOT NULL  AND 
                in_viewport_height      IS NOT NULL THEN  
                
            
                INSERT INTO user_login(
                    user_id,
                    
                    viewport_width,
                    viewport_height,
                    
                    ip_address,
                    country_code_login,
                    login_loc_trace_id,
                    
                    
                    is_mobile,       
                    is_webview,      
                    
                    browser,         
                    browser_version, 
                    webview_platform,
                    os,              
                    os_version,      
                    device,          
                    device_type
                ) 
                VALUES (
                    cur_access_code_used_by_user_id,
                    
                    in_viewport_width,
                    in_viewport_height,
                    
                    in_ip_address,
                    in_login_country_code,
                    cur_login_loc_trace_id,
                    
                    in_is_mobile,       
                    in_is_webview,      
                    
                    in_browser,         
                    in_browser_version, 
                    in_webview_platform,
                    in_os,              
                    in_os_version,      
                    in_device,          
                    in_device_type     
                );
                SELECT LAST_INSERT_ID() INTO cur_user_login_id; 
                
                UPDATE user SET 
                    last_user_login_id      = cur_user_login_id
                WHERE id = cur_access_code_used_by_user_id;
            
            END IF;


            SET cur_user_id =  cur_access_code_used_by_user_id;
            
            
            /* Update user login count*/
            UPDATE user SET 
                login_count = login_count + 1
            WHERE 
                id = cur_user_id;
            
            
            /* The user now has the same account_id as access_code.*/
            SET cur_user_account_id     = cur_access_code_account_id;
            
            
            LEAVE process_user;
        
        ELSE
            /* Staff is using an access code but mismatch name.
            This should return as invalid.
            */
            
            SET res_num     = RES_NUM_INVALID_USER_NAME;
            SET res_code    = "RES_NUM_INVALID_USER_NAME";
        
            LEAVE process_user;
                
            
        END IF;

    END IF;
    
    
    
    /** Staff first time login */
    
    /* Get default farm of the account*/
    SELECT  default_farm_id
    INTO    cur_account_default_farm_id
    FROM    account
    WHERE   id = cur_access_code_account_id;
    
    
    
    SELECT  id
    INTO    cur_access_code_user_group_id
    FROM    user_group
    WHERE   account_id = cur_access_code_account_id AND
            group_num = cur_access_code_user_group_id
    LIMIT   1;
    

    
    SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE;

    /* User will have an automatic account, from the acount_access_code.*/
    INSERT INTO user(
        name_last,
        name_first,
        
        account_id,
        account_access_code_id,
        
        user_group_id,
        
        flag,
        login_count,
        
        signup_country_id
        
    ) VALUES (
        in_name_last,
        in_name_first,
        
        cur_access_code_account_id,
        in_acc_access_code_id,
        
        cur_access_code_user_group_id,
        
        cur_user_flag,
        1,
        
        cur_country_id
    );

    SELECT LAST_INSERT_ID() INTO cur_user_id;
    
    
    UPDATE app_country SET
        signup_count = signup_count + 1
    WHERE id = cur_country_id;



    IF  in_login_country_code   IS NOT NULL  AND
        in_viewport_width       IS NOT NULL  AND 
        in_viewport_height      IS NOT NULL THEN  
    

        /** Will also create a user_login entry and user should be automatically logged in*/
        INSERT INTO user_login(
            user_id,
            
            viewport_width,
            viewport_height,
            
            ip_address,
            country_code_login,
            login_loc_trace_id,
                    
                    
            is_mobile,       
            is_webview,      
            
            browser,         
            browser_version, 
            webview_platform,
            os,              
            os_version,      
            device,          
            device_type
        ) 
        VALUES (
            cur_user_id,
            
            in_viewport_width,
            in_viewport_height,
            
            in_ip_address,
            in_login_country_code,
            cur_login_loc_trace_id,
                    
            in_is_mobile,       
            in_is_webview,      
            
            in_browser,         
            in_browser_version, 
            in_webview_platform,
            in_os,              
            in_os_version,      
            in_device,          
            in_device_type     
        );
        SELECT LAST_INSERT_ID() INTO cur_user_login_id; 
        
        UPDATE user SET 
            last_user_login_id      = cur_user_login_id
        WHERE id = cur_user_id;
    
    
    END IF;
    
    
    /* Assign user to account default farm.*/
    INSERT INTO user_pig_farm(
        pig_farm_id,
        user_id,
        added_by_user_id
    ) VALUES(
        cur_account_default_farm_id,
        cur_user_id,
        cur_user_id
    );
    
    
    /* Update account_access_code*/
    UPDATE account_access_code SET 
        access_code     = in_acc_access_code,
        used_by_user_id = cur_user_id
    WHERE id = in_acc_access_code_id;
    
    
    
    /* The user now has the same account_id as the access_code.*/
    SET cur_user_account_id     = cur_access_code_account_id;
    
    
    LEAVE process_user;
END IF;





IF in_login_social_media_id IS NULL THEN 
    /* Create verification code to be sent to user email.*/
    SET cur_user_verify_code = ROUND(100000 + RAND() * (999000 - 100000));
        
        
    /* Add NUM_MINUTES_CODE_EXPIRY from NOW*/ 
    INSERT INTO user_verify(
        email,
        auth_code,
        ts_expiry,
        dt_expiry
    ) VALUES (
        in_email,
        cur_user_verify_code,
        UNIX_TIMESTAMP(DATE_ADD(NOW(), INTERVAL NUM_MINUTES_CODE_EXPIRY MINUTE)),  /* UNIX timestamp expiry */
        DATE_ADD(NOW(), INTERVAL NUM_MINUTES_CODE_EXPIRY MINUTE)                   /* Datetime expiry */
    );
    SELECT LAST_INSERT_ID() INTO cur_user_verify_id;
        


    /* Unverified user signup or login. */
    IF cur_user_unverified_id = 0 AND cur_user_id = 0 THEN 
        /* Insert to user_unverified. */
        INSERT INTO user_unverified(
            email,
            signup_country_id,
            login_count,
            login_loc_trace_id,
            
            date_signup
        ) VALUES (
            in_email,
            cur_country_id,
            1,
            cur_login_loc_trace_id,
            
            CURRENT_DATE
        );
        SELECT LAST_INSERT_ID() INTO cur_user_unverified_id;
        

        UPDATE user_unverified SET 
            user_verify_id = cur_user_verify_id
        WHERE id = cur_user_unverified_id;


        SELECT  ts_expiry,
                dt_expiry
                
        INTO    cur_user_verify_code_ts_expiry,
                cur_user_verify_code_dt_expiry
        
        FROM    user_verify
        WHERE   id = cur_user_verify_id;

        LEAVE process_user;
        
    END IF; 

    
    /* Unverified user signup or login again. */
    IF cur_user_unverified_id > 0 AND cur_user_id = 0 THEN
            
        UPDATE user_unverified SET 
            user_verify_id  = cur_user_verify_id,
            login_count     = login_count + 1
        WHERE id = cur_user_unverified_id;


        SELECT  ts_expiry,
                dt_expiry
                
        INTO    cur_user_verify_code_ts_expiry,
                cur_user_verify_code_dt_expiry
        
        FROM    user_verify
        WHERE   id = cur_user_verify_id;

        LEAVE process_user;
    END IF;
    
    
    IF  in_login_country_code   IS NOT NULL  AND
        in_viewport_width       IS NOT NULL  AND 
        in_viewport_height      IS NOT NULL THEN  
    
    
        /* This is a manual email login; The cur_user_id > 0; this means the user 
        need to input authentication code. Generate Verify code.  
        */
        /** Will also create a user_login entry and user should be automatically logged in*/
        INSERT INTO user_login(
            user_id,
            viewport_width,
            viewport_height,
            
            ip_address,
            country_code_login,
            login_loc_trace_id,
                        
                        
            is_mobile,       
            is_webview,      
            
            browser,         
            browser_version, 
            webview_platform,
            os,              
            os_version,      
            device,          
            device_type
        ) 
        VALUES (
            cur_user_id,        
            in_viewport_width,
            in_viewport_height,
            
            in_ip_address,
            in_login_country_code,
            cur_login_loc_trace_id,
                        
            in_is_mobile,       
            in_is_webview,      
            
            in_browser,         
            in_browser_version, 
            in_webview_platform,
            in_os,              
            in_os_version,      
            in_device,          
            in_device_type          
        );
        SELECT LAST_INSERT_ID() INTO cur_user_login_id; 
        
        
        
        UPDATE user SET 
            last_user_verify_id     = cur_user_verify_id,
            last_user_login_id      = cur_user_login_id,
            login_count             = login_count +1
        WHERE id = cur_user_id;
    
    ELSE
    
        UPDATE user SET 
            last_user_verify_id     = cur_user_verify_id
        WHERE id = cur_user_id;
    
    END IF;
    
    
    SELECT  ts_expiry,
            dt_expiry
            
    INTO    cur_user_verify_code_ts_expiry,
            cur_user_verify_code_dt_expiry
    
    FROM    user_verify
    WHERE   id = cur_user_verify_id;

    LEAVE process_user;
    
END IF;



/* At this point it is either 
- user login or signup using social media; If user is using social media
to login or signup, it is assumed verified. 

- user already registered and verified.
*/

IF cur_user_unverified_id > 0 THEN 
    DELETE FROM user_unverified 
    WHERE id = cur_user_unverified_id;

END IF;



/**
2026-03-18: Notes on login using Social Media
As of this writing, there are 3 Social Media channel supported or to be supported.

Login Via   To be supported     Development Status
==========  ===============     ===============
Google      fully supported     working correctly
Facebook    must be supported   on development
Tiktok      must be supported   not visible to users


1.) Login using these social media are always assumed they are verified.
So NO need to ask for verification codes.

2.) The Google login, always provide user email, user name, user last name and 
user first name.

3.) Other social media aside from google are assumed they may or may not
provide email.

 
- Every login now creates user_login record
- Screen dimensions captured for device analytics
- Last login ID stored in user table for quick lookup
- Location data enriched with IP trace


*/


/** Google does not provide this, only email that creates uniqueness.*/

IF in_social_media_user_id IS NOT NULL THEN 
    IF in_social_media_user_id IS NOT NULL THEN 
        SELECT  id
        INTO    cur_user_using_social_media_id
        FROM    user
        WHERE   signup_social_media_id = in_login_social_media_id AND
                social_media_user_id = in_social_media_user_id
        LIMIT 1;
    END IF;
END IF;



/* It is possible now not to have any user email as long as there is a 
verified social media login.*/
    

IF cur_user_id = 0 AND cur_user_using_social_media_id = 0 THEN 
    /* User signup using social media*/

    IF in_email IS NOT NULL THEN 
        SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE + FLAG_BIT_USER_EMAIL_VERIFIED;
    ELSE
        SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE;
    END IF;


    INSERT INTO user(
        name,
        name_last,
        name_first,
        email,
        
        flag,
        login_count,
        
        signup_country_id,
        signup_social_media_id,
        social_media_user_id
        
    ) VALUES (
        in_name,
        in_name_last,
        in_name_first,
        in_email,
        
        cur_user_flag,
        1,
        
        cur_country_id,
        in_login_social_media_id,
        in_social_media_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_user_id;
    
    
    UPDATE app_country SET
        signup_count = signup_count + 1
    WHERE id = cur_country_id;


    SET use_this_user_id = cur_user_id;
    

ELSE
    /* user login using social media*/
    
    IF cur_user_id > 0 THEN 
        SET use_this_user_id = cur_user_id;
    ELSE
        SET use_this_user_id = cur_user_using_social_media_id;
    END IF;
    
    
    /* Do people can change their names in social media?*/
    UPDATE user SET 
        name                    = in_name,
    
        name_last               = in_name_last,
        name_first              = in_name_first
    WHERE id = use_this_user_id;


END IF;


IF  in_login_country_code       IS NOT NULL  AND
        in_viewport_width       IS NOT NULL  AND 
        in_viewport_height      IS NOT NULL THEN 
        
    /** Will also create a user_login entry and user should be automatically logged in*/
    INSERT INTO user_login(
        user_id,
        
        viewport_width,
        viewport_height,
        
        ip_address,
        country_code_login,
        login_loc_trace_id,
                    
                    
        is_mobile,       
        is_webview,      
        
        browser,         
        browser_version, 
        webview_platform,
        os,              
        os_version,      
        device,          
        device_type
    ) 
    VALUES (
        use_this_user_id,
        
        in_viewport_width,
        in_viewport_height,
        
        in_ip_address,
        in_login_country_code,
        cur_login_loc_trace_id,
                    
        in_is_mobile,       
        in_is_webview,      
        
        in_browser,         
        in_browser_version, 
        in_webview_platform,
        in_os,              
        in_os_version,      
        in_device,          
        in_device_type       
    );
    SELECT LAST_INSERT_ID() INTO cur_user_login_id; 

ELSE
    /*Minimum info*/


    INSERT INTO user_login(
        user_id,
        viewport_width,
        viewport_height,
        
        ip_address
    ) VALUES (
        use_this_user_id,
        
        in_viewport_width,
        in_viewport_height,
        
        in_ip_address
    ); 
    SELECT LAST_INSERT_ID() INTO cur_user_login_id; 
    

END IF;


UPDATE user SET 
    login_count             = login_count +1,
    last_user_login_id      = cur_user_login_id
WHERE id = cur_user_id;



END process_user;




SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id        = cur_user_id;



SELECT 
    res_num                         AS result_number,
    res_code                        AS result_code,
    res_desc                        AS result_desc,
        
    cur_user_id                     AS user_id,
    cur_user_account_id             AS user_account_id,
    cur_user_flag                   AS user_flag,
    
    cur_user_unverified_id          AS user_unverified_id,
    cur_user_verify_id              AS user_verify_code_id,                  
    cur_user_verify_code            AS user_verify_code,
    cur_user_verify_code_ts_expiry  AS code_ts_expiry,
    cur_user_verify_code_dt_expiry  AS code_dt_expiry,
    NUM_MINUTES_CODE_EXPIRY         AS expiry_minutes;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_add_add $$
CREATE PROCEDURE pig_prod_pig_add_add(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_production_group_id  INT,
    
    in_date_added           VARCHAR(10),
    in_num_pigs_added       INT,
    
    in_comments             VARCHAR(160)
)  

BEGIN

/** 
 * Will add pigs (which is assumed to be external) to a pig_production OR
 * production_group entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 21, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_CANNOT_ADD_PIG    INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_ADD        INT             DEFAULT 27;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE PRODUCTION_GROUP_STATUS_ID_GROWING      INT             DEFAULT 1;
DECLARE PRODUCTION_GROUP_STATUS_ID_HARVESTED    INT             DEFAULT 2;
DECLARE PRODUCTION_GROUP_STATUS_ID_CLOSED       INT             DEFAULT 3;


DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_weaning               DATE            DEFAULT NULL;


DECLARE cur_num_pigs_current                    INT             DEFAULT 0;



DECLARE cur_dead_at_stage                       INT             DEFAULT 0;

DECLARE cur_pig_prod_pig_add_id                INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
     /* pig_production */
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    pig_production 
    WHERE   id = in_pig_prod_id;

ELSE
    /* production_group */
    SELECT  
            account_id,
            pig_farm_id,
            prod_group_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    production_group 
    WHERE   id = in_production_group_id;


END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_ADD,
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


/* Check production status*/
IF in_pig_prod_id > 0 THEN 
    /* pig_production */
    
    IF cur_pig_prod_status_id IN (  PRODUCTION_STATUS_ID_CLOSED,
                                    PRODUCTION_STATUS_ID_HARVESTED) THEN 
        SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
        SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
        SET res_desc    = "Production status already HARVESTED or CLOSED.";
    
        LEAVE process_user;
    END IF;

    IF  cur_pig_prod_status_id < PRODUCTION_STATUS_ID_LACTATING THEN 
        
        SET res_num     = RES_NUM_PIG_PROD_CANNOT_ADD_PIG;
        SET res_code    = "RES_NUM_PIG_PROD_CANNOT_ADD_PIG";
        SET res_desc    = "No pigs yet";
        
        LEAVE process_user;
    END IF;

ELSE
    /* production_group */
    IF cur_pig_prod_status_id != PRODUCTION_GROUP_STATUS_ID_GROWING THEN
        SET res_num     = RES_NUM_PIG_PROD_CANNOT_ADD_PIG;
        SET res_code    = "RES_NUM_PIG_PROD_CANNOT_ADD_PIG";
        SET res_desc    = "Production group status not GROWING.";
    
        LEAVE process_user;
    
    END IF;
    
    
END IF;


INSERT INTO pig_prod_pig_add (
    account_id,
    pig_farm_id,
    pig_prod_id,
    production_group_id,
    
    date_added,
    num_pigs_added,
    comments,
    
    added_by_user_id
    
) VALUES (
    cur_user_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    in_production_group_id,
    
    in_date_added,
    in_num_pigs_added,
    in_comments,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_pig_add_id;


/* Calculate current number of pigs.*/
IF in_pig_prod_id > 0 THEN 
    CALL production_calculate_current_pigs(in_pig_prod_id, 0, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    UPDATE  pig_production SET
        num_pigs_current = cur_num_pigs_current
    WHERE id = in_pig_prod_id;

ELSE
    CALL production_calculate_current_pigs(0, in_production_group_id, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    UPDATE  production_group SET
        num_pigs_current = cur_num_pigs_current
    WHERE id = in_production_group_id;
    
END IF;



END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_pig_add_id             AS pig_prod_pig_add_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS production_harvest_update $$
CREATE PROCEDURE production_harvest_update(
    in_user_id              INT,
    
    in_production_harvest_id INT,
    
    in_acc_pig_buyer_id     INT,
    
    in_date_harvest         VARCHAR(10),
    
    in_num_pigs_harvest     INT,
    in_harvest_type_id      INT,
    
    in_live_weight                  DECIMAL(6,1),
    in_live_price_per_unit          DECIMAL(6,1),
    
    in_slaughter_weight             DECIMAL(6,1),
    in_slaughter_minus_weight       DECIMAL(6,1),
    in_slaughter_price_per_unit     DECIMAL(6,1),
    
    in_net_sales            DECIMAL(8,1),
    in_harvest_cost         DECIMAL(5,1),
    in_comments             VARCHAR(160),
    
    in_weight_pp_live       VARCHAR(400),
    in_weight_pp_slaughter  VARCHAR(400)

)  

BEGIN

/** 
 * Will update production_harvest entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 18, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED INT             DEFAULT 21;
DECLARE RES_NUM_HARVEST_ENTRY_NOT_ALLOWED       INT             DEFAULT 22;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;


DECLARE PRODUCTION_GROUP_STATUS_ID_GROWING      INT             DEFAULT 1;
DECLARE PRODUCTION_GROUP_STATUS_ID_HARVESTED    INT             DEFAULT 2;
DECLARE PRODUCTION_GROUP_STATUS_ID_CLOSED       INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_production_harvest_account_id       INT             DEFAULT 0;
DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_production_group_id                 INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;

DECLARE cur_num_days_since_birth                INT             DEFAULT NULL;

DECLARE cur_live_weight_ave                     DECIMAL(6,1)    DEFAULT NULL;
DECLARE cur_slaughter_weight_ave                DECIMAL(6,1)    DEFAULT NULL;
DEclARE cur_slaughter_net_weight                DECIMAL(6,1)    DEFAULT NULL;
DECLARE cur_net_sales_pp                        DECIMAL(8,1)    DEFAULT NULL;


DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;
DECLARE cur_num_pigs_harvest                    INT             DEFAULT 0;
DECLARE cur_num_dead_pigs                       INT             DEFAULT 0;
DECLARE cur_num_pigs_current                    INT             DEFAULT 0;

DECLARE cur_production_harvest_id                 INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT 
    account_id,
    pig_prod_id,
    production_group_id
INTO
    cur_production_harvest_account_id,
    cur_pig_prod_id,
    cur_production_group_id

FROM production_harvest 
WHERE id = in_production_harvest_id;


IF cur_pig_prod_id > 0 THEN 
    SELECT  prod_status_id
    INTO    cur_pig_prod_status_id
    FROM    pig_production
    WHERE   id = cur_pig_prod_id;
END IF;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_production_harvest_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_HARVEST,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* Check production status*/
IF cur_pig_prod_id > 0 THEN 
    /* pig_production */
    IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_WEANING, 
                                        PRODUCTION_STATUS_ID_GROWING) THEN
        SET res_num     = RES_NUM_HARVEST_ENTRY_NOT_ALLOWED;
        SET res_code    = "RES_NUM_HARVEST_ENTRY_NOT_ALLOWED";
        SET res_desc    = "Production status not WEANING or GROWING.";
    
        LEAVE process_user;
    
    END IF;

ELSE 
    /* production_group */
    IF cur_pig_prod_status_id != PRODUCTION_GROUP_STATUS_ID_GROWING THEN
        SET res_num     = RES_NUM_HARVEST_ENTRY_NOT_ALLOWED;
        SET res_code    = "RES_NUM_HARVEST_ENTRY_NOT_ALLOWED";
        SET res_desc    = "Production group status not GROWING.";
    
        LEAVE process_user;
    
    END IF;
    
END IF;


IF cur_pig_prod_id > 0 THEN 
    SELECT  date_actual_birth
    INTO    cur_pig_prod_date_actual_birth
    FROM    pig_production
    WHERE   id = cur_pig_prod_id;
    
    
    IF cur_pig_prod_date_actual_birth IS NOT NULL THEN 
        SET cur_num_days_since_birth = DATEDIFF(in_date_harvest, 
                cur_pig_prod_date_actual_birth); 
    ELSE
        SET cur_num_days_since_birth = NULL;
    END IF;

END IF;


IF in_live_weight IS NOT NULL THEN 
    SET cur_live_weight_ave = in_live_weight/in_num_pigs_harvest;
END IF;

IF in_slaughter_weight IS NOT NULL THEN 
    SET cur_slaughter_weight_ave = in_slaughter_weight/in_num_pigs_harvest;
    
    IF in_slaughter_minus_weight IS NOT NULL THEN 
        SET cur_slaughter_net_weight = in_slaughter_weight - in_slaughter_minus_weight;
    ELSE
        SET cur_slaughter_net_weight = in_slaughter_weight;
    END IF;
    
END IF;

IF in_net_sales IS NOT NULL THEN
    SET cur_net_sales_pp = in_net_sales / in_num_pigs_harvest;
END IF;




UPDATE production_harvest SET
    acc_pig_buyer_id        = in_acc_pig_buyer_id,
    date_harvest            = in_date_harvest,
    num_days_since_birth    = cur_num_days_since_birth,
        
    num_pigs_harvest        = in_num_pigs_harvest,
    harvest_type_id         = in_harvest_type_id,
        
    live_weight             = in_live_weight,
    live_weight_ave         = cur_live_weight_ave,
    live_price_per_unit     = in_live_price_per_unit,
    
    slaughter_weight        = in_slaughter_weight,
    slaughter_minus_weight  = in_slaughter_minus_weight,
    slaughter_net_weight    = cur_slaughter_net_weight,
    slaughter_weight_ave    = cur_slaughter_weight_ave,
    slaughter_price_per_unit= in_slaughter_price_per_unit,
    
    net_sales               = in_net_sales,
    harvest_cost            = in_harvest_cost,
    comments                = in_comments,
        
    weight_pp_lw_csv        = in_weight_pp_live,
    weight_pp_sw_csv        = in_weight_pp_slaughter,
        
    last_update_user_id     = in_user_id,
    dt_last_update          = CURRENT_TIMESTAMP
WHERE id = in_production_harvest_id;


/* Calculate current number of pigs.*/
IF cur_pig_prod_id > 0 THEN 
    CALL production_calculate_current_pigs(cur_pig_prod_id, 0, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
        
        UPDATE  pig_production SET
            num_pigs_current = 0,
            prod_status_id = PRODUCTION_STATUS_ID_HARVESTED
        WHERE id = cur_pig_prod_id;
    END IF;
    

    IF cur_num_pigs_current > 0 THEN 
        UPDATE  pig_production SET
            num_pigs_current = cur_num_pigs_current
        WHERE id = cur_pig_prod_id;
    ELSE
        
        UPDATE  pig_production SET
            num_pigs_current = 0,
            prod_status_id = PRODUCTION_STATUS_ID_HARVESTED
        WHERE id = cur_pig_prod_id;
    END IF;

ELSE
    CALL production_calculate_current_pigs(0, cur_production_group_id, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    IF cur_num_pigs_current > 0 THEN 
        UPDATE  production_group SET
            num_pigs_current = cur_num_pigs_current
        WHERE id = in_production_group_id;
    ELSE
        
        UPDATE  production_group SET
            num_pigs_current = 0,
            prod_status_id = PRODUCTION_GROUP_STATUS_ID_HARVESTED
        WHERE id = in_production_group_id;
    END IF;
    
END IF;


IF cur_pig_prod_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_harvest = data_ver_num_harvest + 1
    WHERE id = cur_pig_prod_id;
END IF;

IF cur_production_group_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_harvest = data_ver_num_harvest + 1
    WHERE id = cur_production_group_id;
END IF;



END process_user;


SELECT  prod_status_id
INTO    cur_pig_prod_status_id
FROM    pig_production
WHERE   id = cur_pig_prod_id;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_production_harvest_id            AS prod_harvest_id,
    cur_pig_prod_status_id              AS prod_status_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS production_harvest_add $$
CREATE PROCEDURE production_harvest_add(
    in_user_id              INT,
    in_pig_prod_id          INT,
    in_production_group_id  INT,
    in_acc_pig_buyer_id     INT,
    
    in_date_harvest         VARCHAR(10),
    
    in_num_pigs_harvest     INT,
    in_harvest_type_id      INT,
    
    in_live_weight                  DECIMAL(6,1),
    in_live_price_per_unit          DECIMAL(6,1),
    
    in_slaughter_weight             DECIMAL(6,1),
    in_slaughter_minus_weight       DECIMAL(6,1),
    in_slaughther_price_per_unit    DECIMAL(6,1),
    
    in_net_sales            DECIMAL(8,1),
    in_harvest_cost         DECIMAL(5,1),
    in_comments             VARCHAR(160),
    
    in_weight_pp_live       VARCHAR(400),
    in_weight_pp_slaughter  VARCHAR(400)

)  

BEGIN

/** 
 * Will add pig_prod_harvest entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 4, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_HARVEST_ENTRY_NOT_ALLOWED       INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;


DECLARE PRODUCTION_GROUP_STATUS_ID_GROWING      INT             DEFAULT 1;
DECLARE PRODUCTION_GROUP_STATUS_ID_HARVESTED    INT             DEFAULT 2;
DECLARE PRODUCTION_GROUP_STATUS_ID_CLOSED       INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;

DECLARE cur_num_days_since_birth                INT             DEFAULT NULL;


DECLARE cur_live_weight_ave                     DECIMAL(6,1)    DEFAULT NULL;
DECLARE cur_slaughter_weight_ave                DECIMAL(6,1)    DEFAULT NULL;
DEclARE cur_slaughter_net_weight                DECIMAL(6,1)    DEFAULT NULL;
DECLARE cur_net_sales_pp                        DECIMAL(8,1)    DEFAULT NULL;

DECLARE cur_production_harvest_id               INT             DEFAULT 0;

DECLARE cur_num_pigs_current                    INT             DEFAULT 0;




DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    /* pig_production */
    SELECT 
        account_id,
        pig_farm_id,
        prod_status_id,
        date_actual_birth
    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_actual_birth
    FROM pig_production 
    WHERE id = in_pig_prod_id;

ELSE
    /* production_group */
    SELECT 
        account_id,
        prod_group_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM production_group 
    WHERE id = in_production_group_id;

END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_HARVEST,
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


/* Check for duplicate entry */
IF in_pig_prod_id > 0 THEN 
    /* pig_production */
    SELECT  id
    INTO    cur_production_harvest_id
    FROM    production_harvest
    WHERE   pig_prod_id         = in_pig_prod_id    AND
            acc_pig_buyer_id    = in_acc_pig_buyer_id AND
            date_harvest        = in_date_harvest
    LIMIT   1;
    
ELSE
    /* production_group */
    SELECT  id
    INTO    cur_production_harvest_id
    FROM    production_harvest
    WHERE   production_group_id = in_production_group_id    AND
            acc_pig_buyer_id    = in_acc_pig_buyer_id AND
            date_harvest        = in_date_harvest
    LIMIT   1;
    
END IF;

IF cur_production_harvest_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* Check production status*/
IF in_pig_prod_id > 0 THEN 
    /* pig_production */
    IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_WEANING, 
                                        PRODUCTION_STATUS_ID_GROWING) THEN
        SET res_num     = RES_NUM_HARVEST_ENTRY_NOT_ALLOWED;
        SET res_code    = "RES_NUM_HARVEST_ENTRY_NOT_ALLOWED";
        SET res_desc    = "Production status not WEANING or GROWING.";
    
        LEAVE process_user;
    
    END IF;

ELSE 
    /* production_group */
    IF cur_pig_prod_status_id != PRODUCTION_GROUP_STATUS_ID_GROWING THEN
        SET res_num     = RES_NUM_HARVEST_ENTRY_NOT_ALLOWED;
        SET res_code    = "RES_NUM_HARVEST_ENTRY_NOT_ALLOWED";
        SET res_desc    = "Production group status not GROWING.";
    
        LEAVE process_user;
    
    END IF;
    
END IF;


IF cur_pig_prod_date_actual_birth IS NOT NULL THEN 
    SET cur_num_days_since_birth = DATEDIFF(in_date_harvest, 
            cur_pig_prod_date_actual_birth); 
ELSE
    SET cur_num_days_since_birth = NULL;
END IF;


IF in_live_weight IS NOT NULL THEN 
    SET cur_live_weight_ave = in_live_weight/in_num_pigs_harvest;
END IF;

IF in_slaughter_weight IS NOT NULL THEN 
    SET cur_slaughter_weight_ave = in_slaughter_weight/in_num_pigs_harvest;
    
    IF in_slaughter_minus_weight IS NOT NULL THEN 
        SET cur_slaughter_net_weight = in_slaughter_weight - in_slaughter_minus_weight;
    ELSE
        SET cur_slaughter_net_weight = in_slaughter_weight;
    END IF;
    
END IF;

IF in_net_sales IS NOT NULL THEN
    SET cur_net_sales_pp = in_net_sales / in_num_pigs_harvest;
END IF;




INSERT INTO production_harvest(
    account_id,
    pig_farm_id,

    pig_prod_id,
    production_group_id,
    acc_pig_buyer_id,
    
    date_harvest,
    num_days_since_birth,
    
    num_pigs_harvest,
    harvest_type_id,
    
    live_weight,
    live_weight_ave,
    live_price_per_unit,
    
    slaughter_weight,
    slaughter_minus_weight,
    slaughter_net_weight,
    slaughter_weight_ave,
    slaughter_price_per_unit,
    
    net_sales,
    net_sales_pp,
    harvest_cost,
    comments,
    
    weight_pp_lw_csv,
    weight_pp_sw_csv,

    added_by_user_id
    
) VALUES (
    cur_pig_prod_account_id,
    cur_pig_prod_pig_farm_id,

    in_pig_prod_id,
    in_production_group_id,
    in_acc_pig_buyer_id,
    
    in_date_harvest,
    cur_num_days_since_birth,
    
    in_num_pigs_harvest,
    in_harvest_type_id,
    
    in_live_weight,
    cur_live_weight_ave,
    in_live_price_per_unit,
    
    in_slaughter_weight,
    in_slaughter_minus_weight,
    cur_slaughter_net_weight,
    cur_slaughter_weight_ave,
    in_slaughther_price_per_unit,
    
    in_net_sales,
    cur_net_sales_pp,
    in_harvest_cost,
    in_comments,
    
    in_weight_pp_live,     
    in_weight_pp_slaughter,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_production_harvest_id;


/* Calculate current number of pigs.*/
IF in_pig_prod_id > 0 THEN 
    CALL production_calculate_current_pigs(in_pig_prod_id, 0, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    IF cur_num_pigs_current > 0 THEN 
        UPDATE  pig_production SET
            num_pigs_current = cur_num_pigs_current
        WHERE id = in_pig_prod_id;
    ELSE
        
        UPDATE  pig_production SET
            num_pigs_current = 0,
            prod_status_id = PRODUCTION_STATUS_ID_HARVESTED
        WHERE id = in_pig_prod_id;
    END IF;

ELSE
    CALL production_calculate_current_pigs(0, in_production_group_id, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    IF cur_num_pigs_current > 0 THEN 
        UPDATE  production_group SET
            num_pigs_current = cur_num_pigs_current
        WHERE id = in_production_group_id;
    ELSE
        
        UPDATE  production_group SET
            num_pigs_current = 0,
            prod_status_id = PRODUCTION_GROUP_STATUS_ID_HARVESTED
        WHERE id = in_production_group_id;
    END IF;
    
END IF;


IF in_pig_prod_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_harvest = data_ver_num_harvest + 1
    WHERE id = in_pig_prod_id;
END IF;

IF in_production_group_id > 0 THEN 
    UPDATE pig_production SET 
        data_ver_num_harvest = data_ver_num_harvest + 1
    WHERE id = in_production_group_id;
END IF;




END process_user;


SELECT  prod_status_id
INTO    cur_pig_prod_status_id
FROM    pig_production
WHERE   id = in_pig_prod_id;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_production_harvest_id           AS prod_harvest_id,
    cur_pig_prod_status_id              AS prod_status_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_dead_add $$
CREATE PROCEDURE pig_prod_pig_dead_add(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_production_group_id  INT,
    
    in_date_dead            VARCHAR(10),
    in_pig_dead_type_id     INT,
    in_num_pigs_dead        INT,
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will create pig_prod_pig_dead entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 27, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD    INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE PRODUCTION_GROUP_STATUS_ID_GROWING      INT             DEFAULT 1;
DECLARE PRODUCTION_GROUP_STATUS_ID_HARVESTED    INT             DEFAULT 2;
DECLARE PRODUCTION_GROUP_STATUS_ID_CLOSED       INT             DEFAULT 3;


DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;




DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_weaning               DATE            DEFAULT NULL;


DECLARE cur_num_pigs_current                    INT             DEFAULT 0;



DECLARE cur_dead_at_stage                       INT             DEFAULT 0;

DECLARE cur_pig_prod_pig_dead_id                INT             DEFAULT 0;


DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE cur_num_dead_pigs                       INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
     /* pig_production */
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id,
            
            date_weaning
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id,
            
            cur_pig_prod_date_weaning
            
    FROM    pig_production 
    WHERE   id = in_pig_prod_id;

ELSE
    /* production_group */
    SELECT  
            account_id,
            pig_farm_id,
            prod_group_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    production_group 
    WHERE   id = in_production_group_id;


END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD,
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


/* Check production status*/
IF in_pig_prod_id > 0 THEN 
    /* pig_production */
    
    IF cur_pig_prod_status_id IN (  PRODUCTION_STATUS_ID_CLOSED,
                                    PRODUCTION_STATUS_ID_HARVESTED) THEN 
        SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
        SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
        SET res_desc    = "Production status already HARVESTED or CLOSED.";
    
        LEAVE process_user;
    END IF;

    IF  cur_pig_prod_status_id < PRODUCTION_STATUS_ID_LACTATING THEN 
        
        SET res_num     = RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD;
        SET res_code    = "RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD";
        SET res_desc    = "No pigs yet";
        
        LEAVE process_user;
    END IF;

ELSE
    /* production_group */
    IF cur_pig_prod_status_id != PRODUCTION_GROUP_STATUS_ID_GROWING THEN
        SET res_num     = RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD;
        SET res_code    = "RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD";
        SET res_desc    = "Production group status not GROWING.";
    
        LEAVE process_user;
    
    END IF;
    
    
END IF;


/* Compute dead_at_stage*/
IF in_pig_prod_id > 0 THEN 

    IF cur_pig_prod_date_weaning IS NULL THEN 
        SET cur_dead_at_stage = DEAD_AT_STAGE_LACTATING;
    ELSE
        IF in_date_dead >= cur_pig_prod_date_weaning THEN 
            SET cur_dead_at_stage = DEAD_AT_STAGE_GROWING;
        ELSE
            SET cur_dead_at_stage = DEAD_AT_STAGE_LACTATING;
        END IF;
    END IF;

ELSE
    SET cur_dead_at_stage = DEAD_AT_STAGE_GROWING;
END IF;


INSERT INTO pig_prod_pig_dead (
    account_id,
    pig_farm_id,
    pig_prod_id,
    production_group_id,
    
    date_dead,
    dead_type_id,
    dead_at_stage,
    num_pigs_dead,
    
    added_by_user_id
    
) VALUES (
    cur_user_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    in_production_group_id,
    
    in_date_dead,
    in_pig_dead_type_id,
    cur_dead_at_stage,
    in_num_pigs_dead,
    
    in_user_id
);


SELECT LAST_INSERT_ID() INTO cur_pig_prod_pig_dead_id;


/* Add notes*/
IF in_notes IS NOT NULL THEN 
    INSERT INTO pig_prod_notes (
        account_id,
        pig_farm_id,
        pig_prod_id,
        
        notes,
        date_notes,
        added_by_user_id
        
    ) VALUES (
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        in_pig_prod_id,
        
        in_notes,
        CURRENT_DATE,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    /* pig_production.insem_notes_id*/
    UPDATE pig_prod_pig_dead SET
        notes_id = cur_pig_prod_notes_id
    WHERE id = cur_pig_prod_pig_dead_id;

END IF;






/* Calculate current number of pigs.*/
IF in_pig_prod_id > 0 THEN 
    CALL production_calculate_current_pigs(in_pig_prod_id, 0, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    
    
    /* Dead after birth This can be NULL.*/
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   pig_prod_id = in_pig_prod_id;
    

    UPDATE  pig_production SET
        num_pigs_current        = cur_num_pigs_current,
        num_dead_after_birth    = cur_num_dead_pigs,
        data_ver_num_pig_prod   = data_ver_num_pig_prod +1
    WHERE id = in_pig_prod_id;

ELSE
    CALL production_calculate_current_pigs(0, in_production_group_id, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    UPDATE  production_group SET
        num_pigs_current        = cur_num_pigs_current,
        data_ver_num_pig_prod   = data_ver_num_pig_prod +1
    WHERE id = in_production_group_id;
    
END IF;



END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_pig_dead_id            AS pig_prod_pig_dead_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_dead_update $$
CREATE PROCEDURE pig_prod_pig_dead_update(
    in_user_id                  INT,
    
    in_pig_prod_pig_dead_id     INT,
    
    in_date_dead                VARCHAR(10),
    in_pig_dead_type_id         INT,
    in_num_pigs_dead            INT,
    in_notes                    VARCHAR(160)
    
)

BEGIN

/** 
 * Will update pig_prod_pig_dead entry.
 * @author Jack Wong
 * @since August 27, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD    INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_dead_pig_prod_id                INT             DEFAULT 0;
DECLARE cur_pig_dead_production_group_id        INT             DEFAULT 0;
DECLARE cur_pig_dead_notes_id                   INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_weaning               DATE            DEFAULT NULL;


DECLARE cur_num_pigs_current                    INT             DEFAULT 0;


DECLARE cur_dead_at_stage                       INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        a.account_id,
        a.pig_prod_id,
        a.production_group_id,
        a.notes_id,
        
        b.pig_farm_id,
        b.prod_status_id,
        b.date_weaning
INTO    
        cur_pig_prod_account_id,
        cur_pig_dead_pig_prod_id,
        cur_pig_dead_production_group_id,
        cur_pig_dead_notes_id,
        
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_weaning
FROM    pig_prod_pig_dead a 
LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id
WHERE   a.id = in_pig_prod_pig_dead_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


/* Compute dead_at_stage*/
IF cur_pig_dead_pig_prod_id > 0 THEN 

    IF cur_pig_prod_date_weaning IS NULL THEN 
        SET cur_dead_at_stage = DEAD_AT_STAGE_LACTATING;
    ELSE
        IF in_date_dead >= cur_pig_prod_date_weaning THEN 
            SET cur_dead_at_stage = DEAD_AT_STAGE_GROWING;
        ELSE
            SET cur_dead_at_stage = DEAD_AT_STAGE_LACTATING;
        END IF;
    END IF;

ELSE
    SET cur_dead_at_stage = DEAD_AT_STAGE_GROWING;
END IF;

UPDATE pig_prod_pig_dead SET
    date_dead           = in_date_dead,
    dead_type_id        = in_pig_dead_type_id,
    num_pigs_dead       = in_num_pigs_dead,

    notes               = in_notes,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_pig_dead_id;


/* Calculate current number of pigs.*/
IF cur_pig_dead_pig_prod_id > 0 THEN 
    CALL production_calculate_current_pigs(cur_pig_dead_pig_prod_id, 0, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    UPDATE  pig_production SET
        num_pigs_current = cur_num_pigs_current
    WHERE id = cur_pig_dead_pig_prod_id;

ELSE
    CALL production_calculate_current_pigs(0, cur_pig_dead_production_group_id, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    UPDATE  production_group SET
        num_pigs_current = cur_num_pigs_current
    WHERE id = cur_pig_dead_production_group_id;
    
END IF;



IF cur_pig_dead_notes_id > 0 THEN 
    UPDATE pig_prod_notes SET
        notes               = in_notes,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP

    WHERE id = cur_pig_dead_notes_id;

ELSE
    IF in_notes IS NOT NULL THEN 
        INSERT INTO pig_prod_notes (
            account_id,
            pig_farm_id,
            pig_prod_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_pig_prod_account_id, 
            cur_pig_prod_pig_farm_id,
            cur_pig_dead_pig_prod_id,
            
            in_notes,
            CURRENT_DATE,
            in_user_id
        );
        
        SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
        
        /* pig_production.insem_notes_id*/
        UPDATE pig_prod_pig_dead SET
            notes_id = cur_pig_prod_notes_id
        WHERE id = in_pig_prod_pig_dead_id;
    END IF;
    
END IF;





END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_pig_dead_id             AS pig_prod_pig_dead_id;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_selection_delete $$
CREATE PROCEDURE account_selection_delete(
    in_user_id              INT,
    
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    in_semen_supplier_id    INT
)  

BEGIN

/** 
 * Will add account_selection entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 19, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;




/* account_selection.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED   INT             DEFAULT 1;


/* supplier.flag bits*/
DECLARE FLAG_BIT_SUPPLIER_IS_DELETED            INT             DEFAULT 1;
DECLARE FLAG_BIT_SUPPLIER_IS_VERIFIED           INT             DEFAULT 2;


/* semen_supplier_semen.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_DELETED      INT       DEFAULT 1;
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED     INT       DEFAULT 2;



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
    
    0,
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF in_feed_supplier_id > 0 THEN 
    /* The already deleted entries, should not be updated
    to preserve who and when the entries were deleted.
    */
    
    UPDATE account_selection SET
        flag = flag | FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED,
        last_update_user_id = in_user_id,
        dt_last_update = CURRENT_TIMESTAMP
    
    WHERE account_id = cur_user_account_id          AND 
          feed_supplier_id = in_feed_supplier_id    AND 
          (flag & FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED) = 0;

END IF;


IF in_semen_supplier_id > 0 THEN 
    /* The already deleted entries, should not be updated
    to preserve who and when the entries were deleted.
    */
    
    UPDATE account_selection SET
        flag = flag | FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED,
        last_update_user_id = in_user_id,
        dt_last_update = CURRENT_TIMESTAMP
    
    WHERE account_id = cur_user_account_id          AND 
          semen_supplier_id = in_semen_supplier_id  AND 
          (flag & FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED) = 0;
    
    
    /* Note a feed supplier, gilt supplier and semen supplier can be
    one entity. They all point to common_supplier table.
    */
    
    SELECT  COUNT(*)
    INTO    cur_count
    FROM    account_selection
    WHERE   (
            feed_supplier_id    = in_semen_supplier_id OR
            semen_supplier_id   = in_semen_supplier_id OR 
            gilt_supplier_id    = in_semen_supplier_id
            )
            AND 
            account_id != cur_user_account_id;


    /* Delete the supplier on these condiitons:
    1.) The account who created it, is the one who deleted it.
    Nobody else is using it.
    
    2.) The supplier is not verified.
    supplier.flag.FLAG_BIT_SUPPLIER_IS_VERIFIED = 0
    
    
    
    */
    IF cur_count = 0 THEN
        UPDATE common_supplier SET 
            flag = flag | FLAG_BIT_SUPPLIER_IS_DELETED,
            deleted_by_user_id = in_user_id,
            dt_last_update = CURRENT_TIMESTAMP
        WHERE id = in_semen_supplier_id;
        
        
        /* Delete semen_supplier_semen of the deleted semen_supplier if 
        nobody is using them

        */
        
        UPDATE semen_supplier_semen SET 
            flag = flag | FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_DELETED,
            last_update_user_id = in_user_id,
            dt_last_update = CURRENT_TIMESTAMP
        WHERE semen_supplier_id = in_semen_supplier_id AND 
            usage_counter = 0;
        
        
    END IF;
    
    
END IF;



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS account_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_selection_add $$
CREATE PROCEDURE account_selection_add(
    in_user_id              INT,
    
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    in_semen_supplier_id    INT
)  

BEGIN

/** 
 * Will add account_selection entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;




/* account_selection.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED   INT             DEFAULT 1;




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
    
    0,
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF in_feed_supplier_id > 0 THEN 
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id =  cur_user_account_id AND 
            feed_supplier_id = in_feed_supplier_id AND
            flag & FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED = 0;
            

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            feed_supplier_id,
            
            added_by_user_id
        ) VALUES (
            cur_user_account_id,
            in_feed_supplier_id,
            
            in_user_id
        );
    END IF;

END IF;


IF in_semen_supplier_id > 0 THEN 
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id =  cur_user_account_id AND 
            semen_supplier_id = in_semen_supplier_id AND
            flag & FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED = 0;
            

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            semen_supplier_id,
            
            added_by_user_id
        ) VALUES (
            cur_user_account_id,
            in_semen_supplier_id,
            
            in_user_id
        );
    END IF;

END IF;



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS account_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_race_line_delete $$
CREATE PROCEDURE pig_race_line_delete(
    in_user_id                  INT,
    
    in_pig_race_line_id         INT
)  

BEGIN

/** 
 * Will delete pig_race_line entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";

/* pig_race_line.flag bits*/
DECLARE FLAG_BIT_PIG_RACE_LINE_IS_DELETED       INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_race_line_account_id            INT             DEFAULT 0;
DECLARE cur_pig_race_line_flag                  INT             DEFAULT 0;
DECLARE cur_pig_race_line_name                  VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_race_line_account_id
FROM    pig_race_line
WHERE   id = in_pig_race_line_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_race_line_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_RACE_LINE,
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



UPDATE pig_race_line SET
    flag                = flag | FLAG_BIT_PIG_RACE_LINE_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_pig_race_line_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_race_line_flag,
    cur_pig_race_line_name
FROM pig_race_line
WHERE id = in_pig_race_line_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_race_line_id                 AS pig_race_line_id,
    cur_pig_race_line_flag              AS pig_race_line_flag,
    cur_pig_race_line_name              AS pig_race_line_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_race_line_add $$
CREATE PROCEDURE pig_race_line_add(
    in_user_id              INT,

    in_pig_race_id          INT,
    
    in_name                 VARCHAR(50),
    in_description          VARCHAR(160)
)  

BEGIN

/** 
 * Will add pig_race_line entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_race_line_id                    INT             DEFAULT 0;
DECLARE cur_pig_race_line_flag                  INT             DEFAULT 0;
DECLARE cur_pig_race_line_name                  VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PIG_RACE_LINE,
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


/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_race_line_id
FROM    pig_race_line
WHERE   account_id          = cur_user_account_id   AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_pig_race_line_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO pig_race_line(
    account_id,
    pig_race_id,
    
    name,
    description,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_pig_race_id,
    
    in_name,
    in_description,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_race_line_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_race_line_flag,
    cur_pig_race_line_name
FROM pig_race_line
WHERE id = cur_pig_race_line_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_race_line_id                AS pig_race_line_id,
    cur_pig_race_line_flag              AS pig_race_line_flag,
    cur_pig_race_line_name              AS pig_race_line_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_race_line_update $$
CREATE PROCEDURE pig_race_line_update(
    in_user_id                  INT,
    
    in_pig_race_line_id         INT,
    in_pig_race_id              INT,
    
    in_name                     VARCHAR(50),
    in_description              VARCHAR(160)
    
)

BEGIN

/** 
 * Will update pig_race_line entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_race_line_id                    INT             DEFAULT 0;
DECLARE cur_pig_race_line_account_id            INT             DEFAULT 0;
DECLARE cur_pig_race_line_flag                  INT             DEFAULT 0;
DECLARE cur_pig_race_line_name                  VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_race_line_account_id
FROM    pig_race_line
WHERE   id = in_pig_race_line_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_race_line_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_RACE_LINE,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_race_line_id
FROM    pig_race_line
WHERE   id                  != in_pig_race_line_id  AND
        account_id          = cur_user_account_id   AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_pig_race_line_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



UPDATE pig_race_line SET
    pig_race_id         = in_pig_race_id,
    
    name                = in_name,
    description         = in_description,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_race_line_id;

END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_race_line_flag,
    cur_pig_race_line_name
FROM pig_race_line
WHERE id = in_pig_race_line_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_race_line_id                 AS pig_race_line_id,
    cur_pig_race_line_flag              AS pig_race_line_flag,
    cur_pig_race_line_name              AS pig_race_line_name;
    


END $$

DELIMITER ;
