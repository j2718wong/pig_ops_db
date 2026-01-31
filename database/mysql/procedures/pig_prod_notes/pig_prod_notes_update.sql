DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_notes_update $$
CREATE PROCEDURE pig_prod_notes_update(
    in_user_id              INT,
   
    in_pig_prod_notes_id    INT,
    in_date_notes           VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_notes entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_INACTIVE_STATUS        INT             DEFAULT 20;
DECLARE RES_NUM_SOW_BOAR_INACTIVE_STATUS        INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_sow_boar_id                         INT             DEFAULT 0;


DECLARE cur_account_id_to_check                 INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_is_disposed                INT             DEFAULT 0;


DECLARE cur_is_active_status                    INT             DEFAULT 0;


DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  pig_prod_id,
        sow_boar_id

INTO    cur_pig_prod_id,
        cur_sow_boar_id

FROM    pig_prod_notes 
WHERE   id = in_pig_prod_notes_id;
 

IF cur_pig_prod_id > 0 THEN 

    SELECT  
            account_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_status_id
            
    FROM    pig_production
    WHERE   id = cur_pig_prod_id
    LIMIT   1;


    SET cur_account_id_to_check = cur_pig_prod_account_id;

END IF;

IF cur_sow_boar_id > 0 THEN 

    SELECT  
            account_id,
            is_disposed
    INTO    
            cur_sow_boar_account_id,
            cur_sow_boar_is_disposed
            
    FROM    sow_boar
    WHERE   id = cur_sow_boar_id
    LIMIT   1;


    SET cur_account_id_to_check = cur_sow_boar_account_id;

END IF;



CALL basic_user_check(
        in_user_id, 
        1, /* user must have an account*/
        cur_account_id_to_check, /* compare user.account_id to this account_id*/
        
        BUSINESS_OBJ_ID_PIG_PROD_NOTES,
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


IF cur_pig_prod_id > 0 THEN 
    SET cur_is_active_status = 0;
    CALL pig_prod_check_active_status(cur_pig_prod_status_id, cur_is_active_status);
    
    IF cur_is_active_status = 0 THEN 
        SET res_num     = RES_NUM_PIG_PROD_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_PIG_PROD_INACTIVE_STATUS";
    
        LEAVE process_user;
    END IF;
    
END IF;


IF cur_sow_boar_id > 0 THEN 
    IF cur_sow_boar_is_disposed > 0 THEN 
        SET res_num     = RES_NUM_SOW_BOAR_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_SOW_BOAR_INACTIVE_STATUS";
    
        LEAVE process_user;
    END IF;

END IF;




UPDATE pig_prod_notes SET
    date_notes          = in_date_notes,
    notes               = in_notes,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_pig_prod_notes_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_notes_id                AS pig_prod_notes_id;
    

END $$

DELIMITER ;
