DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_update $$
CREATE PROCEDURE sow_boar_update(
    in_user_id              INT,
    
    in_sow_boar_id          INT,
    in_line_id              INT,
    in_sow_status_id        INT,
    in_is_external          INT,
    in_is_production_ready  INT,
    
    in_number               VARCHAR(10),
    in_name                 VARCHAR(20),
    in_date_of_birth        VARCHAR(10),
    in_date_eartag          VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update sow_boar entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 16, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;
DECLARE RES_NUM_SOW_BOAR_ALREADY_DISPOSED       INT             DEFAULT 1;

DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;



DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_sow_boar_id                         INT             DEFAULT 0;
DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_flag                       INT             DEFAULT 0;
DECLARE cur_sow_boar_add_notes_id               INT             DEFAULT 0;
DECLARE cur_sow_boar_is_disposed                INT             DEFAULT 0;
DECLARE cur_sow_boar_sex                        VARCHAR(2);
DECLARE cur_sow_boar_date_of_birth              DATE;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_account_flag_settings               INT             DEFAULT 0;
DECLARE cur_count                               INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        flag,
        add_notes_id,
        is_disposed,
        sex,
        date_of_birth
        
INTO    cur_sow_boar_account_id,
        cur_sow_boar_flag,
        cur_sow_boar_add_notes_id,
        cur_sow_boar_is_disposed,
        cur_sow_boar_sex,
        cur_sow_boar_date_of_birth
        
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


IF cur_sow_boar_is_disposed > 0 THEN 
    SET res_num     = RES_NUM_SOW_BOAR_ALREADY_DISPOSED;
    SET res_code    = "RES_NUM_SOW_BOAR_ALREADY_DISPOSED";
    
    LEAVE process_user;
END IF;


UPDATE sow_boar SET
    line_id             = in_line_id,
    sow_status_id       = in_sow_status_id,

    is_external         = in_is_external,
    is_production_ready = in_is_production_ready,
    
    number              = in_number,
    name                = in_name,
    date_of_birth       = in_date_of_birth,
    date_eartag         = in_date_eartag,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE 
    id = in_sow_boar_id;


IF cur_sow_boar_add_notes_id > 0 THEN
    UPDATE pig_prod_notes SET
        notes               = in_notes,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP

    WHERE id = cur_sow_boar_add_notes_id;
ELSE 
    IF in_notes IS NOT NULL THEN 
        INSERT INTO pig_prod_notes (
            sow_boar_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            cur_sow_boar_id,
            
            in_notes,
            CURRENT_DATE,
            in_user_id
        );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    /* sow_boar.add_notes_id*/
    UPDATE sow_boar SET
        add_notes_id = cur_pig_prod_notes_id
    WHERE id = in_sow_boar_id;

    END IF;

END IF;


/*Perform a series of gilt ops adjustments if 
- a sow
- no gilt ops yet
- change in sow date_of_birth (need to recalculate the dates);
*/


IF cur_sow_boar_sex = 'F' THEN 
    IF in_date_of_birth IS NULL THEN 
        LEAVE process_user; /* Nothing to do*/
    END IF;
    

    SELECT  flag_settings
    INTO    cur_account_flag_settings
    FROM    account 
    WHERE   id = cur_sow_boar_account_id;


    /* Count if there is an account gilt pig ops.*/
    SELECT  COUNT(*) 
    INTO    cur_count 
    FROM    account_pig_ops
    WHERE   account_id = cur_sow_boar_account_id AND 
            operation_type = PIG_OPERATION_TYPE_GILT_OPS;
            
    IF cur_count > 0 THEN 
        SET cur_count = 0;
    
        SELECT  COUNT(*) 
        INTO    cur_count 
        FROM    pig_prod_pig_ops
        WHERE   sow_boar_id = in_sow_boar_id AND 
                operation_type = PIG_OPERATION_TYPE_GILT_OPS;
        
        IF cur_count = 0 THEN 
            CALL gilt_pig_ops_add(
                in_user_id,
                cur_user_account_id,
                PIG_OPERATION_TYPE_GILT_OPS,
                in_sow_boar_id,
                in_date_of_birth
            );
        
        END IF;
        
        IF cur_count > 0 THEN 
            
            /* Chnage only if there is an update of gilt date_of_birth */
            IF cur_sow_boar_date_of_birth != in_date_of_birth THEN 
            
                /* Need to adjust Day 1 counting.*/
                IF cur_account_flag_settings & FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH = 0 THEN 
                    UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                        a.date_target = DATE_ADD(in_date_of_birth, INTERVAL b.num_days_since DAY)
                    WHERE   a.sow_boar_id = in_sow_boar_id AND 
                            a.operation_type = PIG_OPERATION_TYPE_GILT_OPS AND
                            a.account_pig_ops_id = b.id;
                
                ELSE
                    UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                        a.date_target = DATE_ADD(in_date_of_birth, INTERVAL b.num_days_since - 1 DAY)
                    WHERE   a.sow_boar_id = in_sow_boar_id AND 
                            a.operation_type = PIG_OPERATION_TYPE_GILT_OPS AND
                            a.account_pig_ops_id = b.id;
                END IF;
            
            END IF;
        
        END IF;
        
        
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
