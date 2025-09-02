DELIMITER $$

DROP PROCEDURE IF EXISTS account_request_user_add_approve $$
CREATE PROCEDURE account_request_user_add_approve(
    in_account_request_id       INT,
    in_approving_user_id        INT,
    in_assigned_user_group_id   INT
)

BEGIN

/** 
 * Will approve account_request to add user to account; 
 * This is initiated by the account admin user.
 * @author Jack Wong
 * @since August 11, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;




DECLARE RES_NUM_ACC_REQ_USER_ADD_ALREADY_APPROVED   INT         DEFAULT 20;





DECLARE ACCOUNT_REQUEST_STATUS_ID_PENDING       INT             DEFAULT 1;
DECLARE ACCOUNT_REQUEST_STATUS_ID_APPROVED      INT             DEFAULT 2;
DECLARE ACCOUNT_REQUEST_STATUS_ID_REJECTED      INT             DEFAULT 3;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_acc_req_status_id                   INT             DEFAULT 0;
DECLARE cur_acc_req_account_id                  INT             DEFAULT 0;
DECLARE cur_acc_req_requesting_user_id          INT             DEFAULT 0;
DECLARE cur_acc_req_status_name                 VARCHAR(50)     DEFAULT NULL;
DECLARE cur_acc_req_dt_approved                 DATETIME        DEFAULT NULL;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_approving_user_email                VARCHAR(100)    DEFAULT NULL;
DECLARE cur_approving_user_username             VARCHAR(50)     DEFAULT NULL;
DECLARE cur_approving_user_name_last            VARCHAR(50)     DEFAULT NULL;
DECLARE cur_approving_user_name_first           VARCHAR(50)     DEFAULT NULL;


DECLARE cur_requesting_user_username            VARCHAR(50)     DEFAULT NULL;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        status_id,
        account_id,
        requesting_user_id
INTO    
        cur_acc_req_status_id,
        cur_acc_req_account_id,
        cur_acc_req_requesting_user_id
        
FROM    account_request
WHERE   id = in_account_request_id;


CALL basic_user_check(in_approving_user_id, 1, cur_acc_req_account_id,
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


SELECT  email
INTO    cur_approving_user_email
FROM    user 
WHERE   id = in_approving_user_id;


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_acc_req_status_id = ACCOUNT_REQUEST_STATUS_ID_APPROVED THEN
    SET res_num     = RES_NUM_ACC_REQ_USER_ADD_ALREADY_APPROVED;
    SET res_code    = "RES_NUM_ACC_REQ_USER_ADD_ALREADY_APPROVED";

    LEAVE process_user;
END IF;


UPDATE account_request SET
    status_id           = ACCOUNT_REQUEST_STATUS_ID_APPROVED,
    approved_by_user_id = in_approving_user_id,
    dt_approved         = CURRENT_TIMESTAMP
WHERE id = in_account_request_id;


/* Update approved user. */
UPDATE user SET
    account_id      = cur_acc_req_account_id,
    user_group_id   = in_assigned_user_group_id
WHERE id = cur_acc_req_requesting_user_id;

SELECT  username
INTO    cur_requesting_user_username
FROM    user
WHERE   id = cur_acc_req_requesting_user_id;

/* Insert app_audit_log. */
SET s_desc = CONCAT("User added to account; username = ", cur_requesting_user_username);

INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_approving_user_id,
    cur_acc_req_account_id,
    AUDIT_ACTION_UPDATE,
    s_desc,
    CURRENT_DATE
);


END process_user;


SELECT  
        a.status_id,
        b.name,
        c.username,
        c.name_last,
        c.name_first,
        a.dt_approved
INTO    
        cur_acc_req_status_id,
        cur_acc_req_status_name,
        cur_approving_user_username,
        cur_approving_user_name_last,
        cur_approving_user_name_first,
        cur_acc_req_dt_approved
        
FROM    account_request a 
LEFT OUTER JOIN account_request_status b ON a.status_id = b.id
LEFT OUTER JOIN user c ON a.approved_by_user_id = c.id
WHERE   a.id = in_account_request_id;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_request_id               AS acc_req_id,
    cur_acc_req_status_id               AS acc_req_status_id,
    cur_acc_req_status_name             AS acc_req_status_name,
    
    cur_approving_user_username         AS approving_user_username,
    cur_approving_user_name_last        AS approving_user_name_last,
    cur_approving_user_name_first       AS approving_user_name_first,
    cur_acc_req_dt_approved             AS acc_req_dt_approved,
    
    cur_acc_req_requesting_user_id      AS requesting_user_id,
    cur_approving_user_email                      AS requesting_user_email;


END $$

DELIMITER ;
