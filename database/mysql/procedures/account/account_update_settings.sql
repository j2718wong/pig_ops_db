DELIMITER $$

DROP PROCEDURE IF EXISTS account_update_settings $$
CREATE PROCEDURE account_update_settings(
    in_user_id                  INT,
    
    in_day_1_on_dob             INT,
    in_day_1_on_insem           INT,
    
    in_days_wean                INT,
    
    in_days_harvest_from_birth  INT,
    in_days_harvest_from_wean   INT
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


/* account.flag_setting bits
FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH
0 = Date of birth is counted as DAY 0
1 = Date of birth is counted as DAY 1; default

FLAG_BIT_DAY_1_ON_DATE_OF_INSEM
0 = Date of insemination is counted as DAY 0; default
1 = Date of insemination is counted as DAY 1;


*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_flag_settings               INT             DEFAULT 0;

DECLARE cur_account_days_wean                   INT             DEFAULT 0;
DECLARE cur_account_days_harvest_from_birth     INT             DEFAULT NULL;
DECLARE cur_account_days_harvest_from_wean      INT             DEFAULT NULL;
    
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT NULL;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT NULL;
DECLARE cur_account_settings_update             DATETIME        DEFAULT NULL;


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

IF in_day_1_on_insem > 0 THEN 
    SET cur_account_flag_settings = cur_account_flag_settings | FLAG_BIT_DAY_1_ON_DATE_OF_INSEM;
ELSE
    SET cur_account_flag_settings = cur_account_flag_settings & ~FLAG_BIT_DAY_1_ON_DATE_OF_INSEM;
END IF;



UPDATE account SET
    flag_settings           	= cur_account_flag_settings,
    num_days_wean           	= in_days_wean,
    num_days_harvest_from_birth = in_days_harvest_from_birth,
    num_days_harvest_from_wean  = in_days_harvest_from_wean,
    
    last_update_settings_user_id     = in_user_id,
    dt_last_update_settings          = CURRENT_TIMESTAMP
WHERE id = cur_user_account_id;



END process_user;

SELECT 
    a.flag_settings,
    a.num_days_wean,
    a.num_days_harvest_from_birth,
    a.num_days_harvest_from_wean,
    
    b.name_last,
    b.name_first,
    a.dt_last_update_settings
    
INTO 
    cur_account_flag_settings,
    cur_account_days_wean,
    cur_account_days_harvest_from_birth,
    cur_account_days_harvest_from_wean,
    
    cur_user_name_last,
    cur_user_name_first,
    cur_account_settings_update

FROM account a 
LEFT OUTER JOIN user b ON a.last_update_settings_user_id = b.id

WHERE a.id = cur_user_account_id;
    

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_flag_settings           AS account_flag_settings,
    cur_account_days_wean               AS days_wean,
    cur_account_days_harvest_from_birth AS days_harvest_from_birth,
    cur_account_days_harvest_from_wean  AS days_harvest_from_wean,
    
    cur_user_name_last                  AS user_name_last,
    cur_user_name_first                 AS user_name_first,
    cur_account_settings_update         AS settings_update;
    

END $$

DELIMITER ;
