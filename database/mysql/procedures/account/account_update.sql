DELIMITER $$

DROP PROCEDURE IF EXISTS account_update $$
CREATE PROCEDURE account_update(
    in_user_id                  INT,
    
    in_name                     VARCHAR(100)
    
)

BEGIN

/** 
 * Will update account
 * @author Jack Wong
 * @since August 10, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;
DECLARE RES_NUM_USER_IS_INACTIVE                INT             DEFAULT 1;
DECLARE RES_NUM_USER_HAS_NO_ACCOUNT             INT             DEFAULT 2;
DECLARE RES_NUM_ACCOUNT_DISABLED                INT             DEFAULT 3;
DECLARE RES_NUM_ACCOUNT_STATUS_TRIAL_EXPIRED    INT             DEFAULT 4;
DECLARE RES_NUM_ACCOUNT_STATUS_UNPAID_BILL      INT             DEFAULT 5;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;


DECLARE BUSINESS_OBJ_ID_ACCOUNT                	INT             DEFAULT 2;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;
DECLARE cur_account_status_name                 VARCHAR(50);
DECLARE cur_account_name                        VARCHAR(100); 
DECLARE cur_account_date_trial_start            DATE;
DECLARE cur_account_date_trial_end              DATE;




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



UPDATE account SET
    name                = in_name,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = cur_user_account_id;


/* Insert app_audit_log. */
SET s_desc = CONCAT("old_acc_name = ", cur_account_name, "; new_acc_name = ",
    in_name);

INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_user_id,
    cur_user_account_id,
    AUDIT_ACTION_UPDATE,
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
WHERE a.id = cur_user_account_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS acc_id,
    cur_account_name                    AS acc_name,
    cur_account_flag                    AS acc_flag,
    cur_account_status_id               AS acc_status_id,
    cur_account_status_name             AS acc_status_name,
    cur_account_date_trial_start        AS date_trial_start,
    cur_account_date_trial_end          AS date_trial_end;




END $$

DELIMITER ;
