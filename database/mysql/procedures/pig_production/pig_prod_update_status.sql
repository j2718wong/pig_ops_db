DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_status $$
CREATE PROCEDURE pig_prod_update_status(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_pig_prod_status_id   INT,
    
    in_date_status          VARCHAR(10),
    in_notes                VARCHAR(160)
)

BEGIN

/** 
 * Will update pig_production entry.
 * 
 * Will manually update pig_production.prod_status_id
 *
 * Allowed status_ids: TERMINATED, NOT_PREGNANT, CLOSED, NO_LIVE_PIGLETS
 *
 *
 * @author Jack Wong
 * @since September 12, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_INVALID_PIG_PROD_STATUS         INT             DEFAULT 20;
DECLARE RES_NUM_MANUAL_STATUS_UPDATE_NOT_ALLOWED INT            DEFAULT 21;
DECLARE RES_NUM_PIG_PROD_STATUS_NOT_GESTATING   INT             DEFAULT 22;

DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* pig_production.flag bits*/
DECLARE FLAG_BIT_PIGLETS_ARE_EXTERNAL           INT             DEFAULT 2;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;
DECLARE PRODUCTION_STATUS_ID_NO_LIVE_PIGLETS    INT             DEFAULT 10;

DECLARE SOW_STATUS_ID_GESTATING                 INT             DEFAULT 2;
DECLARE SOW_STATUS_ID_DEAD                      INT             DEFAULT 6;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        sow_id,
        prod_status_id,
        flag
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_status_id,
        cur_pig_prod_flag
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


IF  in_pig_prod_status_id <= 0 OR 
    in_pig_prod_status_id > PRODUCTION_STATUS_ID_NO_LIVE_PIGLETS THEN
    
    SET res_num     = RES_NUM_INVALID_PIG_PROD_STATUS;
    SET res_code    = "RES_NUM_INVALID_PIG_PROD_STATUS";
    
    LEAVE process_user;
END IF;


IF in_pig_prod_status_id NOT IN (PRODUCTION_STATUS_ID_TERMINATED, 
                                PRODUCTION_STATUS_ID_NOT_PREGNANT, 
                                PRODUCTION_STATUS_ID_CLOSED,
                                PRODUCTION_STATUS_ID_NO_LIVE_PIGLETS) THEN
    
    SET res_num     = RES_NUM_MANUAL_STATUS_UPDATE_NOT_ALLOWED;
    SET res_code    = "RES_NUM_MANUAL_STATUS_UPDATE_NOT_ALLOWED";
    
    LEAVE process_user;
END IF;

IF in_pig_prod_status_id IN (PRODUCTION_STATUS_ID_TERMINATED, 
                            PRODUCTION_STATUS_ID_NOT_PREGNANT,
                            PRODUCTION_STATUS_ID_NO_LIVE_PIGLETS) THEN 
    IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
        SET res_num     = RES_NUM_PIG_PROD_STATUS_NOT_GESTATING;
        SET res_code    = "RES_NUM_PIG_PROD_STATUS_NOT_GESTATING";
        
        LEAVE process_user;
    END IF;
END IF;


UPDATE pig_production SET
    prod_status_id              = in_pig_prod_status_id,
    
    last_update_user_id         = in_user_id,
    dt_last_update              = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_id;


/* This will also update sow_status*/
IF in_pig_prod_status_id = PRODUCTION_STATUS_ID_TERMINATED THEN 
    UPDATE sow_boar SET 
        sow_status_id = SOW_STATUS_ID_DEAD
    WHERE id = cur_pig_prod_sow_id;
END IF;

IF in_pig_prod_status_id IN (PRODUCTION_STATUS_ID_NOT_PREGNANT,
                            PRODUCTION_STATUS_ID_NO_LIVE_PIGLETS) THEN 
    UPDATE sow_boar SET 
        sow_status_id = SOW_STATUS_ID_GESTATING
    WHERE id = cur_pig_prod_sow_id;
END IF;


/* Add notes*/
IF in_notes IS NOT NULL THEN 
    INSERT INTO pig_prod_notes (
        pig_prod_id,
        
        notes,
        date_notes,
        added_by_user_id
        
    ) VALUES (
        in_pig_prod_id,
        
        in_notes,
        in_date_status,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
END IF;



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;
    


END $$

DELIMITER ;
