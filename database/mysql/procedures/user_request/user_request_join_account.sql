DELIMITER $$

DROP PROCEDURE IF EXISTS user_request_join_account $$
CREATE PROCEDURE user_request_join_account(
    in_access_code_id           INT,
    in_requesting_user_id       INT
)

BEGIN

/** 
 * @author Jack Wong
 * @since August 11, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_USER_IS_INACTIVE                INT             DEFAULT 1;
DECLARE RES_NUM_USER_NOT_EMAIL_VERIFIED         INT             DEFAULT 2;
DECLARE RES_NUM_USER_NOT_ACCOUNT_ADMIN          INT             DEFAULT 3;
DECLARE RES_NUM_USER_NO_ACCOUNT_SET             INT             DEFAULT 4;

DECLARE RES_NUM_USER_ALREADY_HAS_ACCOUNT        INT             DEFAULT 8;
DECLARE RES_NUM_INVALID_ACCESS_CODE             INT             DEFAULT 9; 

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


DECLARE USER_REQUEST_STATUS_ID_PENDING          INT             DEFAULT 1;
DECLARE USER_REQUEST_STATUS_ID_APPROVED         INT             DEFAULT 2;
DECLARE USER_REQUEST_STATUS_ID_REJECTED         INT             DEFAULT 3;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_email                          VARCHAR(100);

DECLARE cur_access_code_account_id              INT             DEFAULT 0;
DECLARE cur_access_code_user_group_id           INT             DEFAULT 0;
DECLARE cur_access_code_used_by_user_id         INT             DEFAULT 0;


DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;
DECLARE cur_account_default_farm_id             INT             DEFAULT 0;
 



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        flag,
        email
        
INTO    cur_user_account_id,
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



IF cur_user_account_id > 0 THEN 
    SET res_num     = RES_NUM_USER_ALREADY_HAS_ACCOUNT;
    SET res_code    = "RES_NUM_USER_ALREADY_HAS_ACCOUNT";

    LEAVE process_user;
END IF;



SELECT  account_id,
        user_group_id,
        used_by_user_id
        
INTO    cur_access_code_account_id,
        cur_access_code_user_group_id,
        cur_access_code_used_by_user_id

FROM    account_access_code

WHERE id = in_access_code_id;


IF cur_access_code_used_by_user_id > 0 THEN 
    SET res_num     = RES_NUM_INVALID_ACCESS_CODE;
    SET res_code    = "RES_NUM_INVALID_ACCESS_CODE";
    SET res_desc    = "Already Used";
    
    LEAVE process_user;
END IF;

    

/* Check account*/
SELECT 
    flag,
    status_id,
    default_farm_id
    name
INTO
    cur_account_flag,
    cur_account_status_id,
    cur_account_default_farm_id
    
FROM account
WHERE id = cur_access_code_account_id;


IF cur_account_flag & FLAG_BIT_ACCOUNT_ENABLE = 0 THEN 
    SET res_num     = RES_NUM_ACCOUNT_DISABLED;
    SET res_code    = "RES_NUM_ACCOUNT_DISABLED";
    
    IF cur_account_status_id = ACCOUNT_STATUS_ID_UNPAID_BILL THEN
        SET res_num     = RES_NUM_ACCOUNT_STATUS_UNPAID_BILL;
        SET res_code    = "RES_NUM_ACCOUNT_STATUS_UNPAID_BILL";
    
    END IF;
    
    LEAVE process_user;
END IF;




/* Update User*/
UPDATE user SET 
    account_id              = cur_access_code_account_id,
    user_group_id           = cur_access_code_user_group_id,
    account_access_code_id  = in_access_code_id
WHERE 
    id = in_requesting_user_id;

INSERT INTO user_pig_farm(
    pig_farm_id,
    user_id,
    added_by_user_id
) VALUES(
    cur_account_default_farm_id,
    in_requesting_user_id,
    in_requesting_user_id
);



/* Update account_access_code*/
UPDATE account_access_code SET
    used_by_user_id = in_requesting_user_id
WHERE id = in_access_code_id;



END process_user;


SELECT  account_id
INTO    cur_user_account_id
FROM    user
WHERE   id =  in_requesting_user_id;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS user_account_id,
    cur_user_email                      AS user_email;


END $$

DELIMITER ;
