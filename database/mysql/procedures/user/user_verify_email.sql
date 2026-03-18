DELIMITER $$

DROP PROCEDURE IF EXISTS user_verify_email $$
CREATE PROCEDURE user_verify_email(
    in_unverified_user_id   INT, /* Only one of this is not NULL and > 0. */
    in_user_id              INT, /* Only one of this is not NULL and > 0. */
    
    in_auth_code            INT,
    
    in_viewport_width       INT,
    in_viewport_height      INT,
    
    in_ip_address           VARCHAR(24)
    
)

BEGIN

/** 
 * Will verify  user email.
 * @author Jack Wong
 * @since March 4, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_CANNOT_FIND_VERIFICATION        INT             DEFAULT 1;
DECLARE RES_NUM_INVALID_CODE                    INT             DEFAULT 2;
DECLARE RES_NUM_CODE_EXPIRED                    INT             DEFAULT 3;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;




DECLARE cur_unix_timestamp                      BIGINT          DEFAULT 0;


DECLARE cur_user_verify_id                      INT             DEFAULT 0;
DECLARE cur_user_signup_country_id              INT             DEFAULT 0;
DECLARE cur_user_login_loc_trace_id             INT             DEFAULT 0;
        
DECLARE cur_user_email                          VARCHAR(50)     DEFAULT 0;
DECLARE cur_user_verify_code                    INT             DEFAULT 0;
DECLARE cur_user_verify_ts_expiry               BIGINT          DEFAULT 0;


DECLARE cur_user_id                             INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET cur_unix_timestamp      = UNIX_TIMESTAMP();


IF in_unverified_user_id > 0  THEN 
    SELECT  a.user_verify_id,
            a.signup_country_id,
            a.login_loc_trace_id,
            
            b.email,
            b.auth_code,
            b.ts_expiry
     
    INTO    
            cur_user_verify_id,
            cur_user_signup_country_id,
            cur_user_login_loc_trace_id,
            
            cur_user_email,
            cur_user_verify_code,
            cur_user_verify_ts_expiry
    FROM    user_unverified a
    LEFT OUTER JOIN  user_verify b ON a.user_verify_id = b.id   
    WHERE   a.id = in_unverified_user_id;


ELSE
    SELECT  a.last_user_verify_id,
            
            b.auth_code,
            b.ts_expiry
     
    INTO    
            cur_user_verify_id,
            
            cur_user_verify_code,
            cur_user_verify_ts_expiry
    FROM    user a
    LEFT OUTER JOIN  user_verify b ON a.last_user_verify_id = b.id   
    WHERE   a.id = in_user_id;

END IF;


SET res_num      = 0;
SET res_code     = 'SUCCESS';
        



process_user : BEGIN

IF cur_user_verify_id = 0 THEN 
    SET res_num     = RES_NUM_CANNOT_FIND_VERIFICATION;
    SET res_code    = "RES_NUM_CANNOT_FIND_VERIFICATION";
    
    LEAVE process_user;
END IF;

            
IF cur_user_verify_code = in_auth_code THEN 
    IF cur_unix_timestamp > cur_user_verify_ts_expiry THEN 
        SET res_num      = RES_NUM_CODE_EXPIRED;
        SET res_code     = 'RES_NUM_CODE_EXPIRED';
    ELSE
        
        /* Update code verification*/
        UPDATE user_verify SET
            dt_verified         = CURRENT_TIMESTAMP
        WHERE id = cur_user_verify_id;
        
        
        IF in_unverified_user_id > 0 THEN 
            /* Covert user from unverified user to verified user.*/
            SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE + FLAG_BIT_USER_EMAIL_VERIFIED;
        

            INSERT INTO user(
                email,
                
                flag,
                login_count,
                
                signup_country_id
            ) VALUES (
                cur_user_email,
                
                cur_user_flag,
                1,
                
                cur_user_signup_country_id
            );

            SELECT LAST_INSERT_ID() INTO cur_user_id;
            
            
            UPDATE app_country SET
                signup_count = signup_count + 1
            WHERE id = cur_user_signup_country_id;



            /** Will also create a user_login entry and user should be automatically logged in*/
            INSERT INTO user_login(
                user_id,
                
                viewport_width,
                viewport_height,
                
                ip_address,
                country_code_login,
                login_loc_trace_id
            ) 
            VALUES (
                cur_user_id,
                
                in_viewport_width,
                in_viewport_height,
                
                in_ip_address,
                cur_user_signup_country_id,
                cur_user_login_loc_trace_id     
            );


            /* Delete unverified user*/
            DELETE FROM user_unverified 
            WHERE id = in_unverified_user_id;
        
        ELSE
            SET cur_user_id = in_user_id;
        
        END IF;
        
        
    END IF;
ELSE
    SET res_num      = RES_NUM_INVALID_CODE;
    SET res_code     = 'RES_NUM_INVALID_CODE';
END IF;



END process_user;


SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id = cur_user_id;
    

SELECT  
    res_num                     AS result_num,
    res_code                    AS result_code,
    res_desc                    AS result_desc,
    
    cur_user_id                 AS user_id,
    cur_user_flag               AS user_flag;

END $$

DELIMITER ;
