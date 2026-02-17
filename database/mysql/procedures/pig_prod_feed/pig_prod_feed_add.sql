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
