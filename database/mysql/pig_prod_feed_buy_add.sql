DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_feed_buy_add $$
CREATE PROCEDURE pig_prod_feed_buy_add(
    in_user_id              INT,

    in_pig_prod_id          INT,
    
    in_date                 VARCHAR(10),
    
    in_feed_type_id         INT,
    
    in_quantity             INT,
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    in_kg_per_unit          INT,
    in_cost_per_unit        DECIMAL(6,1),
    in_cost_total           DECIMAL(6,1)
    
)  

BEGIN

/** 
 * Will add pig_prod_feed_buy entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 25, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_FEED_BUY      INT             	DEFAULT 20;


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

DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_last_feed_balance     DATE            DEFAULT NULL;

DECLARE cur_pig_prod_num_b_lactating            INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_booster              INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_prestarter           INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_starter              INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_grower               INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_finisher             INT             DEFAULT NULL;

DECLARE cur_pig_prod_num_l_lactating            DECIMAL(5,1)    DEFAULT NULL;
DECLARE cur_pig_prod_num_l_booster              DECIMAL(5,1)    DEFAULT NULL;
DECLARE cur_pig_prod_num_l_prestarter           DECIMAL(5,1)    DEFAULT NULL;
DECLARE cur_pig_prod_num_l_starter              DECIMAL(5,1)    DEFAULT NULL;
DECLARE cur_pig_prod_num_l_grower               DECIMAL(5,1)    DEFAULT NULL;
DECLARE cur_pig_prod_num_l_finisher             DECIMAL(5,1)    DEFAULT NULL;

DECLARE cur_pig_prod_cost_lactating             DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_booster               DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_prestarter            DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_starter               DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_grower                DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_finisher              DECIMAL(10,2)   DEFAULT NULL;
    



DECLARE cur_pig_prod_feed_buy_id                    INT             DEFAULT 0;
DECLARE cur_pig_prod_feed_buy_flag                  INT             DEFAULT 0;
DECLARE cur_pig_prod_feed_buy_name                  VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_prod_account_id
FROM    pig_production
WHERE   id = in_pig_prod_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_FEED_BUY,
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
INTO    cur_pig_prod_feed_buy_id
FROM    pig_prod_feed_buy
WHERE   pig_prod_id         = in_pig_prod_id    AND
        date                = in_date           AND
        feed_type_id        =in_feed_type_id
LIMIT   1;

IF cur_pig_prod_feed_buy_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


SELECT
    status_id,
    date_last_feed_balance,

    num_b_lactating,
    num_b_booster,
    num_b_prestarter,
    num_b_starter,
    num_b_grower,
    num_b_finisher,
    num_l_lactating,
    num_l_booster,
    num_l_prestarter,
    num_l_starter,
    num_l_grower,
    num_l_finisher,
    cost_lactating,
    cost_booster,
    cost_prestarter,
    cost_starter,
    cost_grower,
    cost_finisher
    
INTO
    cur_pig_prod_status_id,
    cur_pig_prod_date_last_feed_balance,

    cur_pig_prod_num_b_lactating,
    cur_pig_prod_num_b_booster,
    cur_pig_prod_num_b_prestarter,
    cur_pig_prod_num_b_starter,
    cur_pig_prod_num_b_grower,
    cur_pig_prod_num_b_finisher,
    
    cur_pig_prod_num_l_lactating,
    cur_pig_prod_num_l_booster,
    cur_pig_prod_num_l_prestarter,
    cur_pig_prod_num_l_starter,
    cur_pig_prod_num_l_grower,
    cur_pig_prod_num_l_finisher,
    
    cur_pig_prod_cost_lactating,
    cur_pig_prod_cost_booster,
    cur_pig_prod_cost_prestarter,
    cur_pig_prod_cost_starter,
    cur_pig_prod_cost_grower,
    cur_pig_prod_cost_finisher
    
FROM pig_production
WHERE id = in_pig_prod_id;
  



INSERT INTO pig_prod_feed_buy(
    pig_prod_id,
    
    date,
    feed_type_id,
    
    quantity,
    feed_brand_id,
    feed_supplier_id,
    kg_per_unit,
    cost_per_unit,
    cost_total,

    added_by_user_id
) VALUES (
    in_pig_prod_id,
    
    in_date,
    in_feed_type_id,
    
    in_quantity,
    in_feed_brand_id,
    in_feed_supplier_id,
    in_kg_per_unit,
    in_cost_per_unit,
    in_cost_total,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_feed_buy_id;


/* If no feed_buy yet, set date_last_feed_balance to CUR_DATE*/
IF  cur_pig_prod_date_last_feed_balance IS NULL THEN
    UPDATE pig_production SET 
        date_last_feed_balance = CURRENT_DATE
    WHERE id = in_pig_prod_id;
END IF;;


IF in_feed_type_id = FEED_TYPE_ID_LACTATING THEN 
    IF cur_pig_prod_num_b_lactating IS NULL THEN 
        UPDATE pig_production SET 
            num_b_lactating     = in_quantity,
            num_l_lactating     = in_quantity,
            cost_lactating      = in_cost_total
        WHERE id = in_pig_prod_id;
        
    ELSE
        UPDATE pig_production SET 
            num_b_lactating     = num_b_lactating + in_quantity,
            cost_lactating      = cost_lactating + in_cost_total
        WHERE id = in_pig_prod_id;
    END IF;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_BOOSTER THEN 
    IF cur_pig_prod_num_b_booster IS NULL THEN 
        UPDATE pig_production SET 
            num_b_booster       = in_quantity,
            num_l_booster       = in_quantity,
            cost_booster        = in_cost_total
        WHERE id = in_pig_prod_id;
        
    ELSE
        UPDATE pig_production SET 
            num_b_booster       = num_b_booster + in_quantity,
            cost_booster        = cost_booster + in_cost_total
        WHERE id = in_pig_prod_id;
        
    END IF;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_PRESTARTER THEN 
    IF cur_pig_prod_num_b_prestarter IS NULL THEN 
        UPDATE pig_production SET 
            num_b_prestarter    = in_quantity,
            num_l_prestarter    = in_quantity,
            cost_prestarter     = in_cost_total
        WHERE id = in_pig_prod_id;
        
    ELSE
        UPDATE pig_production SET 
            num_b_prestarter    = num_b_prestarter + in_quantity,
            cost_prestarter     = cost_prestarter + in_cost_total
        WHERE id = in_pig_prod_id;
    END IF;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_STARTER THEN 
    IF cur_pig_prod_num_b_starter IS NULL THEN 
        UPDATE pig_production SET 
            num_b_starter       = in_quantity,
            num_l_starter       = in_quantity,
            cost_starter        = in_cost_total
        WHERE id = in_pig_prod_id;
        
    ELSE
        UPDATE pig_production SET 
            num_b_starter       = num_b_starter + in_quantity,
            cost_starter        = cost_starter + in_cost_total
        WHERE id = in_pig_prod_id;
    END IF;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 
    IF cur_pig_prod_num_b_grower IS NULL THEN 
        UPDATE pig_production SET 
            num_b_grower        = in_quantity,
            num_l_grower        = in_quantity,
            cost_grower         = in_cost_total
        WHERE id = in_pig_prod_id;
        
    ELSE
        UPDATE pig_production SET 
            num_b_grower        = num_b_grower + in_quantity,
            cost_grower         = cost_grower + in_cost_total
        WHERE id = in_pig_prod_id;
    END IF;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_FINISHER THEN 
    IF cur_pig_prod_num_b_finisher IS NULL THEN 
        UPDATE pig_production SET 
            num_b_finisher      = in_quantity,
            num_l_finisher      = in_quantity,
            cost_finisher       = in_cost_total
        WHERE id = in_pig_prod_id;
        
    ELSE
        UPDATE pig_production SET 
            num_b_finisher      = num_b_finisher + in_quantity,
            cost_finisher       = cost_finisher + in_cost_total
        WHERE id = in_pig_prod_id;
    END IF;
END IF;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_feed_buy_id            AS pig_prod_feed_buy_id;

END $$

DELIMITER ;
