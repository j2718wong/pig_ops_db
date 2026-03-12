DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_dead_update $$
CREATE PROCEDURE pig_prod_pig_dead_update(
    in_user_id                  INT,
    
    in_pig_prod_pig_dead_id     INT,
    
    in_date_dead                VARCHAR(10),
    in_pig_dead_type_id         INT,
    in_num_pigs_dead            INT,
    in_notes                    VARCHAR(160)
    
)

BEGIN

/** 
 * Will update pig_prod_pig_dead entry.
 * @author Jack Wong
 * @since August 27, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD    INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_dead_pig_prod_id                INT             DEFAULT 0;
DECLARE cur_pig_dead_production_group_id        INT             DEFAULT 0;
DECLARE cur_pig_dead_notes_id                   INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_weaning               DATE            DEFAULT NULL;


DECLARE cur_num_pigs_current                    INT             DEFAULT 0;


DECLARE cur_dead_at_stage                       INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        a.account_id,
        a.pig_prod_id,
        a.production_group_id,
        a.notes_id,
        
        b.pig_farm_id,
        b.prod_status_id,
        b.date_weaning
INTO    
        cur_pig_prod_account_id,
        cur_pig_dead_pig_prod_id,
        cur_pig_dead_production_group_id,
        cur_pig_dead_notes_id,
        
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_weaning
FROM    pig_prod_pig_dead a 
LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id
WHERE   a.id = in_pig_prod_pig_dead_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD,
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


/* Compute dead_at_stage*/
IF cur_pig_dead_pig_prod_id > 0 THEN 

    IF cur_pig_prod_date_weaning IS NULL THEN 
        SET cur_dead_at_stage = DEAD_AT_STAGE_LACTATING;
    ELSE
        IF in_date_dead >= cur_pig_prod_date_weaning THEN 
            SET cur_dead_at_stage = DEAD_AT_STAGE_GROWING;
        ELSE
            SET cur_dead_at_stage = DEAD_AT_STAGE_LACTATING;
        END IF;
    END IF;

ELSE
    SET cur_dead_at_stage = DEAD_AT_STAGE_GROWING;
END IF;

UPDATE pig_prod_pig_dead SET
    date_dead           = in_date_dead,
    dead_type_id        = in_pig_dead_type_id,
    num_pigs_dead       = in_num_pigs_dead,

    notes               = in_notes,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_pig_dead_id;


/* Calculate current number of pigs.*/
IF cur_pig_dead_pig_prod_id > 0 THEN 
    CALL production_calculate_current_pigs(cur_pig_dead_pig_prod_id, 0, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    UPDATE  pig_production SET
        num_pigs_current = cur_num_pigs_current
    WHERE id = cur_pig_dead_pig_prod_id;

ELSE
    CALL production_calculate_current_pigs(0, cur_pig_dead_production_group_id, cur_num_pigs_current);
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    UPDATE  production_group SET
        num_pigs_current = cur_num_pigs_current
    WHERE id = cur_pig_dead_production_group_id;
    
END IF;



IF cur_pig_dead_notes_id > 0 THEN 
    UPDATE pig_prod_notes SET
        notes               = in_notes,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP

    WHERE id = cur_pig_dead_notes_id;

ELSE
    IF in_notes IS NOT NULL THEN 
        INSERT INTO pig_prod_notes (
            account_id,
            pig_farm_id,
            pig_prod_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_pig_prod_account_id, 
            cur_pig_prod_pig_farm_id,
            cur_pig_dead_pig_prod_id,
            
            in_notes,
            CURRENT_DATE,
            in_user_id
        );
        
        SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
        
        /* pig_production.insem_notes_id*/
        UPDATE pig_prod_pig_dead SET
            notes_id = cur_pig_prod_notes_id
        WHERE id = in_pig_prod_pig_dead_id;
    END IF;
    
END IF;





END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_pig_dead_id             AS pig_prod_pig_dead_id;
    


END $$

DELIMITER ;
