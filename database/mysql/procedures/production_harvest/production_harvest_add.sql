DELIMITER $$

DROP PROCEDURE IF EXISTS production_harvest_add $$
CREATE PROCEDURE production_harvest_add(
    in_user_id              INT,
    in_pig_prod_id          INT,
    in_production_group_id  INT,
    in_acc_pig_buyer_id     INT,
    
    in_date_harvest         VARCHAR(10),
    
    in_num_pigs_harvest     INT,
    
    in_live_weight          DECIMAL(6,1),
    in_slaughter_weight     DECIMAL(6,1),
    in_slaughter_net_weight DECIMAL(6,1),
    
    in_live_price_per_unit          DECIMAL(6,1),
    in_slaughther_price_per_unit    DECIMAL(6,1),
    
    in_net_sales            DECIMAL(8,1),
    in_harvest_cost         DECIMAL(5,1),
    in_cost_comments        VARCHAR(160)
)  

BEGIN

/** 
 * Will add pig_prod_harvest entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 4, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_HARVEST_ENTRY_NOT_ALLOWED       INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;

DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;
DECLARE cur_num_pigs_harvest                    INT             DEFAULT 0;
DECLARE cur_num_dead_pigs                       INT             DEFAULT 0;
DECLARE cur_num_pigs_current                    INT             DEFAULT 0;

DECLARE cur_production_harvest_id               INT             DEFAULT 0;


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
    SELECT 
        account_id,
        prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM production_group 
    WHERE id = in_pig_prod_group_id;

END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_HARVEST,
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
IF in_pig_prod_id > 0 THEN 
    SELECT  id
    INTO    cur_production_harvest_id
    FROM    production_harvest
    WHERE   pig_prod_id         = in_pig_prod_id    AND
            date_harvest        = in_date_harvest
    LIMIT   1;
    
ELSE
    SELECT  id
    INTO    cur_production_harvest_id
    FROM    production_harvest
    WHERE   pig_prod_group_id   = in_pig_prod_group_id    AND
            date_harvest        = in_date_harvest
    LIMIT   1;
    
END IF;

IF cur_production_harvest_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


IF in_pig_prod_id > 0 THEN 
    IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_WEANING, 
                                        PRODUCTION_STATUS_ID_GROWING) THEN
        SET res_num     = RES_NUM_HARVEST_ENTRY_NOT_ALLOWED;
        SET res_code    = "RES_NUM_HARVEST_ENTRY_NOT_ALLOWED";
        SET res_desc    = "Production status not WEANING or GROWING.";
    
        LEAVE process_user;
    
    END IF;
END IF;


INSERT INTO production_harvest(
    account_id,

    pig_prod_id,
    production_group_id,
    acc_pig_buyer_id,
    
    date_harvest,
    
    num_pigs_harvest,
    
    live_weight,
    slaughter_weight,
    slaughter_net_weight,
    
    live_price_per_unit,
    slaughter_price_per_unit,
    
    net_sales,
    harvest_cost,
    cost_comments,

    added_by_user_id
    
) VALUES (
    cur_pig_prod_account_id,

    in_pig_prod_id,
    in_production_group_id,
    in_acc_pig_buyer_id,
    
    in_date_harvest,
    
    in_num_pigs_harvest,
    
    in_live_weight,
    in_slaughter_weight,
    in_slaughter_net_weight,
    
    in_live_price_per_unit,
    in_slaughther_price_per_unit,
    
    in_net_sales,
    in_harvest_cost,
    in_cost_comments,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_production_harvest_id;


IF in_pig_prod_id > 0 THEN 
    SELECT  num_pigs_weaning_m + num_pigs_weaning_f
    INTO    cur_num_pigs_weaning
    FROM    pig_production 
    WHERE   id = in_pig_prod_id;
    
    
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    production_harvest
    WHERE   pig_prod_id = in_pig_prod_id;
    
   
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   pig_prod_id = in_pig_prod_id AND dead_at_stage = DEAD_AT_STAGE_GROWING;
    
    SET cur_num_pigs_current = cur_num_pigs_weaning - cur_num_pigs_harvest;
    
    IF cur_num_dead_pigs > 0 THEN 
        SET cur_num_pigs_current = cur_num_pigs_current - cur_num_dead_pigs;
    END IF;
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    IF cur_num_pigs_current > 0 THEN 
        UPDATE  pig_production SET
            num_pigs_current = cur_num_pigs_current
        WHERE id = in_pig_prod_id;
    ELSE
        
        UPDATE  pig_production SET
            num_pigs_current = 0,
            prod_status_id = PRODUCTION_STATUS_ID_HARVESTED
        WHERE id = in_pig_prod_id;
    END IF;

    
ELSE
    /*TODO for production_group*/
    
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    pig_prod_harvest
    WHERE   pig_prod_group_id = in_pig_prod_group_id;
    
    
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   pig_prod_group_id = in_pig_prod_group_id AND dead_at_stage = DEAD_AT_STAGE_GROWING;
    
END IF;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_production_harvest_id           AS pig_prod_harvest_id;

END $$

DELIMITER ;
