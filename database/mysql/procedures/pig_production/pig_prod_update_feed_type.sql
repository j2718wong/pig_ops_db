DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_feed_type $$
CREATE PROCEDURE pig_prod_update_feed_type(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_feed_type_id         INT,
    in_date                 VARCHAR(10)
)  

BEGIN

/** 
 * Will update weaning data for pig_production entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 27, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_CANNOT_UPDATE_FEED_TYPE INT            DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;



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


DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        prod_status_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id
        
FROM    pig_production 
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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



IF cur_pig_prod_status_id < PRODUCTION_STATUS_ID_LACTATING THEN 
    SET res_num     = RES_NUM_PIG_PROD_CANNOT_UPDATE_FEED_TYPE;
    SET res_code    = "RES_NUM_PIG_PROD_CANNOT_UPDATE_FEED_TYPE";
    SET res_desc    = "Production status is not yet LACTATING.";
    
    LEAVE process_user;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_BOOSTER THEN 
    UPDATE pig_production SET
        date_booster                = in_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id = in_pig_prod_id;
END IF; 

IF in_feed_type_id = FEED_TYPE_ID_PRESTARTER THEN 
    UPDATE pig_production SET
        date_prestarter             = in_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id = in_pig_prod_id;
END IF; 

IF in_feed_type_id = FEED_TYPE_ID_STARTER THEN 
    UPDATE pig_production SET
        date_starter                = in_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id = in_pig_prod_id;
END IF; 

IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 
    UPDATE pig_production SET
        date_grower                 = in_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id = in_pig_prod_id;
END IF; 

IF in_feed_type_id = FEED_TYPE_ID_FINISHER THEN 
    UPDATE pig_production SET
        date_finisher               = in_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id = in_pig_prod_id;
END IF; 


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_prod_id;
    

END $$

DELIMITER ;
