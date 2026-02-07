DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_birth $$
CREATE PROCEDURE pig_prod_update_birth(
    in_user_id                  INT,
    
    in_pig_prod_id              INT,
    
    in_date_actual_birth        VARCHAR(10),  /* in YYYY-MM-DD format*/
    in_num_pigs_dead_at_birth   INT,
    in_num_pigs_live_m          INT,
    in_num_pigs_live_f          INT,
    
    in_birth_staff_id           INT,
    in_done_by_user             INT
    
)

BEGIN

/** 
 * Will update pig_production at piglets birth entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_UPDATE_BIRTH_NOT_ALLOWED        INT             DEFAULT 20;

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


DECLARE SOW_STATUS_ID_LACTATING                 INT             DEFAULT 3;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;



/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';


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

DECLARE added_new_staff                         INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        prod_status_id,
        sow_id,
        date_actual_birth
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_status_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_date_actual_birth
        
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




SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = cur_pig_prod_account_id;



IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_GESTATING,
                                    PRODUCTION_STATUS_ID_LACTATING) THEN 
    SET res_num     = RES_NUM_UPDATE_BIRTH_NOT_ALLOWED;
    SET res_code    = "RES_NUM_UPDATE_BIRTH_NOT_ALLOWED";
    SET res_desc    = "Production status not GESTATING or LACTATING.";
    
    LEAVE process_user;
END IF;


/*
It is possible to change the date_actual_birth, but there is a series of 
operations to be done to the affected business objects. So that is why   
we need to check if the date_actual_birth has been modified.

*/

IF cur_pig_prod_date_actual_birth IS NULL THEN 
    SET detected_actual_date_birth_change = 1;

ELSE
    SET date_temp = STR_TO_DATE(in_date_actual_birth, '%Y-%m-%d');
    
    IF date_temp != cur_pig_prod_date_actual_birth THEN 
        SET detected_actual_date_birth_change = 1;
    END IF;

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
    
    
    SET in_birth_staff_id = cur_user_staff_id;
    
END IF;




UPDATE pig_production SET 
    date_actual_birth           = in_date_actual_birth,
    num_days_actual             = DATEDIFF(in_date_actual_birth, date_insemination),
    prod_status_id              = PRODUCTION_STATUS_ID_LACTATING,
    
    num_pigs_dead_at_birth      = in_num_pigs_dead_at_birth,
    num_pigs_live_m             = in_num_pigs_live_m,
    num_pigs_live_f             = in_num_pigs_live_f,
    
    num_pigs_current            = in_num_pigs_live_m + in_num_pigs_live_f,
    
    birth_staff_id              = in_birth_staff_id,
    
    last_update_user_id         = in_user_id,
    dt_last_update              = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_id;


UPDATE sow_boar SET 
    sow_status_id   = SOW_STATUS_ID_LACTATING
WHERE id = cur_pig_prod_sow_id;


/* Count if there are pig operations to be done for lactating sow set by account.*/
SELECT  COUNT(*)
INTO    cur_count_account_pig_ops
FROM    account_pig_ops
WHERE   account_id = cur_pig_prod_account_id  AND 
        operation_type = PIG_OPERATION_TYPE_LACTATING_SOW AND 
        (flag & FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED) = 0;


IF cur_count_account_pig_ops > 0 THEN 
    SELECT  COUNT(*)
    INTO    cur_count_pig_prod_pig_ops
    FROM    pig_prod_pig_ops
    WHERE   pig_prod_id = in_pig_prod_id AND 
            operation_type = PIG_OPERATION_TYPE_LACTATING_SOW;

    IF cur_count_pig_prod_pig_ops = 0 THEN 
        /* Create pig_prod_pig_ops entry*/
        CALL pig_prod_pig_ops_add(
            in_user_id,
            
            cur_pig_prod_account_id, 
            PIG_OPERATION_TYPE_LACTATING_SOW,
            in_pig_prod_id,
            in_date_actual_birth
        );
        
        /* Since this is a lactating sow pig ops, need to relate to SOW.*/
        UPDATE pig_prod_pig_ops SET 
            sow_boar_id = cur_pig_prod_sow_id
        WHERE pig_prod_id = in_pig_prod_id AND a.operation_type = PIG_OPERATION_TYPE_LACTATING_SOW;
        
    ELSE
        IF detected_actual_date_birth_change > 0 THEN
            
            /* Need to adjust Day 1 counting.*/
            IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH = 0 THEN 
                UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                    a.date_target = DATE_ADD(in_date_actual_birth, INTERVAL b.num_days_since DAY)
                WHERE   a.pig_prod_id = in_pig_prod_id AND 
                        a.operation_type = PIG_OPERATION_TYPE_LACTATING_SOW AND
                        a.account_pig_ops_id = b.id;
            
            ELSE
                UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                    a.date_target = DATE_ADD(in_date_actual_birth, INTERVAL b.num_days_since - 1 DAY)
                WHERE   a.pig_prod_id = in_pig_prod_id AND 
                        a.operation_type = PIG_OPERATION_TYPE_LACTATING_SOW AND
                        a.account_pig_ops_id = b.id;
            END IF;
        END IF;

    END IF;

END IF;


/* Count if there are pig operations to be done for lactating piglets set by account.*/
SELECT  COUNT(*)
INTO    cur_count_pig_prod_pig_ops
FROM    pig_prod_pig_ops
WHERE   pig_prod_id = in_pig_prod_id AND 
        operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS;

IF cur_count_pig_prod_pig_ops = 0 THEN 
    /* Create pig_prod_pig_ops entry*/
    CALL pig_prod_pig_ops_add(
        in_user_id,
        
        cur_pig_prod_account_id, 
        PIG_OPERATION_TYPE_LACTATING_PIGLETS,
        in_pig_prod_id,
        in_date_actual_birth
    );

ELSE
    IF detected_actual_date_birth_change > 0 THEN
    
        IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH = 0 THEN
            UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                a.date_target = DATE_ADD(in_date_actual_birth, INTERVAL b.num_days_since DAY)
            WHERE   a.pig_prod_id = in_pig_prod_id AND 
                    a.operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS AND
                    a.account_pig_ops_id = b.id;
        
        ELSE
            UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                a.date_target = DATE_ADD(in_date_actual_birth, INTERVAL b.num_days_since - 1 DAY)
            WHERE   a.pig_prod_id = in_pig_prod_id AND 
                    a.operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS AND
                    a.account_pig_ops_id = b.id;
        END IF;
    END IF;
END IF;

END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id,
    added_new_staff                     AS added_new_staff;

END $$

DELIMITER ;
