DELIMITER $$

DROP PROCEDURE IF EXISTS user_resend_verify_code $$
CREATE PROCEDURE user_resend_verify_code(
    in_unverified_user_id   INT
    
)

BEGIN

/** 
 * Will create user_verify entry.
 * @author Jack Wong
 * @since March 17, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE NUM_MINUTES_CODE_EXPIRY                 INT             DEFAULT 5;



DECLARE RES_NUM_CANNOT_FIND_VERIFICATION        INT             DEFAULT 1;



/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;



DECLARE cur_user_verify_id                      INT             DEFAULT 0;
DECLARE cur_user_email                          VARCHAR(50)     DEFAULT 0;


DECLARE cur_user_verify_code                    INT             DEFAULT 0;
DECLARE cur_user_verify_code_ts_expiry          BIGINT          DEFAULT 0;
DECLARE cur_user_verify_code_dt_expiry          DATETIME        DEFAULT NULL;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';




SELECT  user_verify_id,
        email
 
INTO    
        cur_user_verify_id,
        cur_user_email
FROM    user_unverified 
  
WHERE   id = in_unverified_user_id;


SET res_num      = 0;
SET res_code     = 'SUCCESS';
        



process_user : BEGIN

IF cur_user_verify_id = 0 THEN 
    SET res_num     = RES_NUM_CANNOT_FIND_VERIFICATION;
    SET res_code    = "RES_NUM_CANNOT_FIND_VERIFICATION";
    
    LEAVE process_user;
END IF;


/* Create verification code to be sent to user email.*/
SET cur_user_verify_code = ROUND(100000 + RAND() * (999000 - 100000));
    
    
/* Add NUM_MINUTES_CODE_EXPIRY from NOW*/ 
INSERT INTO user_verify(
    email,
    auth_code,
    ts_expiry,
    dt_expiry
) VALUES (
    cur_user_email,
    cur_user_verify_code,
    UNIX_TIMESTAMP(DATE_ADD(NOW(), INTERVAL NUM_MINUTES_CODE_EXPIRY MINUTE)),  /* UNIX timestamp expiry */
    DATE_ADD(NOW(), INTERVAL NUM_MINUTES_CODE_EXPIRY MINUTE)                   /* Datetime expiry */
);
SELECT LAST_INSERT_ID() INTO cur_user_verify_id;
    
    
UPDATE user_unverified SET 
    user_verify_id = cur_user_verify_id
WHERE id = in_unverified_user_id;


SELECT  ts_expiry,
        dt_expiry
        
INTO    cur_user_verify_code_ts_expiry,
        cur_user_verify_code_dt_expiry

FROM    user_verify
WHERE   id = cur_user_verify_id;


      
      
END process_user;


    

SELECT  
    res_num                         AS result_num,
    res_code                        AS result_code,
    res_desc                        AS result_desc,
    
    0                               AS user_id,
    0                               AS user_account_id,
    0                               AS user_flag,
    
    in_unverified_user_id           AS user_unverified_id,
    cur_user_verify_id              AS user_verify_code_id,                  
    cur_user_verify_code            AS user_verify_code,
    cur_user_verify_code_ts_expiry  AS code_ts_expiry,
    cur_user_verify_code_dt_expiry  AS code_dt_expiry,
    NUM_MINUTES_CODE_EXPIRY         AS expiry_minutes,
    
    cur_user_email                  AS user_email;

END $$

DELIMITER ;
