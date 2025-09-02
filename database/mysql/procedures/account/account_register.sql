DELIMITER $$

DROP PROCEDURE IF EXISTS account_register $$
CREATE PROCEDURE account_register(
    in_user_id              INT,
    
    in_country_id           INT,
    in_name                 VARCHAR(100)
)  

BEGIN

/** 
 * Will add account entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 8, 2025
 *
 */

DECLARE LOV_ID_ACCOUNT_NUMDAYS_FREE_TRIAL       INT             DEFAULT 1;


DECLARE RES_NUM_SUCCESS                             INT         DEFAULT 0;

DECLARE RES_NUM_ACCOUNT_ALREADY_REGISTERED_FOR_USER INT         DEFAULT 21;
DECLARE RES_NUM_DUPLICATE_ENTRY                     INT         DEFAULT 22;


DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


DECLARE BUSINESS_OBJ_ID_ACCOUNT                	INT             DEFAULT 2;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;




/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;

DECLARE ACCOUNT_STATUS_ID_ON_TRIAL              INT             DEFAULT 1;
DECLARE ACCOUNT_STATUS_ID_TRIAL_EXPIRED         INT             DEFAULT 2;
DECLARE ACCOUNT_STATUS_ID_UNPAID_BILL           INT             DEFAULT 3;




DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";



DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_account_id                     INT             DEFAULT 0;

DECLARE cur_num_days_trial                      INT             DEFAULT 0;


DECLARE cur_account_id                          INT             DEFAULT 0;
DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;
DECLARE cur_account_status_name                 VARCHAR(50);
DECLARE cur_account_name                        VARCHAR(100); 
DECLARE cur_account_date_trial_start            DATE;
DECLARE cur_account_date_trial_end              DATE;

DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    0, /* user has no account yet*/
    0,
    
    BUSINESS_OBJ_ID_ACCOUNT,
    FLAG_BIT_OPERATION_ADD,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN


IF cur_user_account_id > 0 THEN
    SET res_num     = RES_NUM_ACCOUNT_ALREADY_REGISTERED_FOR_USER;
    SET res_code    = "RES_NUM_ACCOUNT_ALREADY_REGISTERED_FOR_USER";
    
    LEAVE process_user;
END IF;


SELECT  val_int 
INTO    cur_num_days_trial
FROM    a01_list_of_values
WHERE   id = LOV_ID_ACCOUNT_NUMDAYS_FREE_TRIAL;


/* Check account duplicate. */
SELECT  id
INTO    cur_account_id
FROM    account
WHERE   country_id = in_country_id AND UPPER(name)  = UPPER(in_name)
LIMIT   1;


IF cur_account_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;

END IF;





INSERT INTO account(
    name,
    country_id,
    flag,
    status_id,
    date_trial_start,
    date_trial_end
) VALUES (
    in_name,
    in_country_id,
    1,
    ACCOUNT_STATUS_ID_ON_TRIAL,
    CURRENT_DATE,
    DATE_ADD(CURRENT_DATE, INTERVAL cur_num_days_trial DAY)
);

SELECT LAST_INSERT_ID() INTO cur_account_id;


CALL account_user_groups_create(cur_account_id);


SELECT  id 
INTO    cur_user_group_id
FROM    user_group
WHERE   account_id = cur_account_id AND group_num = 1;


/* The user that registers the account is an account admin. */
UPDATE user SET
    account_id      = cur_account_id,
    user_group_id   = cur_user_group_id,
    flag            = flag | FLAG_BIT_USER_IS_ACCOUNT_ADMIN
WHERE id = in_user_id;


CALL account_gestating_ops_create(cur_account_id);

CALL account_lactating_ops_create(cur_account_id);


/* Insert app_audit_log. */
SET s_desc = CONCAT("Account registered; acc_name = ", in_name);
INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_user_id,
    cur_account_id,
    AUDIT_ACTION_ADD,
    s_desc,
    CURRENT_DATE
); 


SET s_desc = "User set to ACCOUNT ADMIN";
INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_user_id,
    cur_account_id,
    AUDIT_ACTION_ADD,
    s_desc,
    CURRENT_DATE
); 


END process_user;


SELECT
    a.name,
    a.flag,
    a.status_id,
    b.name,
    a.date_trial_start,
    a.date_trial_end
INTO
    cur_account_name,
    cur_account_flag,
    cur_account_status_id,
    cur_account_status_name,
    cur_account_date_trial_start,
    cur_account_date_trial_end
FROM account a
LEFT OUTER JOIN account_status b ON a.status_id = b.id
WHERE a.id = cur_account_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_id                      AS acc_id,
    cur_account_name                    AS acc_name,
    cur_account_flag                    AS acc_flag,
    cur_account_status_id               AS acc_status_id,
    cur_account_status_name             AS acc_status_name,
    cur_account_date_trial_start        AS date_trial_start,
    cur_account_date_trial_end          AS date_trial_end;

END $$

DELIMITER ;
