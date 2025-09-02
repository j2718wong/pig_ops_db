DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_staff_delete $$
CREATE PROCEDURE pig_farm_staff_delete(
    in_user_id                  INT,
    
    in_pig_farm_staff_id         INT
)  

BEGIN

/** 
 * Will delete pig_farm_staff entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF           INT            DEFAULT 6;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";

/* pig_farm_staff.flag bits*/
DECLARE FLAG_BIT_PIG_FARM_STAFF_IS_DELETED      INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_staff_account_id           INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_flag                 INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_name                 VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_farm_staff_account_id
FROM    pig_farm_staff
WHERE   id = in_pig_farm_staff_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_staff_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_FARM_STAFF,
    FLAG_BIT_OPERATION_DELETE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



UPDATE pig_farm_staff SET
    flag                = flag | FLAG_BIT_PIG_FARM_STAFF_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_pig_farm_staff_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_staff_flag,
    cur_pig_farm_staff_name
FROM pig_farm_staff
WHERE id = in_pig_farm_staff_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_farm_staff_id                AS pig_farm_staff_id,
    cur_pig_farm_staff_flag             AS pig_farm_staff_flag,
    cur_pig_farm_staff_name             AS pig_farm_staff_name;
    

END $$

DELIMITER ;
