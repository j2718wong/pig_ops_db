DELIMITER $$

DROP PROCEDURE IF EXISTS user_internal_login $$
CREATE PROCEDURE user_internal_login(
    in_email                VARCHAR(50)
            
)  

BEGIN


/** 
 * This is used for internal user login. By default Normal SuperPig users cannot be
 * an internal user; and internal users cannot login to Superpig. This is current 
 * design until there is a chnage.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 12, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_INVALID_EMAIL                   INT             DEFAULT 20;
DECLARE RES_NUM_INVALID_USER                    INT             DEFAULT 21;
DECLARE RES_NUM_INVALID_ACCOUNT                 INT             DEFAULT 22;

DECLARE NUM_MINUTES_CODE_EXPIRY                 INT             DEFAULT 5;


/* account.flag bits
bit 0: FLAG_BIT_ACCOUNT_ENABLE
bit 1: FLAG_BIT_FREE_TRIAL_STARTED
bit 2:
bit 3:  

bit 4: FLAG_BIT_ACCOUNT_IS_BILL_EXEMPTED
0 = not exempted has to pay bill
1 = exempted, no need to compute bill

bit 5: FLAG_BIT_ACCOUNT_IS_TEST_ACCOUNT
bit 6: FLAG_BIT_ACCOUNT_IS_COMPANY_OWNED

*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_FREE_TRIAL_STARTED             INT             DEFAULT 2;


DECLARE FLAG_BIT_ACCOUNT_IS_BILL_EXEMPTED       INT             DEFAULT 16;
DECLARE FLAG_BIT_ACCOUNT_IS_TEST_ACCOUNT        INT             DEFAULT 32;
DECLARE FLAG_BIT_ACCOUNT_IS_COMPANY_OWNED       INT             DEFAULT 64;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;
DECLARE FLAG_BIT_USER_IS_INTERNAL_DATA_ENTRY    INT             DEFAULT 32;
DECLARE FLAG_BIT_USER_IS_INTERNAL_FINANCE       INT             DEFAULT 64;
DECLARE FLAG_BIT_USER_IS_TEST_USER              INT             DEFAULT 128;

DECLARE FLAG_BIT_USER_IS_SYS_ADMIN              INT             DEFAULT 256;



DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT NULL;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT NULL;


DECLARE cur_user_verify_id                      INT             DEFAULT 0; 

DECLARE cur_user_verify_code                    INT             DEFAULT NULL;
DECLARE cur_user_verify_code_ts_expiry          BIGINT          DEFAULT 0;
DECLARE cur_user_verify_code_dt_expiry          DATETIME        DEFAULT NULL;
    

DECLARE cur_user_id                             INT             DEFAULT 0;
DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


DECLARE cur_account_flag                        INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


process_user : BEGIN


SELECT  id,
        account_id,
        flag

INTO    cur_user_id,        
        cur_user_account_id,
        cur_user_flag      
        
FROM user
WHERE email = in_email;


/* Check user email if existing*/
IF cur_user_id = 0 THEN 
    SET res_num     = RES_NUM_INVALID_EMAIL;
    SET res_code    = "RES_NUM_INVALID_EMAIL";
    
    LEAVE process_user;

END IF;


/* Check for inactive user flag*/
IF (cur_user_flag & FLAG_BIT_USER_IS_ACTIVE) = 0 THEN 
    SET res_num     = RES_NUM_INVALID_USER;
    SET res_code    = "RES_NUM_INVALID_USER";
    
    LEAVE process_user;

END IF;


/* Check for deleted user flag*/
IF (cur_user_flag & FLAG_BIT_USER_IS_DELETED) > 0 THEN 
    SET res_num     = RES_NUM_INVALID_USER;
    SET res_code    = "RES_NUM_INVALID_USER";
    
    LEAVE process_user;

END IF;


/* Check for invalid account */
IF cur_user_account_id IS NULL OR cur_user_account_id = 0 THEN 
    SET res_num     = RES_NUM_INVALID_ACCOUNT;
    SET res_code    = "RES_NUM_INVALID_ACCOUNT";
    
    LEAVE process_user;

END IF;



SELECT  flag
INTO    cur_account_flag
FROM    account
WHERE   id = cur_user_account_id;


/* Check user account is company owned (internal account)*/
IF cur_account_flag & FLAG_BIT_ACCOUNT_IS_COMPANY_OWNED = 0 THEN 
    SET res_num     = RES_NUM_INVALID_ACCOUNT;
    SET res_code    = "RES_NUM_INVALID_ACCOUNT";
    
    LEAVE process_user;

END IF; 




IF  (cur_user_flag & FLAG_BIT_USER_IS_SYS_ADMIN) = 0 THEN 

    /* Check for valid internal user flags*/
    /* FLAG_BIT_USER_IS_INTERNAL_DATA_ENTRY + FLAG_BIT_USER_IS_INTERNAL_FINANCE = 96*/
    IF (cur_user_flag & 96) = 0 THEN 
        SET res_num     = RES_NUM_INVALID_USER;
        SET res_code    = "RES_NUM_INVALID_USER";
        
        LEAVE process_user;

    END IF;

END IF;




/* Create verification code to be sent to user email.*/
SET cur_user_verify_code = FLOOR(100000 + RAND() * 900000);
    
    
/* Add NUM_MINUTES_CODE_EXPIRY from NOW*/ 
INSERT INTO user_verify(
    email,
    auth_code,
    ts_expiry,
    dt_expiry
) VALUES (
    in_email,
    cur_user_verify_code,
    UNIX_TIMESTAMP(DATE_ADD(NOW(), INTERVAL NUM_MINUTES_CODE_EXPIRY MINUTE)),  /* UNIX timestamp expiry */
    DATE_ADD(NOW(), INTERVAL NUM_MINUTES_CODE_EXPIRY MINUTE)                   /* Datetime expiry */
);
SELECT LAST_INSERT_ID() INTO cur_user_verify_id;
    

SELECT  ts_expiry,
        dt_expiry
        
INTO    cur_user_verify_code_ts_expiry,
        cur_user_verify_code_dt_expiry

FROM    user_verify
WHERE   id = cur_user_verify_id;


END process_user;




SELECT 
    res_num                         AS result_number,
    res_code                        AS result_code,
    res_desc                        AS result_desc,
        
    cur_user_id                     AS user_id,
    cur_user_account_id             AS user_account_id,
    cur_user_flag                   AS user_flag,

    cur_user_verify_id              AS user_verify_code_id,                  
    cur_user_verify_code            AS user_verify_code,
    cur_user_verify_code_ts_expiry  AS code_ts_expiry,
    cur_user_verify_code_dt_expiry  AS code_dt_expiry,
    NUM_MINUTES_CODE_EXPIRY         AS expiry_minutes;
    

END $$

DELIMITER ;
