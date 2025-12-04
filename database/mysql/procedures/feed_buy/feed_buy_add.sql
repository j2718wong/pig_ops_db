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



END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_buy_id                     AS feed_buy_id;

END $$

DELIMITER ;