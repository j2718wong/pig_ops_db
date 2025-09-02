DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_feed_buy_update $$
CREATE PROCEDURE pig_prod_feed_buy_update(
    in_user_id              INT,
    in_pig_prod_feed_buy_id INT,
    
    in_date_buy             VARCHAR(10),
    in_feed_type_id         INT,
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    quantity                INT,
    kg_per_qty              DECIMAL(5,1),
    
    unit_cost               DECIMAL(8,2),
    total_cost              DECIMAL(8,2)
)  

BEGIN

/** 
 * Will update pig_prod_feed_buy entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 31, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_FEED_BUY       INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status                     INT             DEFAULT 0;

DECLARE cur_feed_quantity_lactating             INT             DEFAULT 0;
DECLARE cur_feed_quantity_booster               INT             DEFAULT 0;
DECLARE cur_feed_quantity_prestarter            INT             DEFAULT 0;
DECLARE cur_feed_quantity_starter               INT             DEFAULT 0;
DECLARE cur_feed_quantity_grower                INT             DEFAULT 0;
DECLARE cur_feed_quantity_finisher              INT             DEFAULT 0;


DECLARE cur_feed_cost_lactating                 DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_feed_cost_booster                   DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_feed_cost_prestarter                DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_feed_cost_starter                   DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_feed_cost_grower                    DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_feed_cost_finisher                  DECIMAL(8,2)    DEFAULT 0;




DECLARE cur_pig_prod_feed_buy_id                    INT             DEFAULT 0;
DECLARE cur_pig_prod_feed_buy_flag                  INT             DEFAULT 0;
DECLARE cur_pig_prod_feed_buy_name                  VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT 
    b.account_id,
    b.status

INTO
    cur_pig_prod_account_id,
    cur_pig_prod_status

FROM pig_prod_feed_buy a 
LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id 
WHERE a.id = in_pig_prod_feed_buy_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_FEED_BUY,
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



UPDATE pig_prod_feed_buy  SET
    date_buy            = in_date_buy,
    
    feed_type_id        = in_feed_type_id,
    feed_brand_id       = in_feed_brand_id,
    feed_supplier_id    = in_feed_supplier_id,
    
    quantity            = in_quantity,
    kg_per_qty          = in_kg_per_qty,
    kg_total            = in_quantity * in_kg_per_qty,
    
    unit_cost           = in_unit_cost,
    feed_cost           = in_feed_cost,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_pig_prod_feed_buy_id;



/* It is difficult to know which feed is updated; so update all;*/
SELECT  SUM(quantity),
        SUM(feed_cost)
INTO    cur_feed_quantity_lactating,
        cur_feed_cost_lactating
FROM    pig_prod_feed_buy
WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_LACTATING;
    
    
SELECT  SUM(quantity),
        SUM(feed_cost)
INTO    cur_feed_quantity_booster,
        cur_feed_cost_booster
FROM    pig_prod_feed_buy
WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_BOOSTER;
    
    
SELECT  SUM(quantity),
        SUM(feed_cost)
INTO    cur_feed_quantity_prestarter,
        cur_feed_cost_prestarter
FROM    pig_prod_feed_buy
WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_PRESTARTER;
    

SELECT  SUM(quantity),
        SUM(feed_cost)
INTO    cur_feed_quantity_starter,
        cur_feed_cost_starter
FROM    pig_prod_feed_buy
WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_STARTER;


SELECT  SUM(quantity),
        SUM(feed_cost)
INTO    cur_feed_quantity_grower,
        cur_feed_cost_grower
FROM    pig_prod_feed_buy
WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_GROWER;


SELECT  SUM(quantity),
        SUM(feed_cost)
INTO    cur_feed_quantity_finisher,
        cur_feed_cost_finisher
FROM    pig_prod_feed_buy
WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = FEED_TYPE_ID_FINISHER;

    
    
UPDATE pig_production SET 
    num_b_lactating     = cur_feed_quantity_lactating,
    num_b_booster       = cur_feed_quantity_booster,
    num_b_prestarter    = cur_feed_quantity_prestarter,
    num_b_starter       = cur_feed_quantity_starter,
    num_b_grower        = cur_feed_quantity_grower,
    num_b_finisher      = cur_feed_quantity_finisher,
    
    cost_lactating      = cur_feed_cost_lactating,
    cost_booster        = cur_feed_cost_booster,
    cost_prestarter     = cur_feed_cost_prestarter,
    cost_starter        = cur_feed_cost_starter,
    cost_grower         = cur_feed_cost_grower,
    cost_finisher       = cur_feed_cost_finisher,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_pig_prod_id;



END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_feed_buy_id                 AS pig_prod_feed_buy_id;

END $$

DELIMITER ;
