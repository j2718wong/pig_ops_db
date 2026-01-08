DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_feed_start_date $$
CREATE PROCEDURE pig_prod_update_feed_start_date(
    in_user_id                  INT,
    
    in_pig_prod_id              INT,
    in_feed_type_id             INT,
    in_feed_start_date          VARCHAR(10)  /* in YYYY-MM-DD format*/
)

BEGIN

/** 
 * Will update pig_production feed start date.
 * @author Jack Wong
 * @since December 4, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_UPDATE_FEED_START_DATE_NOT_ALLOWED INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE FEED_TYPE_ID_GESTATING                  INT             DEFAULT 1;
DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                	INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;





DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS              INT             DEFAULT 4;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;

DECLARE cur_account_flag_settings               INT             DEFAULT 0;

DECLARE cur_count_account_pig_ops               INT             DEFAULT 0;
DECLARE cur_count_pig_prod_pig_ops              INT             DEFAULT 0;

DECLARE num_days_to_add                         INT             DEFAULT 0;

DECLARE date_temp                               DATE            DEFAULT NULL;
DECLARE detected_actual_date_birth_change       INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        prod_status_id
INTO    
        cur_pig_prod_account_id,
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


IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_GESTATING,
                                    PRODUCTION_STATUS_ID_LACTATING,
                                    PRODUCTION_STATUS_ID_WEANING,
                                    PRODUCTION_STATUS_ID_GROWING,
                                    PRODUCTION_STATUS_ID_COMBINED) THEN 
    SET res_num     = RES_NUM_UPDATE_FEED_START_DATE_NOT_ALLOWED;
    SET res_code    = "RES_NUM_UPDATE_FEED_START_DATE_NOT_ALLOWED";

    LEAVE process_user;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_GESTATING THEN 

    UPDATE pig_production SET 
        date_gestating              = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_LACTATING THEN 

    UPDATE pig_production SET 
        date_lactating              = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_BOOSTER THEN 

    UPDATE pig_production SET 
        date_booster                = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_PRESTARTER THEN 

    UPDATE pig_production SET 
        date_prestarter             = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_STARTER THEN 

    UPDATE pig_production SET 
        date_starter                = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 

    UPDATE pig_production SET 
        date_grower                 = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_FINISHER THEN 

    UPDATE pig_production SET 
        date_finisher               = in_feed_start_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id =  in_pig_prod_id;
END IF;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;


END $$

DELIMITER ;
