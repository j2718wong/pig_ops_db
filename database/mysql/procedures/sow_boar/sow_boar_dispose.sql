DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_dispose $$
CREATE PROCEDURE sow_boar_dispose(
    in_user_id              INT,
    
    in_sow_boar_id          INT,
    in_dispose_status_id    INT,
    
    in_date_dispose         VARCHAR(10),
    in_dispose_notes        VARCHAR(160)
)  

BEGIN

/** 
 * Will dispose sow_boar entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 17, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;

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




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
        

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;



DECLARE cur_sow_boar_sex                        CHAR(2);


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.pig_farm_id,  
        a.account_id,
        a.sex,
        a.last_pig_production_id,
        b.prod_status_id

INTO    cur_sow_boar_pig_farm_id,
        cur_sow_boar_account_id,
        cur_sow_boar_sex,
        cur_pig_prod_id,
        cur_pig_prod_status_id
        
FROM    sow_boar
WHERE   id = in_sow_boar_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SOW_BOAR,
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


IF in_dispose_notes IS NOT NULL THEN 
    INSERT INTO pig_prod_notes (
        sow_boar_id,
        
        notes,
        date_notes,
        added_by_user_id
        
    ) VALUES (
        in_sow_boar_id,
        
        in_dispose_notes,
        CURRENT_DATE,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
END IF;




UPDATE sow_boar SET
    date_dispose        = in_date_dispose,
    dispose_notes_id    = cur_pig_prod_notes_id,
    dispose_status_id   = in_dispose_status_id,
    is_disposed         = 1,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE 
    id = in_sow_boar_id;


IF cur_sow_boar_sex = 'M' THEN 
    UPDATE pig_farm SET
        data_ver_num_boar = data_ver_num_boar + 1
    WHERE id = cur_sow_boar_pig_farm_id; 
ELSE
    /* Update production status if gestating*/
    IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_GESTATING THEN 
        UPDATE pig_production SET 
            prod_status_id = PRODUCTION_STATUS_ID_TERMINATED
        WHERE id = cur_pig_prod_id;
        
        UPDATE pig_farm SET
            data_ver_num_sow      = data_ver_num_sow + 1,
            data_ver_num_pig_prod = data_ver_num_pig_prod + 1
        WHERE id = cur_sow_boar_pig_farm_id; 
    
    ELSE
    
        UPDATE pig_farm SET
            data_ver_num_sow      = data_ver_num_sow + 1
        WHERE id = cur_sow_boar_pig_farm_id; 

    END IF;
END IF;







END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_sow_boar_id                      AS sow_boar_id;
    

END $$

DELIMITER ;
