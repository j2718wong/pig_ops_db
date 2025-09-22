DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_add_add $$
CREATE PROCEDURE pig_prod_pig_add_add(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_production_group_id  INT,
    
    in_date_added           VARCHAR(10)
    in_num_pigs_added       INT,
    
    in_comments             VARCHAR(160)
)  

BEGIN

/** 
 * Will add pigs (which is assumed to be external) to a pig_production OR
 * production_group entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 21, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_CANNOT_ADD_PIG    INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_ADD        INT             DEFAULT 27;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE PRODUCTION_GROUP_STATUS_ID_GROWING      INT             DEFAULT 1;
DECLARE PRODUCTION_GROUP_STATUS_ID_HARVESTED    INT             DEFAULT 2;
DECLARE PRODUCTION_GROUP_STATUS_ID_CLOSED       INT             DEFAULT 3;


DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_weaning               DATE            DEFAULT NULL;


DECLARE cur_num_pigs_current                    INT             DEFAULT 0;



DECLARE cur_dead_at_stage                       INT             DEFAULT 0;

DECLARE cur_pig_prod_pig_add_id                INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
     /* pig_production */
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    pig_production 
    WHERE   id = in_pig_prod_id;

ELSE
    /* production_group */
    SELECT  
            account_id,
            pig_farm_id,
            prod_group_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    production_group 
    WHERE   id = in_production_group_id;


END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_ADD,
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


/* Check production status*/
IF in_pig_prod_id > 0 THEN 
    /* pig_production */
    
    IF cur_pig_prod_status_id IN (  PRODUCTION_STATUS_ID_CLOSED,
                                    PRODUCTION_STATUS_ID_HARVESTED) THEN 
        SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
        SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
        SET res_desc    = "Production status already HARVESTED or CLOSED.";
    
        LEAVE process_user;
    END IF;

    IF  cur_pig_prod_status_id < PRODUCTION_STATUS_ID_LACTATING THEN 
        
        SET res_num     = RES_NUM_PIG_PROD_CANNOT_ADD_PIG;
        SET res_code    = "RES_NUM_PIG_PROD_CANNOT_ADD_PIG";
        SET res_desc    = "No pigs yet";
        
        LEAVE process_user;
    END IF;

ELSE
    /* production_group */
    IF cur_pig_prod_status_id != PRODUCTION_GROUP_STATUS_ID_GROWING THEN
        SET res_num     = RES_NUM_PIG_PROD_CANNOT_ADD_PIG;
        SET res_code    = "RES_NUM_PIG_PROD_CANNOT_ADD_PIG";
        SET res_desc    = "Production group status not GROWING.";
    
        LEAVE process_user;
    
    END IF;
    
    
END IF;


INSERT INTO pig_prod_pig_add (
    account_id,
    pig_farm_id,
    pig_prod_id,
    production_group_id,
    
    date_added,
    num_pigs_added,
    comments,
    
    added_by_user_id
    
) VALUES (
    cur_user_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    in_production_group_id,
    
    in_date_added,
    in_num_pigs_added,
    in_comments,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_pig_add_id;


/* Calculate current number of pigs.*/
IF in_pig_prod_id > 0 THEN 
    CALL production_calculate_current_pigs(in_pig_prod_id, 0, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    UPDATE  pig_production SET
        num_pigs_current = cur_num_pigs_current
    WHERE id = in_pig_prod_id;

ELSE
    CALL production_calculate_current_pigs(0, in_production_group_id, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    UPDATE  production_group SET
        num_pigs_current = cur_num_pigs_current
    WHERE id = in_production_group_id;
    
END IF;



END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_pig_add_id             AS pig_prod_pig_add_id;
    

END $$

DELIMITER ;
