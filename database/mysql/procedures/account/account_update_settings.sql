DELIMITER $$

DROP PROCEDURE IF EXISTS account_update_settings $$
CREATE PROCEDURE account_update_settings(
    in_user_id                  INT,
    
    in_day_1_on_dob             INT
    
)

BEGIN

/** 
 * Will update account
 * @author Jack Wong
 * @since September 13, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;


DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* account.flag_settings bits*/
/* If this is SET, day 1 counting will start on date of birth; otherwise next day after birth.*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_flag_settings               INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";

CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, 
    
    BUSINESS_OBJ_ID_ACCOUNT,
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
WHERE   id = cur_user_account_id;

IF in_day_1_on_dob > 0 THEN  
    SET cur_account_flag_settings = cur_account_flag_settings | FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH;
ELSE
    SET cur_account_flag_settings = cur_account_flag_settings & ~FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH;
END IF;


UPDATE account SET
    flag_settings       = cur_account_flag_settings,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = cur_user_account_id;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS acc_id;

END $$

DELIMITER ;
