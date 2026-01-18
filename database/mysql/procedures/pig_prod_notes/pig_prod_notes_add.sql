DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_notes_add $$
CREATE PROCEDURE pig_prod_notes_add(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_sow_boar_id          INT,
    in_production_group_id  INT,
    
    in_is_health_issue      INT,
    
    in_date_notes           VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will create pig_prod_notes entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;

/* pig_prod_notes.flag bits*/
DECLARE FLAG_BIT_PIG_PROD_NOTES_IS_DELETED      INT             DEFAULT 1;
DECLARE FLAG_BIT_NOTES_IS_PIG_HEALTH_ISSUE      INT             DEFAULT 2;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_flag                                INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
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

END IF;


IF in_sow_boar_id > 0 THEN 
    SELECT  
            account_id,
            pig_farm_id
    INTO 
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id
            
    FROM    sow_boar
    WHERE   id = in_sow_boar_id;

END IF;


IF in_production_group_id > 0 THEN 
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    production_group 
    WHERE   id = in_production_group_id
    LIMIT   1;
END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
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


IF in_pig_prod_id > 0 THEN 

    IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
        SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
        SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
        
        LEAVE process_user;
    END IF;

END IF;


IF  in_is_health_issue > 0 THEN 
    SET cur_flag = FLAG_BIT_NOTES_IS_PIG_HEALTH_ISSUE;
END IF;

INSERT INTO pig_prod_notes (
    account_id,
    pig_farm_id,
    pig_prod_id,
    sow_boar_id,
    production_group_id,
    flag,
    
    notes,
    date_notes,
    added_by_user_id
    
) VALUES (
    cur_pig_prod_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    in_sow_boar_id,
    in_production_group_id,
    cur_flag,
    
    in_notes,
    in_date_notes,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_notes_id               AS pig_prod_notes_id;
    

END $$

DELIMITER ;
