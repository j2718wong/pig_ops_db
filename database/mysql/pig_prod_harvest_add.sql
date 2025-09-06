DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_harvest_add $$
CREATE PROCEDURE pig_prod_harvest_add(
    in_user_id              INT,
    in_pig_prod_id          INT,
    in_pig_prod_group_id    INT,
    
    in_date_harvest         VARCHAR(10),
    
    in_num_pigs_harvest     INT,
    in_live_weight          INT,
    in_slaugther_weight     INT
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


DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;

DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

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


IF in_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        status

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status

    FROM pig_production 
    WHERE id = in_pig_prod_id;

ELSE
    SELECT 
        account_id,
        status

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production_group 
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
    INTO    cur_pig_prod_harvest_id
    FROM    pig_prod_harvest
    WHERE   pig_prod_id         = in_pig_prod_id    AND
            date_harvest        = in_date_harvest
    LIMIT   1;
    
ELSE
    SELECT  id
    INTO    cur_pig_prod_harvest_id
    FROM    pig_prod_harvest
    WHERE   pig_prod_group_id   = in_pig_prod_group_id    AND
            date_harvest        = in_date_harvest
    LIMIT   1;
    
END IF;

IF cur_pig_prod_harvest_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


INSERT INTO pig_prod_harvest(
    pig_prod_id,
    pig_prod_group_id,
    
    date_harvest,
    
    num_pigs_harvest,
    
    live_weight,
    slaugther_weight

    added_by_user_id
) VALUES (
    in_pig_prod_id,
    in_pig_prod_group_id,
    
    in_date_harvest,
    
    in_num_pigs,
    
    in_live_weight,
    in_slaugther_weight,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_harvest_id;


IF in_pig_prod_id > 0 THEN 
    SELECT  num_pigs_weaning_m + num_pigs_weaning_f
    INTO    cur_num_pigs_weaning
    FROM    pig_production 
    WHERE   id = in_pig_prod_id;
    
    
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    pig_prod_harvest
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
        WHERE id = in_pig_prod_id;
    ELSE
        
        UPDATE  pig_production SET
            num_pigs_current = 0,
            pig_prod_status_id = PRODUCTION_STATUS_ID_HARVESTED
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
    
    cur_pig_prod_harvest_id            AS pig_prod_harvest_id;

END $$

DELIMITER ;
