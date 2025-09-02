DELIMITER $$

DROP PROCEDURE IF EXISTS account_request_user_add $$
CREATE PROCEDURE account_request_user_add(
    in_account_id               INT,
    in_requesting_user_id       INT
)

BEGIN

/** 
 * Will add account_request; this is initiated by the user.
 * @author Jack Wong
 * @since August 11, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_USER_IS_INACTIVE                INT             DEFAULT 1;
DECLARE RES_NUM_USER_NOT_EMAIL_VERIFIED         INT             DEFAULT 2;
DECLARE RES_NUM_USER_NOT_ACCOUNT_ADMIN          INT             DEFAULT 3;
DECLARE RES_NUM_USER_NO_ACCOUNT_SET             INT             DEFAULT 4;

DECLARE RES_NUM_ACCOUNT_DISABLED                INT             DEFAULT 11;
DECLARE RES_NUM_ACCOUNT_STATUS_TRIAL_EXPIRED    INT             DEFAULT 12;
DECLARE RES_NUM_ACCOUNT_STATUS_UNPAID_BILL      INT             DEFAULT 13;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 50;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;


DECLARE ACCOUNT_STATUS_ID_ON_TRIAL              INT             DEFAULT 1;
DECLARE ACCOUNT_STATUS_ID_TRIAL_EXPIRED         INT             DEFAULT 2;
DECLARE ACCOUNT_STATUS_ID_UNPAID_BILL           INT             DEFAULT 3;


DECLARE ACCOUNT_REQUEST_STATUS_ID_PENDING       INT             DEFAULT 1;
DECLARE ACCOUNT_REQUEST_STATUS_ID_APPROVED      INT             DEFAULT 2;
DECLARE ACCOUNT_REQUEST_STATUS_ID_REJECTED      INT             DEFAULT 3;



DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_email                          VARCHAR(100);


DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;
DECLARE cur_account_name                        VARCHAR(100); 
DECLARE cur_account_date_trial_start            DATE;
DECLARE cur_account_date_trial_end              DATE;

DECLARE cur_account_req_id                      INT             DEFAULT 0;
DECLARE cur_account_req_status_id               INT             DEFAULT 0;
DECLARE cur_account_req_status_name             VARCHAR(50)     DEFAULT '';



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        flag,
        email
INTO    
        cur_user_flag,
        cur_user_email
FROM    user 
WHERE   id = in_requesting_user_id;


process_user : BEGIN

/* Check user*/
IF cur_user_flag & FLAG_BIT_USER_IS_ACTIVE = 0 THEN 
    SET res_num     = RES_NUM_USER_IS_INACTIVE;
    SET res_code    = "RES_NUM_USER_IS_INACTIVE";

    LEAVE process_user;
END IF;

IF cur_user_flag & FLAG_BIT_USER_EMAIL_VERIFIED = 0 THEN 
    SET res_num     = RES_NUM_USER_NOT_EMAIL_VERIFIED;
    SET res_code    = "RES_NUM_USER_NOT_EMAIL_VERIFIED";

    LEAVE process_user;    
END IF;



/* Check account*/
SELECT 
    flag,
    status_id,
    name
INTO
    cur_account_flag,
    cur_account_status_id,
    cur_account_name
    
FROM account
WHERE id = in_account_id;


IF cur_account_flag & FLAG_BIT_ACCOUNT_ENABLE = 0 THEN 
    SET res_num     = RES_NUM_ACCOUNT_DISABLED;
    SET res_code    = "RES_NUM_ACCOUNT_DISABLED";
    
    IF cur_account_status_id = ACCOUNT_STATUS_ID_UNPAID_BILL THEN
        SET res_num     = RES_NUM_ACCOUNT_STATUS_UNPAID_BILL;
        SET res_code    = "RES_NUM_ACCOUNT_STATUS_UNPAID_BILL";
    
    END IF;
    
    LEAVE process_user;
END IF;


/* Check duplicate. */
SELECT  id 
INTO    cur_account_req_id
FROM    account_request
WHERE   account_id = in_account_id and requesting_user_id = in_requesting_user_id
LIMIT   1;


IF cur_account_req_id > 0 THEN
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


INSERT INTO account_request(
    account_id,
    requesting_user_id,
    status_id
) VALUES (
    in_account_id,
    in_requesting_user_id,
    ACCOUNT_REQUEST_STATUS_ID_PENDING
);

SELECT LAST_INSERT_ID() INTO cur_account_req_id;


END process_user;


SELECT
    a.status_id,
    b.name
INTO 
    cur_account_req_status_id,
    cur_account_req_status_name
FROM account_request a 
LEFT OUTER JOIN account_request_status b ON a.status_id = b.id
WHERE a.id = in_account_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_req_id                  AS acc_req_id,
    cur_account_req_status_id           AS acc_req_status_id,
    cur_account_req_status_name         AS acc_req_status_name;


END $$

DELIMITER ;
