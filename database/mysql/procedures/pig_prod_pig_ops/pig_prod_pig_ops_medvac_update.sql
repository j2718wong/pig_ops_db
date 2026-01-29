DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_ops_medvac_update $$
CREATE PROCEDURE pig_prod_pig_ops_medvac_update(
    in_user_id              INT,
   
    in_pig_prod_pig_ops_id  INT,
    in_staff_id             INT,
    in_done_by_user         INT,

    in_medvac_brand_id      INT,
    in_medvac_type_id       INT,
    in_acc_medvac_id        INT,
    
    in_date                 VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_pig_ops entry. This is the variation if the pigops is a medvac.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_SOW_BOAR_ALREADY_DISPOSED       INT             DEFAULT 20;

DECLARE RES_NUM_PIG_PROD_INACTIVE_STATUS        INT             DEFAULT 21;
DECLARE RES_NUM_CANNOT_BE_UDPATED               INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_sow_boar_id        INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_operation_type     INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_notes_id           INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_pig_medvac_id      INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_prod_pig_ops_id                     INT             DEFAULT 0;


DECLARE cur_sow_is_disposed                     INT             DEFAULT 0;

DECLARE cur_is_active_status                    INT             DEFAULT 0;

DECLARE cur_medvac_id                           INT             DEFAULT 0;

DECLARE cur_acc_pig_ops_name                    VARCHAR(50);
DECLARE cur_staff_name                          VARCHAR(50);
DECLARE cur_notes                               VARCHAR(200);

DECLARE added_new_staff                         INT             DEFAULT 0;


DECLARE cur_u_brand_name                        VARCHAR(50)     DEFAULT '';
DECLARE cur_u_type_name                         VARCHAR(50)     DEFAULT '';
DECLARE cur_u_acc_medvac_name                   VARCHAR(50)     DEFAULT '';
DECLARE cur_u_medvac_notes                      VARCHAR(160)    DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        b.account_id,
        b.pig_farm_id,
        a.pig_prod_id,
        b.sow_id,           /*This is pig_production.sow_id*/
        a.sow_boar_id,      /*This is pig_prod_pig_ops.sow_boar_id*/
        
        a.operation_type,
        b.prod_status_id,
        a.notes_id,
        a.pig_medvac_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_pig_ops_sow_boar_id,
        
        cur_pig_prod_pig_ops_operation_type,
        cur_pig_prod_status_id,
        cur_pig_prod_pig_ops_notes_id,
        cur_pig_prod_pig_ops_pig_medvac_id
        
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


/* Check sow_boar status*/
IF cur_pig_prod_pig_ops_sow_boar_id > 0 THEN
    /** Check sow_status if not yet disposed*/
    SELECT  is_disposed
    INTO    cur_sow_is_disposed
    FROM    sow_boar
    WHERE   id  = cur_pig_prod_pig_ops_sow_boar_id;
    
    
    IF cur_sow_is_disposed  > 0 THEN 
        SET res_num     = RES_NUM_SOW_BOAR_ALREADY_DISPOSED;
        SET res_code    = "RES_NUM_SOW_BOAR_ALREADY_DISPOSED";
        
        LEAVE process_user;
    END IF;
    
END IF;


/* Check pig_production status*/
IF cur_pig_prod_id > 0 THEN 
    SET cur_is_active_status = 0;
    CALL pig_prod_check_active_status(cur_pig_prod_status_id, cur_is_active_status);
    
    IF cur_is_active_status = 0 THEN 
        SET res_num     = RES_NUM_PIG_PROD_INACTIVE_STATUS;
        SET res_code    = "RES_NUM_PIG_PROD_INACTIVE_STATUS";
    
        LEAVE process_user;
    END IF;


    IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
        IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
            SET res_num     = RES_NUM_CANNOT_BE_UDPATED;
            SET res_code    = "RES_NUM_CANNOT_BE_UDPATED";
            
            LEAVE process_user;
        END IF;
    END IF;
    
    
    IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS THEN 
        IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_LACTATING THEN 
            SET res_num     = RES_NUM_CANNOT_BE_UDPATED;
            SET res_code    = "RES_NUM_CANNOT_BE_UDPATED";
            
            LEAVE process_user;
        END IF;
    END IF;
    

END IF;


IF cur_pig_prod_pig_ops_notes_id IS NULL OR cur_pig_prod_pig_ops_notes_id = 0 THEN 
    
    /* This is necessary as notes is optional; It will leave blank in table row 
     UI if no notes.*/


    SELECT  b.name
    INTO    cur_acc_pig_ops_name
    FROM    pig_prod_pig_ops a 
    LEFT OUTER JOIN account_pig_ops b ON a.account_pig_ops_id = b.id 
    WHERE   a.id = in_pig_prod_pig_ops_id;


    SELECT  name
    INTO    cur_staff_name
    FROM    pig_farm_staff
    WHERE   id = in_staff_id;

    SET cur_notes  = CONCAT('Pig operation(', cur_acc_pig_ops_name ,') done by ', cur_staff_name, '. ');


    IF in_notes IS NOT NULL THEN 
        SET cur_notes  = CONCAT(cur_notes, in_notes);
    END IF;


    /* Truncate notes if needed. */
    IF LENGTH(cur_notes) >= 160 THEN 
        SET cur_notes = SUBSTRING(cur_notes, 1, 159);
    END IF;

    
    
    
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
        NULL,
        cur_pig_prod_id,
        NULL,
        NULL,
        
        cur_notes,
        in_date,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    UPDATE pig_prod_pig_ops SET
        notes_id            = cur_pig_prod_notes_id
    WHERE id = in_pig_prod_pig_ops_id;
    
    SET cur_pig_prod_pig_ops_notes_id = cur_pig_prod_notes_id;

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



/* These string copies of medvac_brand, medvac_type and medvac_name
are used for faster text search for medvac. 

Everytime a user type in key words for search in medvac entry,
it will search through these columns 

1.) u_brand_name
2.) u_type_name
3.) u_medvac_name
4.) u_medvac_notes

The medvac text search is performed using account_id not sow_boar_id, 
so this needs to be fast.

There is also a future plan to search for multiple accounts
with same pig_farm.address_level_2_id, which is even has more data sets to searched.

*/

SELECT  name
INTO    cur_u_brand_name 
FROM    medvac_brand
WHERE   id = in_medvac_brand_id;


SELECT  name
INTO    cur_u_type_name 
FROM    medvac_type
WHERE   id = in_medvac_type_id;


SELECT  name
INTO    cur_u_acc_medvac_name 
FROM    account_medvac
WHERE   id = in_acc_medvac_id;





IF cur_pig_prod_pig_ops_pig_medvac_id IS NULL THEN 
    
    /* Relate to SOW if operation is related to sow. */
    IF cur_pig_prod_pig_ops_operation_type IN (
                                    PIG_OPERATION_TYPE_GESTATING,
                                    PIG_OPERATION_TYPE_LACTATING_SOW,
                                    PIG_OPERATION_TYPE_GILT_OPS) THEN

        INSERT INTO pig_medvac(
    
            pig_prod_pig_ops_id,
            
            sow_boar_id,
            
            date_medvac,
            medvac_type_id,
            medvac_brand_id,
            acc_medvac_id,
    
            u_brand_name,
            u_type_name,
            u_acc_medvac_name,
            
            notes,
                    
            staff_id,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_pig_ops_id,
            
            cur_pig_prod_sow_id,
            
            in_date,
            in_medvac_type_id,
            in_medvac_brand_id,
            in_acc_medvac_id,
            
            cur_u_brand_name,
            cur_u_type_name,
            cur_u_acc_medvac_name,
            
            in_notes,
            
            in_staff_id,
            
            in_user_id
        );

        SELECT LAST_INSERT_ID() INTO cur_medvac_id;
        
        UPDATE pig_prod_pig_ops SET 
            pig_medvac_id = cur_medvac_id
        WHERE id = in_pig_prod_pig_ops_id;
        
    END IF;
    
    
    /* Relate to PIG_PROD if operation is related to piglets. */
    IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS THEN
        INSERT INTO pig_medvac(
    
            pig_prod_pig_ops_id,
            
            pig_prod_id,
            
            date_medvac,
            medvac_type_id,
            medvac_brand_id,
            acc_medvac_id,
    
            u_brand_name,
            u_type_name,
            u_acc_medvac_name,
            
            notes,
            
            
            staff_id,
            
            added_by_user_id

        ) VALUES (
            in_pig_prod_pig_ops_id,
            
            cur_pig_prod_id,
            
            in_date,
            in_medvac_type_id,
            in_medvac_brand_id,
            in_acc_medvac_id,
            
            cur_u_brand_name,
            cur_u_type_name,
            cur_u_acc_medvac_name,
            
            in_notes,
            
            in_staff_id,
            
            in_user_id
        );

        SELECT LAST_INSERT_ID() INTO cur_medvac_id;
        
        UPDATE pig_prod_pig_ops SET 
            pig_medvac_id = cur_medvac_id
        WHERE id = in_pig_prod_pig_ops_id;
    END IF;

ELSE
    /* Update MEDVAC*/
    
    UPDATE pig_medvac  SET
        date_medvac         = in_date,
        
        medvac_brand_id     = in_medvac_brand_id,
        medvac_type_id      = in_medvac_type_id,
        acc_medvac_id       = in_acc_medvac_id,
        
        staff_id            = in_staff_id,
        notes               = in_notes,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP
    WHERE id = cur_pig_prod_pig_ops_pig_medvac_id;


      
END IF;


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
