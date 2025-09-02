DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_feed_buy_add $$
CREATE PROCEDURE pig_prod_feed_buy_add(
    in_user_id              INT,
    in_pig_prod_id          INT,
    
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
 * Will add pig_prod_feed_buy entry.
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

DECLARE cur_feed_quantity                       INT             DEFAULT 0;
DECLARE cur_feed_cost                           DECIMAL(8,2)    DEFAULT 0;



DECLARE cur_pig_prod_feed_buy_id                    INT             DEFAULT 0;
DECLARE cur_prod_feed_buy_flag                  INT             DEFAULT 0;
DECLARE cur_prod_feed_buy_name                  VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT 
    account_id,
    status

INTO
    cur_pig_prod_account_id,
    cur_pig_prod_status

FROM pig_production 
WHERE id = in_pig_prod_id;


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
        date_buy            = in_date_buy       AND
        feed_type_id        = in_feed_type_id
LIMIT   1;

IF cur_pig_prod_feed_buy_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO pig_prod_feed_buy(
    pig_prod_id,
    
    date_buy,
    
    feed_type_id,
    feed_brand_id,
    feed_supplier_id,
    
    quantity,
    kg_per_qty,
    kg_total,
    
    unit_cost,
    feed_cost,
    
    added_by_user_id
) VALUES (
    in_pig_prod_id,
    
    in_date_buy,
    
    in_feed_type_id,
    in_feed_brand_id,
    in_feed_supplier_id,
    
    in_quantity,
    in_kg_per_qty,
    in_quantity * in_kg_per_qty,
    
    in_unit_cost,
    in_total_cost
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_feed_buy_id;


IF in_feed_type_id = FEED_TYPE_ID_LACTATING THEN 
    SELECT  SUM(quantity),
            SUM(feed_cost)
    INTO    cur_feed_quantity,
            cur_feed_cost
    FROM    pig_prod_feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = in_feed_type_id;
    
    
    UPDATE pig_production SET 
        num_b_lactating     = cur_feed_quantity,
        cost_lactating      = cur_feed_cost
    WHERE id = in_pig_prod_id;
    
END IF;


IF in_feed_type_id = FEED_TYPE_ID_BOOSTER THEN 
    SELECT  SUM(quantity),
            SUM(feed_cost)
    INTO    cur_feed_quantity,
            cur_feed_cost
    FROM    pig_prod_feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = in_feed_type_id;
    
    UPDATE pig_production SET 
        num_b_booster       = cur_feed_quantity,
        cost_booster        = cur_feed_cost
    WHERE id = in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_PRESTARTER THEN 
    SELECT  SUM(quantity),
            SUM(feed_cost)
    INTO    cur_feed_quantity,
            cur_feed_cost
    FROM    pig_prod_feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = in_feed_type_id;
    
    UPDATE pig_production SET 
        num_b_prestarter    = cur_feed_quantity,
        cost_prestarter     = cur_feed_cost
    WHERE id = in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_STARTER THEN 
    SELECT  SUM(quantity),
            SUM(feed_cost)
    INTO    cur_feed_quantity,
            cur_feed_cost
    FROM    pig_prod_feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = in_feed_type_id;
    
    UPDATE pig_production SET 
        num_b_starter       = cur_feed_quantity,
        cost_starter        = cur_feed_cost
    WHERE id = in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 
    SELECT  SUM(quantity),
            SUM(feed_cost)
    INTO    cur_feed_quantity,
            cur_feed_cost
    FROM    pig_prod_feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = in_feed_type_id;
    
    UPDATE pig_production SET 
        num_b_grower        = cur_feed_quantity,
        cost_grower         = cur_feed_cost
    WHERE id = in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_FINISHER THEN 
    SELECT  SUM(quantity),
            SUM(feed_cost)
    INTO    cur_feed_quantity,
            cur_feed_cost
    FROM    pig_prod_feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = in_feed_type_id;
    
    UPDATE pig_production SET 
        num_b_finisher      = cur_feed_quantity,
        cost_finisher       = cur_feed_finisher
    WHERE id = in_pig_prod_id;
END IF;



END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_feed_buy_id            AS prod_feed_buy_id;

END $$

DELIMITER ;
