DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_feed_add $$
CREATE PROCEDURE pig_prod_feed_add(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_pig_farm_feed_buy_id INT,
    
    in_date_add             VARCHAR(10),
    
    
    in_num_gesta            INT,
    in_num_lacta            INT,
    in_num_booster          INT,
    in_num_prestarter       INT,
    in_num_starter          INT,
    in_num_grower           INT,
    in_num_finisher         INT,
    
    
    in_feed_item_gesta_id       INT,
    in_feed_item_lacta_id       INT,
    in_feed_item_booster_id     INT,
    in_feed_item_prestarter_id  INT,
    in_feed_item_starter_id     INT,
    in_feed_item_grower_id      INT,
    in_feed_item_finisher_id    INT
    
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


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_is_active_status                    INT             DEFAULT 0;

DECLARE cur_pig_prod_feed_id                    INT             DEFAULT 0;

DECLARE cur_feed_brand_id                       INT             DEFAULT 0;
DECLARE cur_unit_cost                           DECIMAL(8,2)    DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  account_id,
        pig_prod_status_id
        
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



INSERT INTO pig_prod_feed(
    pig_prod_id,              
    pig_farm_feed_buy_id,
    
    date_add,    
    
    num_gesta,                
    num_lacta,                
    num_booster,              
    num_prestarter,             
    num_starter,              
    num_grower,               
    num_finisher,             
        
    feed_item_gesta_id,   
    feed_item_lacta_id,   
    feed_item_booster_id, 
    feed_item_prestarter_id, 
    feed_item_starter_id, 
    feed_item_grower_id,  
    feed_item_finisher_id,
    
    added_by_user_id         
    
) VALUES (
    in_pig_prod_id,              
    in_pig_farm_feed_buy_id,
    
    in_date_add,    
    
    in_num_gesta,                
    in_num_lacta,                
    in_num_booster,              
    in_num_prestarter,             
    in_num_starter,              
    in_num_grower,               
    in_num_finisher,             
    
    in_feed_item_gesta_id,   
    in_feed_item_lacta_id,   
    in_feed_item_booster_id, 
    in_feed_item_prestarter_id, 
    in_feed_item_starter_id, 
    in_feed_item_grower_id,  
    in_feed_item_finisher_id,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_feed_id;


/* Update pig_prod_feed joined columns because this is expensive operation when  
LEFT OUTER JOIN in SELECT query.*/

IF in_feed_item_gesta_id > 0 THEN 
    SELECT  feed_brand_id,
            unit_cost
    
    INTO    cur_feed_brand_id,
            cur_unit_cost
    
    FROM    pig_farm_feed_buy_item
    WHERE   id = in_feed_item_gesta_id;
    
    UPDATE  pig_prod_feed SET
        feed_brand_gesta_id = cur_feed_brand_id,
        unit_cost_gesta     = cur_unit_cost
    WHERE id = cur_pig_prod_feed_id;
END IF;


IF in_feed_item_lacta_id > 0 THEN 
    SELECT  feed_brand_id,
            unit_cost
    
    INTO    cur_feed_brand_id,
            cur_unit_cost
    
    FROM    pig_farm_feed_buy_item
    WHERE   id = in_feed_item_lacta_id;
    
    UPDATE  pig_prod_feed SET
        feed_brand_lacta_id = cur_feed_brand_id,
        unit_cost_lacta     = cur_unit_cost
    WHERE id = cur_pig_prod_feed_id;
END IF;


IF in_feed_item_booster_id > 0 THEN 
    SELECT  feed_brand_id,
            unit_cost
    
    INTO    cur_feed_brand_id,
            cur_unit_cost
    
    FROM    pig_farm_feed_buy_item
    WHERE   id = in_feed_item_booster_id;
    
    UPDATE  pig_prod_feed SET
        feed_brand_booster_id = cur_feed_brand_id,
        unit_cost_booster     = cur_unit_cost
    WHERE id = cur_pig_prod_feed_id;
END IF;


IF in_feed_item_prestarter_id > 0 THEN 
    SELECT  feed_brand_id,
            unit_cost
    
    INTO    cur_feed_brand_id,
            cur_unit_cost
    
    FROM    pig_farm_feed_buy_item
    WHERE   id = in_feed_item_prestarter_id;
    
    UPDATE  pig_prod_feed SET
        feed_brand_prestarter_id = cur_feed_brand_id,
        unit_cost_prestarter     = cur_unit_cost
    WHERE id = cur_pig_prod_feed_id;
END IF;


IF in_feed_item_starter_id > 0 THEN 
    SELECT  feed_brand_id,
            unit_cost
    
    INTO    cur_feed_brand_id,
            cur_unit_cost
    
    FROM    pig_farm_feed_buy_item
    WHERE   id = in_feed_item_starter_id;
    
    UPDATE  pig_prod_feed SET
        feed_brand_starter_id = cur_feed_brand_id,
        unit_cost_starter     = cur_unit_cost
    WHERE id = cur_pig_prod_feed_id;
END IF;


IF in_feed_item_grower_id > 0 THEN 
    SELECT  feed_brand_id,
            unit_cost
    
    INTO    cur_feed_brand_id,
            cur_unit_cost
    
    FROM    pig_farm_feed_buy_item
    WHERE   id = in_feed_item_grower_id;
    
    UPDATE  pig_prod_feed SET
        feed_brand_grower_id = cur_feed_brand_id,
        unit_cost_grower     = cur_unit_cost
    WHERE id = cur_pig_prod_feed_id;
END IF;


IF in_feed_item_finisher_id > 0 THEN 
    SELECT  feed_brand_id,
            unit_cost
    
    INTO    cur_feed_brand_id,
            cur_unit_cost
    
    FROM    pig_farm_feed_buy_item
    WHERE   id = in_feed_item_finisher_id;
    
    UPDATE  pig_prod_feed SET
        feed_brand_finisher_id = cur_feed_brand_id,
        unit_cost_finisher     = cur_unit_cost
    WHERE id = cur_pig_prod_feed_id;
END IF;


/* Update pig_production bought feeds*/ 

/* Sum up all gestating feeds for pig_production*/

SELECT SUM(num_gesta)
INTO cur_feed_quantity,



END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    cur_pig_prod_feed_id                AS pig_prod_feed_id;

END $$

DELIMITER ;
