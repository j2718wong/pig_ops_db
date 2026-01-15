DELIMITER $$

DROP PROCEDURE IF EXISTS pig_medvac_update $$
CREATE PROCEDURE pig_medvac_update(
    in_user_id              INT,
    in_pig_medvac_id        INT,

    in_date_medvac          VARCHAR(10),
    in_medvac_brand_id      INT,
    in_medvac_type_id       INT,
    in_acc_medvac_id        INT,
    in_staff_id             INT,
    
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_medvac entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since January 8, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_MEDVAC  INT          DEFAULT 20;
DECLARE RES_NUM_DISPOSED_SOW_BOAR_CANNOT_ADD_MEDVAC INT         DEFAULT 21;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;



DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;




DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_medvac_account_id               INT             DEFAULT 0;
DECLARE cur_sow_boar_id                         INT             DEFAULT 0;
DECLARE cur_sow_boar_is_disposed                INT             DEFAULT 0;
DECLARE cur_sow_boar_sow_status_id              INT             DEFAULT 0;
DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT 
    a.account_id,
    a.sow_boar_id,
    b.is_disposed,
    b.sow_status_id,
    a.pig_prod_id,
    c.prod_status_id
INTO 
    cur_pig_medvac_account_id,
    cur_sow_boar_id,
    cur_sow_boar_is_disposed,
    cur_sow_boar_sow_status_id,
    cur_pig_prod_id,
    cur_pig_prod_status_id
    
    
FROM pig_medvac a 
LEFT OUTER JOIN sow_boar b          ON a.sow_boar_id = b.id
LEFT OUTER JOIN pig_production c    ON a.pig_prod_id = c.id

WHERE a.id = in_pig_medvac_id;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_medvac_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
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


/* Check pig_production status*/
IF in_pig_prod_id > 0 THEN
    IF cur_pig_prod_status_id IN (  PRODUCTION_STATUS_ID_TERMINATED,
                                    PRODUCTION_STATUS_ID_NOT_PREGNANT,
                                    PRODUCTION_STATUS_ID_HARVESTED,
                                    PRODUCTION_STATUS_ID_CLOSED) THEN 
        SET res_num     = RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_MEDVAC;
        SET res_code    = "RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_MEDVAC";
        
        LEAVE process_user;
    END IF;
END IF;


/* Check sow_boar status*/
IF in_sow_boar_id > 0 THEN 
    IF cur_sow_boar_is_disposed > 0 THEN 
        SET res_num     = RES_NUM_DISPOSED_SOW_BOAR_CANNOT_ADD_MEDVAC;
        SET res_code    = "RES_NUM_DISPOSED_SOW_BOAR_CANNOT_ADD_MEDVAC";
        
        LEAVE process_user;
    END IF;
    
END IF;


UPDATE pig_medvac  SET
    date_medvac         = in_date_medvac,
    
    medvac_brand_id     = in_medvac_brand_id,
    medvac_type_id      = in_medvac_type_id,
    acc_medvac_id       = in_acc_medvac_id,
    
    staff_id            = in_staff_id,
    notes               = in_notes,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_pig_medvac_id;



END process_user;




SELECT 
    res_num             AS result_number,
    res_code            AS result_code,
    res_desc            AS result_desc;

END $$

DELIMITER ;
