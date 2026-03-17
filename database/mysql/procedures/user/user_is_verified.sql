DELIMITER $$

DROP PROCEDURE IF EXISTS user_is_verified $$
CREATE PROCEDURE user_is_verified(
    in_user_unverified_id   INT,
    
    in_viewport_width       INT,
    in_viewport_height      INT,
    in_ip_address           VARCHAR(24)
)  

BEGIN

/** 
 * Will create user login entry. 
 *
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since March 1, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


DECLARE cur_user_id                             INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_login_id                       INT             DEFAULT 0;


DECLARE cur_user_signup_country_id              INT             DEFAULT 0;
DECLARE cur_user_signup_country_code            VARCHAR(5)      DEFAULT NULL;
DECLARE cur_user_login_loc_trace_id             INT             DEFAULT 0;
DECLARE cur_user_email                          VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";





process_user : BEGIN

SELECT 
    a.signup_country_id,
    b.country_code,
    a.login_loc_trace_id,
    a.email 
INTO 
    cur_user_signup_country_id,
    cur_user_signup_country_code,
    cur_user_login_loc_trace_id,
    cur_user_email
FROM user_unverified a
LEFT OUTER JOIN app_country b ON a.signup_country_id = b.id
WHERE a.id = in_user_unverified_id;


IF cur_user_email IS NOT NULL THEN 
    SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE + FLAG_BIT_USER_EMAIL_VERIFIED;

    INSERT INTO user(
        email,
        
        flag,
        login_count
    )
    VALUES (
        cur_user_email,
        
        cur_user_flag,
        1
    );
    
    SELECT LAST_INSERT_ID() INTO cur_user_id;
    
    
    DELETE FROM user_unverified
    WHERE id = in_user_unverified_id;
    
    
    UPDATE app_country SET
        signup_count = signup_count + 1
    WHERE id = cur_country_id;
    
    
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
        cur_user_signup_country_code,
        cur_user_login_loc_trace_id     
    );
    
END IF;



SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id        = cur_user_id;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_id                         AS user_id,
    0                                   AS user_account_id,
    cur_user_flag                       AS user_flag;



END process_user;



SELECT 
    
    cur_user_login_id                   AS user_login_id;
    

END $$

DELIMITER ;
