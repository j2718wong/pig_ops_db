DELIMITER $$

DROP PROCEDURE IF EXISTS production_harvest_update $$
CREATE PROCEDURE production_harvest_update(
    in_user_id              INT,
    
    in_production_harvest_id INT,
    
    in_date_harvest         VARCHAR(10),
    
    in_num_pigs_harvest     INT,
    in_harvest_type_id      INT,
    
    in_live_weight          DECIMAL(6,1),
    in_slaughter_weight     DECIMAL(6,1),
    in_slaughter_net_weight DECIMAL(6,1),
    
    in_live_price_per_unit          DECIMAL(6,1),
    in_slaughther_price_per_unit    DECIMAL(6,1),
    
    in_net_sales            DECIMAL(8,1),
    in_harvest_cost         DECIMAL(5,1),
    in_comments             VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_harvest entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 18, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;


DECLARE PRODUCTION_GROUP_STATUS_ID_GROWING      INT             DEFAULT 1;
DECLARE PRODUCTION_GROUP_STATUS_ID_HARVESTED    INT             DEFAULT 2;
DECLARE PRODUCTION_GROUP_STATUS_ID_CLOSED       INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_production_harvest_account_id       INT             DEFAULT 0;
DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_production_group_id                 INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;

DECLARE cur_num_days_since_birth                INT             DEFAULT NULL;

DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;
DECLARE cur_num_pigs_harvest                    INT             DEFAULT 0;
DECLARE cur_num_dead_pigs                       INT             DEFAULT 0;
DECLARE cur_num_pigs_current                    INT             DEFAULT 0;

DECLARE cur_pig_prod_harvest_id                 INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT 
    account_id,
    pig_prod_id,
    production_group_id
INTO
    cur_production_harvest_account_id,
    cur_pig_prod_id,
    cur_production_group_id

FROM production_harvest 
WHERE id = in_production_harvest_id;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_production_harvest_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_HARVEST,
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


/* Check production status*/
IF in_pig_prod_id > 0 THEN 
    /* pig_production */
    IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_WEANING, 
                                        PRODUCTION_STATUS_ID_GROWING) THEN
        SET res_num     = RES_NUM_HARVEST_ENTRY_NOT_ALLOWED;
        SET res_code    = "RES_NUM_HARVEST_ENTRY_NOT_ALLOWED";
        SET res_desc    = "Production status not WEANING or GROWING.";
    
        LEAVE process_user;
    
    END IF;

ELSE 
    /* production_group */
    IF cur_pig_prod_status_id != PRODUCTION_GROUP_STATUS_ID_GROWING THEN
        SET res_num     = RES_NUM_HARVEST_ENTRY_NOT_ALLOWED;
        SET res_code    = "RES_NUM_HARVEST_ENTRY_NOT_ALLOWED";
        SET res_desc    = "Production group status not GROWING.";
    
        LEAVE process_user;
    
    END IF;
    
END IF;


IF cur_pig_prod_id > 0 THEN 
    SELECT  date_actual_birth
    INTO    cur_pig_prod_date_actual_birth
    FROM    pig_production
    WHERE   id = cur_pig_prod_id;
    
    
    IF cur_pig_prod_date_actual_birth IS NOT NULL THEN 
        SET cur_num_days_since_birth = DATEDIFF(in_date_harvest, 
                cur_pig_prod_date_actual_birth); 
    ELSE
        SET cur_num_days_since_birth = NULL;
    END IF;

END IF;


UPDATE pig_prod_harvest SET
    date_harvest        = in_date_harvest,
    num_days_since_birth= cur_num_days_since_birth,
    
    num_pigs_harvest    = in_num_pigs_harvest,
    harvest_type_id     = in_harvest_type_id,
    
    live_weight         = in_live_weight,
    slaughter_weight    = in_slaughter_weight,
    slaughter_net_weight = in_slaughter_net_weight,
    
    live_price_per_unit     = in_live_price_per_unit,
    slaughter_price_per_unit = in_slaughter_price_per_unit,
    
    net_sales           = in_net_sales,
    harvest_cost        = in_harvest_cost,
    comments            = in_comments,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_production_harvest_id;


/* Calculate current number of pigs.*/
IF cur_pig_prod_id > 0 THEN 
    CALL production_calculate_current_pigs(cur_pig_prod_id, 0, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    IF cur_num_pigs_current > 0 THEN 
        UPDATE  pig_production SET
            num_pigs_current = cur_num_pigs_current
        WHERE id = cur_pig_prod_id;
    ELSE
        
        UPDATE  pig_production SET
            num_pigs_current = 0,
            prod_status_id = PRODUCTION_STATUS_ID_HARVESTED
        WHERE id = cur_pig_prod_id;
    END IF;

ELSE
    CALL production_calculate_current_pigs(0, in_production_group_id, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    IF cur_num_pigs_current > 0 THEN 
        UPDATE  production_group SET
            num_pigs_current = cur_num_pigs_current
        WHERE id = in_production_group_id;
    ELSE
        
        UPDATE  production_group SET
            num_pigs_current = 0,
            prod_status_id = PRODUCTION_GROUP_STATUS_ID_HARVESTED
        WHERE id = in_production_group_id;
    END IF;
    
END IF;





END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_harvest_id             AS pig_prod_harvest_id;

END $$

DELIMITER ;
