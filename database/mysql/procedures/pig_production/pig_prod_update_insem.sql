DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_insem $$
CREATE PROCEDURE pig_prod_update_insem(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    
    in_boar_id              INT,
    
    in_semen_supplier_id    INT,
    in_semen_sup_semen_id   INT,    /* semen supplier semen_id*/
    in_semen_ai_boar_id     INT,    /* semen coming from one of farm's boar*/
    
    
    in_semen_cost           DECIMAL(6,2),
    in_insemination_cost    DECIMAL(6,2),
    in_comments             VARCHAR(160),
    
    in_insem_staff_id       INT,
    in_date_insemination    VARCHAR(10)  /* in YYYY-MM-DD format*/

)

BEGIN

/** 
 * Will update pig_production entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_STATUS_NOT_GESTATING   INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA INT             DEFAULT 21;
DECLARE RES_NUM_PIG_PROD_PIGLETS_ARE_EXTERNAL   INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE INSEMINATION_TYPE_BOAR                  VARCHAR(2)      DEFAULT 'B';
DECLARE INSEMINATION_TYPE_ARTIFICIAL_EXTERNAL   VARCHAR(4)      DEFAULT 'AI_X';
DECLARE INSEMINATION_TYPE_ARTIFICIAL_INTERNAL   VARCHAR(4)      DEFAULT 'AI_N';


/* pig_production.flag bits*/
DECLARE FLAG_BIT_PIGLETS_ARE_EXTERNAL           INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_insemination          DATE            DEFAULT NULL;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;
DECLARE cur_pig_prod_insem_notes_id             INT             DEFAULT 0;

DECLARE cur_insemination_type                   VARCHAR(4)      DEFAULT NULL;

DECLARE cur_pig_prod_date_actual_birth          DATE;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        sow_id,
        prod_status_id,
        date_insemination,
        flag,
        insem_notes_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_insemination,
        cur_pig_prod_flag,
        cur_pig_prod_insem_notes_id
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


IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
    SET res_num     = RES_NUM_PIG_PROD_STATUS_NOT_GESTATING;
    SET res_code    = "RES_NUM_PIG_PROD_STATUS_NOT_GESTATING";
    
    LEAVE process_user;
END IF;


IF cur_pig_prod_flag & FLAG_BIT_PIGLETS_ARE_EXTERNAL THEN 
    SET res_num     = RES_NUM_PIG_PROD_PIGLETS_ARE_EXTERNAL;
    SET res_code    = "RES_NUM_PIG_PROD_PIGLETS_ARE_EXTERNAL";
    SET res_desc    = "Cannot update insemination data if piglets are external.";
    
    LEAVE process_user;
END IF;


SELECT  date_actual_birth
INTO    cur_pig_prod_date_actual_birth
FROM    pig_production
WHERE   id = in_pig_prod_id;


IF cur_pig_prod_date_actual_birth IS NOT NULL THEN 

    SET res_num     = RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA;
    SET res_code    = "RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA";
    SET res_desc    = "Cannot update insemination data after birth.";
    
    LEAVE process_user;

END IF;


/* Check if semen is coming from external supplier*/
IF in_boar_id > 0 THEN 
    SET cur_insemination_type = INSEMINATION_TYPE_BOAR;
ELSE 

    IF in_semen_sup_semen_id > 0 THEN 
        SET cur_insemination_type = INSEMINATION_TYPE_ARTIFICIAL_EXTERNAL;
        
    ELSE
        IF in_semen_ai_boar_id > 0 THEN 
            SET cur_insemination_type = INSEMINATION_TYPE_ARTIFICIAL_INTERNAL;
        END IF;
        
    END IF;
END IF;


UPDATE pig_production SET
    insemination_type       = cur_insemination_type,
    
    boar_id                 = in_boar_id,
        
    semen_supplier_id       = in_semen_supplier_id,
    semen_sup_semen_id      = in_semen_sup_semen_id,
    semen_ai_boar_id        = in_semen_ai_boar_id,
        
    semen_cost              = in_semen_cost,
    insemination_cost       = in_insemination_cost,
        
    date_insemination       = in_date_insemination,
    date_expected_birth     = DATE_ADD(in_date_insemination, INTERVAL 115 DAY),
        
    insem_staff_id          = in_insem_staff_id,
        
    last_update_user_id     = in_user_id,
    dt_last_update          = CURRENT_TIMESTAMP,
    
    data_ver_num_pig_prod   = data_ver_num_pig_prod + 1
    
WHERE id =  in_pig_prod_id;


IF cur_pig_prod_insem_notes_id > 0 THEN 
    UPDATE pig_prod_notes SET
        date_notes          = in_date_insemination,
        notes               = in_comments,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP

    WHERE id = cur_pig_prod_insem_notes_id;

ELSE
    IF in_comments IS NOT NULL THEN 
        INSERT INTO pig_prod_notes (
            pig_prod_id,
            sow_boar_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            in_pig_prod_id,
            cur_pig_prod_sow_id,
            
            in_comments,
            in_date_insemination,
            in_user_id
        );
        
        SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
        
        /* pig_production.insem_notes_id*/
        UPDATE pig_production SET
            insem_notes_id = cur_pig_prod_notes_id
        WHERE id = in_pig_prod_id;
    END IF;
    
END IF;


IF cur_pig_prod_date_insemination != in_date_insemination THEN 
    UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
        a.date_target = DATE_ADD(in_date_insemination, INTERVAL b.num_days_since DAY)
    WHERE   a.pig_prod_id = in_pig_prod_id AND 
            a.operation_type = PIG_OPERATION_TYPE_GESTATING AND
            a.account_pig_ops_id = b.id;
END IF;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;
    


END $$

DELIMITER ;
