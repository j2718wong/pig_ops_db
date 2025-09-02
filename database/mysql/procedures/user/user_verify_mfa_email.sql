DELIMITER $$

DROP PROCEDURE IF EXISTS user_verify_mfa_email $$
CREATE PROCEDURE user_verify_mfa_email(
    in_user_id                  INT,
    in_auth_code                INT
)

BEGIN

/** 
 * Will verify multi factor auth entry for user email.
 * @author Jack Wong
 * @since January 4, 2024
 *
 */


DECLARE RES_NUM_VERIFIED                        INT             DEFAULT 0;
DECLARE RES_NUM_EMAIL_ALREADY_VERIFIED          INT             DEFAULT 1;
DECLARE RES_NUM_MFA_INVALID_CODE                INT             DEFAULT 2;
DECLARE RES_NUM_MFA_EXPIRED                     INT             DEFAULT 3;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;




DECLARE cur_unix_timestamp                      BIGINT          DEFAULT 0;

DECLARE cur_mfa_id                              INT             DEFAULT 0;
DECLARE cur_mfa_auth_code                       INT             DEFAULT 0;
DECLARE cur_mfa_ts_expiry                       BIGINT          DEFAULT 0;

DECLARE cur_user_flag                           INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET cur_unix_timestamp      = UNIX_TIMESTAMP();

SELECT      
        flag,
        last_mfa_id_email_verify 
INTO    
        cur_user_flag,
        cur_mfa_id
FROM    user  
WHERE   id = in_user_id;


process_user : BEGIN

IF cur_user_flag & FLAG_BIT_USER_EMAIL_VERIFIED > 0 THEN 
    SET res_num     = RES_NUM_EMAIL_ALREADY_VERIFIED;
    SET res_code    = "RES_NUM_EMAIL_ALREADY_VERIFIED";
    
    LEAVE process_user;
END IF;

IF cur_mfa_id > 0 THEN 
    SELECT 
        auth_code,
        ts_expiry
    INTO 
        cur_mfa_auth_code,
        cur_mfa_ts_expiry
    FROM app_mfa
    WHERE id = cur_mfa_id;
            
    IF cur_mfa_auth_code = in_auth_code THEN 
        IF cur_unix_timestamp > cur_mfa_ts_expiry THEN 
            SET res_num      = RES_NUM_MFA_EXPIRED;
            SET res_code     = 'RES_NUM_MFA_EXPIRED';
        ELSE
            SET res_num      = RES_NUM_VERIFIED;
            SET res_code     = 'RES_NUM_VERIFIED';
            
            /* Update MFA*/
            UPDATE app_mfa SET
                dt_verified         = CURRENT_TIMESTAMP
            WHERE id = cur_mfa_id;
            
            /* Update user*/
            UPDATE user SET
                flag   = flag | FLAG_BIT_USER_EMAIL_VERIFIED | FLAG_BIT_USER_IS_ACTIVE
            WHERE id = in_user_id;
            
        END IF;
    ELSE
        SET res_num      = RES_NUM_MFA_INVALID_CODE;
        SET res_code     = 'RES_NUM_MFA_INVALID_CODE';
    END IF;
    
    
END IF;

END process_user;


SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id = in_user_id;
    

SELECT  
    res_num                     AS result_num,
    res_code                    AS result_code,
    res_desc                    AS result_desc,
    
    in_user_id                  AS user_id,
    cur_user_flag               AS user_flag;

END $$

DELIMITER ;
