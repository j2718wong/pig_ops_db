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
