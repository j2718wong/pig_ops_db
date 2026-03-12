DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_ops_update $$
CREATE PROCEDURE pig_prod_pig_ops_update(
    in_user_id                  INT,
   
    in_pig_prod_pig_ops_id      INT,
    in_staff_id                 INT,
    in_done_by_user             INT, 
    
    in_date                     VARCHAR(10),
    in_notes                    VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_pig_ops entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_BE_UDPATED               INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;

DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_operation_type     INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_notes_id           INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_prod_pig_ops_id                     INT             DEFAULT 0;

DECLARE cur_prod_notes                          VARCHAR(160)    DEFAULT NULL;


DECLARE cur_acc_pig_ops_name                    VARCHAR(50);
DECLARE cur_staff_name                          VARCHAR(50);
DECLARE cur_notes                               VARCHAR(200);

DECLARE added_new_staff                         INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        b.account_id,
        b.pig_farm_id,
        b.sow_id,
        a.pig_prod_id,
        a.operation_type,
        b.prod_status_id,
        a.notes_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_id,
        cur_pig_prod_pig_ops_operation_type,
        cur_pig_prod_status_id,
        cur_pig_prod_pig_ops_notes_id
        
FROM    pig_prod_pig_ops a
LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id
WHERE   a.id = in_pig_prod_pig_ops_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS,
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



IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
    IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
        SET res_num     = RES_NUM_CANNOT_BE_UDPATED;
        SET res_code    = "RES_NUM_CANNOT_BE_UDPATED";
        
        LEAVE process_user;
    END IF;
END IF;



SELECT  b.name
INTO    cur_acc_pig_ops_name
FROM    pig_prod_pig_ops a 
LEFT OUTER JOIN account_pig_ops b ON a.account_pig_ops_id = b.id 
WHERE   a.id = in_pig_prod_pig_ops_id;


SELECT  name
INTO    cur_staff_name
FROM    pig_farm_staff
WHERE   id = in_staff_id;



IF cur_pig_prod_pig_ops_notes_id IS NULL OR cur_pig_prod_pig_ops_notes_id = 0 THEN 
    
    /* This is necessary as notes is optional; It will leave blank in table row 
     UI if no notes.*/


    SET cur_notes  = CONCAT('Pig operation(', cur_acc_pig_ops_name ,') done by ', cur_staff_name, '. ');


    IF in_notes IS NOT NULL THEN 
        SET cur_notes  = CONCAT(cur_notes, in_notes);
    END IF;


    /* Truncate notes if needed. */
    IF LENGTH(cur_notes) >= 160 THEN 
        SET cur_notes = SUBSTRING(cur_notes, 1, 159);
    END IF;

    
    /* Should relate to both sow and pig_prod*/
    IF cur_pig_prod_pig_ops_operation_type IN ( PIG_OPERATION_TYPE_GESTATING,
                                                PIG_OPERATION_TYPE_LACTATING_SOW) THEN
        INSERT INTO pig_prod_notes (
            account_id,
            pig_farm_id,
            
            
            pig_prod_id,
            sow_boar_id,
            production_group_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            
            cur_pig_prod_id,
            cur_pig_prod_sow_id,
            NULL,
            
            cur_notes,
            in_date,
            in_user_id
        );
    END iF;
    
    
    /** Should not relate to sow if operation is for piglets*/
    IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS THEN 
    
        INSERT INTO pig_prod_notes (
            account_id,
            pig_farm_id,
            
            pig_prod_id,
            sow_boar_id,
            production_group_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            
            cur_pig_prod_id,
            NULL,
            NULL,
            
            cur_notes,
            in_date,
            in_user_id
        );
    END IF;
    
    
    /** Should only relate to sow*/
    IF cur_pig_prod_pig_ops_operation_type IN ( PIG_OPERATION_TYPE_GILT_OPS,
                                                PIG_OPERATION_TYPE_WEANING_SOW_OPS) THEN
        INSERT INTO pig_prod_notes (
            account_id,
            pig_farm_id,
            
            pig_prod_id,
            sow_boar_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            
            NULL,
            cur_pig_prod_sow_id,
            
            cur_notes,
            in_date,
            in_user_id
        );
    
    END IF;


    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    UPDATE pig_prod_pig_ops SET
        notes_id            = cur_pig_prod_notes_id
    WHERE id = in_pig_prod_pig_ops_id;

ELSE
    
    
    UPDATE pig_prod_notes SET 
        date_notes          = in_date,
        notes               = in_notes,
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP
    WHERE id = cur_pig_prod_pig_ops_notes_id;

END IF;


/* If done by user, user will be added to staff list.
Note: not all staff are users
*/
IF in_done_by_user > 0 THEN
    SELECT  pig_farm_staff_id,
            name_first,
            name_last
    
    INTO    cur_user_staff_id,
            cur_user_name_first,
            cur_user_name_last
    FROM    user 
    WHERE   id = in_user_id;
    
    
    IF cur_user_staff_id = 0 THEN 
        INSERT INTO pig_farm_staff (
            account_id,
            pig_farm_id,
            user_id,
            name,
            
            added_by_user_id
        ) VALUES (
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            in_user_id,
            CONCAT(cur_user_name_first, ' ', cur_user_name_last),
            
            in_user_id
        );
        SELECT LAST_INSERT_ID() INTO cur_user_staff_id;
        
        
        UPDATE user SET 
            pig_farm_staff_id = cur_user_staff_id
        WHERE id = in_user_id;
        
        SET added_new_staff = 1;
        
    END IF;
    
    
    SET in_staff_id = cur_user_staff_id;
    
END IF;


UPDATE pig_prod_pig_ops SET
    date_actual         = in_date,
    staff_id            = in_staff_id,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_pig_prod_pig_ops_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_pig_ops_id              AS pig_prod_pig_ops_id,
    added_new_staff                     AS added_new_staff,
    cur_pig_prod_pig_farm_id            AS pig_farm_id;
    

END $$

DELIMITER ;
