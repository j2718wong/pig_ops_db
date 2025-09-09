DELIMITER $$

DROP PROCEDURE IF EXISTS feed_balance_add $$
CREATE PROCEDURE feed_balance_add(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_prod_group_id        INT,
    
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
 * Will add feed_balance entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 25, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
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



DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;
DECLARE cur_pig_prod_last_feed_balance_id       INT             DEFAULT 0;


DECLARE cur_feed_balance_id                     INT             DEFAULT 0;

DECLARE cur_num_days_since_birth                INT             DEFAULT 0;
DECLARE cur_num_weeks_since_birth               INT             DEFAULT 0;

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


IF in_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        prod_status_id,
        date_actual_birth,
        last_feed_balance_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_actual_birth,
        cur_pig_prod_last_feed_balance_id

    FROM pig_production 
    WHERE id = in_pig_prod_id;

ELSE
    IF in_prod_group_id > 0 THEN 
        SELECT 
            account_id,
            pig_prod_status_id

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM production_group 
        WHERE id = in_prod_group_id;
 
    END IF;
    
END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


/* Check for duplicate entry */
IF in_pig_prod_id > 0 THEN 
    SELECT  id
    INTO    cur_feed_balance_id
    FROM    feed_balance
    WHERE   pig_prod_id         = in_pig_prod_id    AND
            date_balance        = in_date_balance
    LIMIT   1;
    
ELSE
    
    IF in_prod_group_id > 0 THEN 
        SELECT  id
        INTO    cur_feed_balance_id
        FROM    feed_balance
        WHERE   pig_prod_group_id   = in_prod_group_id    AND
                date_balance        = in_date_balance
        LIMIT   1;
    END IF;
    
END IF;

IF cur_feed_balance_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;




INSERT INTO feed_balance(
    pig_prod_id,
    pig_prod_group_id,
    
    date_balance,
    
    num_pigs,
    
    num_lactating,
    num_booster,
    num_prestarter,
    num_starter,
    num_grower,
    num_finisher,

    added_by_user_id
) VALUES (
    in_pig_prod_id,
    in_prod_group_id,
    
    in_date_balance,
    
    in_num_pigs,
    
    in_num_lactating,
    in_num_booster,
    in_num_prestarter,
    in_num_starter,
    in_num_grower,
    in_num_finisher,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_balance_id;


IF in_pig_prod_id > 0 THEN 
    /* Compute num_days_since_birth, num_weeks_since_birth*/
    IF cur_pig_prod_date_actual_birth IS NOT NULL THEN
        SET cur_num_days_since_birth    = DATEDIFF(in_date_balance, cur_pig_prod_date_actual_birth);
        SET cur_num_weeks_since_birth   = ROUND(cur_num_days_since_birth/7);
    END IF; 
    
    IF cur_pig_prod_last_feed_balance_id IS NOT NULL THEN 
        SELECT  consumed_kg_total
        INTO    prev_consumed_kg_total
        FROM    feed_balance
        WHERE   id = cur_pig_prod_last_feed_balance_id;
    END IF;
    

    UPDATE pig_production SET
        last_feed_balance_m1_id     = cur_pig_prod_last_feed_balance_id,
        last_feed_balance_id        = cur_feed_balance_id
    WHERE id = in_pig_prod_id;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_lactating
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_LACTATING   AND 
            date_buy <= in_date_balance;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_booster
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_BOOSTER     AND 
            date_buy <= in_date_balance;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_prestarter
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_PRESTARTER  AND 
            date_buy <= in_date_balance;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_starter
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_STARTER     AND 
            date_buy <= in_date_balance;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_grower
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_GROWER      AND 
            date_buy <= in_date_balance;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_finisher
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_FINISHER    AND 
            date_buy <= in_date_balance;
    
    
    
    IF cur_kg_total_lactating IS NOT NULL THEN 
        IF in_num_lactating IS NOT NULL THEN
            SET cur_consumed_kg_lactating   = CEIL(cur_kg_total_lactating - in_num_lactating * KG_WEIGHT_PER_UNIT_LACTATING);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_lactating; 
        END IF;
    END IF; 
    
    IF cur_kg_total_booster IS NOT NULL THEN 
        IF in_num_booster IS NOT NULL THEN
            SET cur_consumed_kg_booster     = CEIL(cur_kg_total_booster - in_num_booster * KG_WEIGHT_PER_UNIT_BOOSTER);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_booster;
        END IF;
    END IF;
    
    IF cur_kg_total_prestarter IS NOT NULL THEN 
        IF in_num_prestarter IS NOT NULL THEN
            SET cur_consumed_kg_prestarter  = CEIL(cur_kg_total_prestarter - in_num_prestarter * KG_WEIGHT_PER_UNIT_PRESTARTER);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_prestarter;
        END IF;
    END IF;
    
    IF cur_kg_total_starter IS NOT NULL THEN 
        IF in_num_starter IS NOT NULL THEN
            SET cur_consumed_kg_starter     = CEIL(cur_kg_total_starter - in_num_starter * KG_WEIGHT_PER_UNIT_STARTER);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_starter;
        END IF;
    END IF;
    
    IF cur_kg_total_grower IS NOT NULL THEN 
        IF in_num_grower IS NOT NULL THEN
            SET cur_consumed_kg_grower      = CEIL(cur_kg_total_grower - in_num_grower * KG_WEIGHT_PER_UNIT_GROWER);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_grower;
        END IF;
    END IF;
    
    IF cur_kg_total_finisher IS NOT NULL THEN 
        IF in_num_finisher IS NOT NULL THEN
            SET cur_consumed_kg_finisher    = CEIL(cur_kg_total_finisher - in_num_finisher * KG_WEIGHT_PER_UNIT_FINISHER);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_finisher;
        END IF;
    END IF;
    
    
    SET diff_consumed_kg_total = curr_consumed_kg_total - prev_consumed_kg_total;
    
    IF in_num_pigs > 0 THEN 
        SET consumption_per_pig = diff_consumed_kg_total / in_num_pigs;
    END IF;
    
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
    
    
END IF;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_balance_id                 AS feed_balance_id;

END $$

DELIMITER ;
