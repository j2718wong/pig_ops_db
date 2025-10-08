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


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_feed_buy_id                      AS feed_buy_id;

END $$

DELIMITER ;
