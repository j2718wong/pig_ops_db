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


DECLARE cur_feed_buy_id                    INT             DEFAULT 0;

DECLARE cur_feed_buy_total_cost                 DECIMAL(10,2)   DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.pig_farm_feed_buy_id,
        b.account_id 

INTO    cur_pig_farm_feed_buy_id,
        cur_pig_farm_feed_buy_account_id
        
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



END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_buy_id                     AS feed_buy_id;

END $$

DELIMITER ;
