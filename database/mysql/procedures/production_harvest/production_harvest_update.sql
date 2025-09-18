DELIMITER $$

DROP PROCEDURE IF EXISTS production_harvest_update $$
CREATE PROCEDURE production_harvest_update(
    in_user_id              INT,
    
    in_production_harvest_id INT,
    
    in_date_harvest         VARCHAR(10),
    
    in_num_pigs_harvest     INT,
    in_live_weight          INT,
    in_slaugther_weight     INT,
    
    in_sales                DECIMAL(8,1),
    in_harvest_cost         DECIMAL(5,1),
    in_cost_comments        VARCHAR(160)
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


DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;

DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE PRODUCTION_GRP_STATUS_ID_GROWING        INT             DEFAULT 1;
DECLARE PRODUCTION_GRP_STATUS_ID_HARVESTED      INT             DEFAULT 2;
DECLARE PRODUCTION_GRP_STATUS_ID_CLOSED         INT             DEFAULT 3;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_production_harvest_account_id       INT             DEFAULT 0;
DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_production_group_id                 INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


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


IF cur_pig_prod_id > 0 THEN 
    SELECT  prod_status_id
    INTO    cur_pig_prod_status_id
    FROM    pig_production
    WHERE   id = cur_pig_prod_id;
    
    IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
        SET res_num     = RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED;
        SET res_code    = "RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED";
        
        LEAVE process_user;
    END IF;
    
END IF;

IF cur_production_group_id > 0 THEN
    SELECT  prod_status_id
    INTO    cur_pig_prod_status_id
    FROM    production_status
    WHERE   id = cur_production_group_id;
    
    IF cur_pig_prod_status_id = PRODUCTION_GRP_STATUS_ID_CLOSED THEN 
        SET res_num     = RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED;
        SET res_code    = "RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED";
        
        LEAVE process_user;
    END IF;

END IF;


UPDATE pig_prod_harvest SET
    date_harvest        = in_date_harvest,
    
    num_pigs_harvest    = in_num_pigs_harvest,
    
    live_weight         = in_live_weight,
    slaugther_weight    = in_slaugther_weight,
    
    sales               = in_sales,
    harvest_cost        = in_harvest_cost,
    cost_comments       = in_cost_comments,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_production_harvest_id;


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
    
    
    SET cur_num_pigs_current = cur_num_pigs_weaning - cur_num_pigs_harvest - cur_num_dead_pigs;
    
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
            pig_prod_status_id = PRODUCTION_STATUS_ID_HARVESTED
        WHERE id = cur_pig_prod_id;
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
    
    cur_pig_prod_harvest_id             AS pig_prod_harvest_id;

END $$

DELIMITER ;
