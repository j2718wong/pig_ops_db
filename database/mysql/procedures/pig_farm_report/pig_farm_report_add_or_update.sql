DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_report_add_or_update $$
CREATE PROCEDURE pig_farm_report_add_or_update(
    in_user_id              INT,
    
    in_pig_farm_id          INT,
    in_report_type_id       INT,
    
    in_report_date          VARCHAR(10),
    in_file_path            VARCHAR(255),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will add account_pig_buyer entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE REPORT_TYPE_PIG_FARM_SUMMARY            INT             DEFAULT 1;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_farm_report_id                  INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_farm_account_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    0,
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


/* No Duplicate check; IF same type of report generated of same day, the
old entry will be updated. */
SELECT  id
INTO    cur_pig_farm_report_id
FROM    pig_farm_report
WHERE   pig_farm_id         = in_pig_farm_id AND
        report_type_id      = in_report_type_id AND
        report_date         = in_report_date
LIMIT   1;


IF cur_pig_farm_report_id = 0 THEN 

    INSERT INTO pig_farm_report(
        account_id,
        pig_farm_id,
        report_type_id,
        
        report_date,   
        
        file_path,
        notes,
        
        added_by_user_id
        
    ) VALUES (
        cur_pig_farm_account_id,
        in_pig_farm_id,
        in_report_type_id,
        
        in_report_date,
        in_file_path,
        in_notes,
        
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_farm_report_id;

    IF in_report_type_id = REPORT_TYPE_PIG_FARM_SUMMARY THEN 
        UPDATE pig_farm SET 
            last_summary_report_id = cur_pig_farm_report_id
        WHERE id = in_pig_farm_id;
    END IF;
    
ELSE
    UPDATE pig_farm_report SET 
        file_path           = in_file_path,
        notes               = in_notes,

        last_update_user_id = in_user_id
    WHERE id = cur_pig_farm_report_id;
    
END IF;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_report_id              AS pig_farm_report_id;

END $$

DELIMITER ;
