DELIMITER $$

DROP PROCEDURE IF EXISTS user_register_or_login $$
CREATE PROCEDURE user_register_or_login(
    in_login_social_media_id INT,

    in_name                 VARCHAR(80),
    in_name_last            VARCHAR(50),
    in_name_first           VARCHAR(50),
    
    in_email                VARCHAR(50),
    
    in_login_country_code   VARCHAR(3),  /* This should be in upper case*/
    in_login_country_name   VARCHAR(50),
    in_login_city           VARCHAR(50), /* This should be in upper case*/
    in_login_region         VARCHAR(50), /* This should be in upper case*/
    
    
    in_viewport_width       INT,
    in_viewport_height      INT,
    in_ip_address           VARCHAR(24)            
)  

BEGIN

/** 
 * Will create user entry. This is usually used when a user registers from
 * a mobile app or web application. All parameter input cannot be null or empty.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 8, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE NUM_MINUTES_CODE_EXPIRY                 INT             DEFAULT 5;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;





DECLARE cur_user_unverified_id                  INT             DEFAULT 0;
DECLARE cur_user_verify_id                      INT             DEFAULT 0; 

DECLARE cur_user_verify_code                    INT             DEFAULT NULL;
DECLARE cur_user_verify_code_ts_expiry          BIGINT          DEFAULT 0;
DECLARE cur_user_verify_code_dt_expiry          DATETIME        DEFAULT NULL;
    

DECLARE cur_user_id                             INT             DEFAULT 0;
DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;




DECLARE cur_country_id                          INT             DEFAULT 0;
DECLARE cur_login_loc_trace_id                  INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


/** Save country if not yet saved;*/
SELECT  id
INTO    cur_country_id
FROM    app_country 
WHERE   country_code = in_login_country_code;


IF cur_country_id = 0 THEN 
    INSERT INTO app_country(
        country_code,
        name
    )
    VALUES(
        in_login_country_code,
        in_login_country_name
    );
    
    SELECT LAST_INSERT_ID() INTO cur_country_id;
END IF;



/** Save Ip location trace*/
IF in_login_city IS NOT NULL AND in_login_region IS NOT NULL THEN 
    SELECT  id 
    INTO    cur_login_loc_trace_id
    FROM    user_login_ip_loc_trace
    WHERE   app_country_id      = cur_country_id AND
            ip_loc_trace_city   = in_login_city AND 
            ip_loc_trace_region = in_login_region
    LIMIT   1;

ELSE
    IF in_login_city IS NOT NULL THEN
        SELECT  id 
        INTO    cur_login_loc_trace_id
        FROM    user_login_ip_loc_trace
        WHERE   app_country_id      = cur_country_id AND
                ip_loc_trace_city   = in_login_city AND 
                ip_loc_trace_region = NULL
        LIMIT   1;
    END IF;
    
    IF in_login_region IS NOT NULL THEN
        SELECT  id 
        INTO    cur_login_loc_trace_id
        FROM    user_login_ip_loc_trace
        WHERE   app_country_id      = cur_country_id AND
                ip_loc_trace_region = in_login_region AND 
                ip_loc_trace_city   = NULL
        LIMIT   1;
    END IF;
        
END IF;



IF cur_login_loc_trace_id = 0 THEN 
    INSERT INTO user_login_ip_loc_trace (
        app_country_id,
        ip_loc_trace_city,
        ip_loc_trace_region
    ) VALUES(
        cur_country_id,
        in_login_city,
        in_login_region
    );
    
    SELECT LAST_INSERT_ID() INTO cur_login_loc_trace_id;
END IF;



/* Trust to only to God; everything else is unverified until proven otherwise.*/
/* Only verified emails are inserted into user table; not verified are assumed garbage.*/


/* Check first if email is in the user_unverified*/
SELECT  id
INTO    cur_user_unverified_id
FROM    user_unverified
WHERE   email        = in_email
LIMIT   1;


SELECT  id,
        account_id,
        flag

INTO    cur_user_id,
        cur_user_account_id,
        cur_user_flag

FROM    user
WHERE   email        = in_email
LIMIT   1;



process_user : BEGIN

IF in_login_social_media_id = 0  THEN 


    /* Unverified user signup or login. */
    IF cur_user_unverified_id = 0 AND cur_user_id = 0 THEN 
        /* Insert to user_unverified. */
        INSERT INTO user_unverified(
            email,
            signup_country_id,
            login_count
        ) VALUES (
            in_email,
            cur_country_id,
            1
        );
        SELECT LAST_INSERT_ID() INTO cur_user_unverified_id;
        
      
        
        /* Create verification code to be sent to user email.*/
        SET cur_user_verify_code = ROUND(100000 + RAND() * (999000 - 100000));
            
            
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
            
            
        UPDATE user_unverified SET 
            user_verify_id = cur_user_verify_id
        WHERE id = cur_user_unverified_id;


        SELECT  ts_expiry,
                dt_expiry
                
        INTO    cur_user_verify_code_ts_expiry,
                cur_user_verify_code_dt_expiry
        
        FROM    user_verify
        WHERE   id = cur_user_verify_id;

        LEAVE process_user;
        
    END IF; 

    
    /* Unverified user signup or login again. */
    IF cur_user_unverified_id > 0 AND cur_user_id = 0 THEN
        /* Create verification code to be sent to user email.*/
        SET cur_user_verify_code = ROUND(100000 + RAND() * (999000 - 100000));
            
            
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
            
            
        UPDATE user_unverified SET 
            user_verify_id  = cur_user_verify_id,
            login_count     = login_count + 1
        WHERE id = cur_user_unverified_id;


        SELECT  ts_expiry,
                dt_expiry
                
        INTO    cur_user_verify_code_ts_expiry,
                cur_user_verify_code_dt_expiry
        
        FROM    user_verify
        WHERE   id = cur_user_verify_id;

        LEAVE process_user;
    END IF;
    
    
    
END IF;



/* At this point it is either 
- user login or signup using social media; If user is using social media
to login or signup, it is assumed verified. 

- user already registered and verified.
*/



IF cur_user_id = 0 THEN 
    /* user signup using social media*/

    INSERT INTO user(
        name,
        name_last,
        name_first,
        email,
        
        login_count,
        
        signup_country_id,
        signup_social_media_id
    ) VALUES (
        in_name,
        in_name_last,
        in_name_first,
        in_email,
        
        1,
        
        cur_country_id,
        in_login_social_media_id
    );

    SELECT LAST_INSERT_ID() INTO cur_user_id;
    
    
    UPDATE app_country SET
        signup_count = signup_count + 1
    WHERE id = cur_country_id;


 
    /* No need to send verification code if logging in via social media.*/
 
    SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE + FLAG_BIT_USER_EMAIL_VERIFIED;
    UPDATE user SET
        flag = cur_user_flag
    WHERE id = cur_user_id;



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
        in_login_country_code,
        cur_login_loc_trace_id     
    );

    
    
ELSE
    /* user login using social media*/
    
    UPDATE user SET 
        name                    = in_name,
    
        name_last               = in_name_last,
        name_first              = in_name_first,
        
        login_count             = login_count + 1,
        
        signup_social_media_id  = in_login_social_media_id 
    WHERE id = cur_user_id;
    
    
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
        in_login_country_code,
        cur_login_loc_trace_id     
    );

END IF;


END process_user;




SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id        = cur_user_id;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_id                         AS user_id,
    cur_user_account_id                 AS user_account_id,
    cur_user_flag                       AS user_flag,
    
    cur_user_unverified_id              AS user_unverified_id,
    cur_user_verify_id                  AS user_verify_code_id,                  
    cur_user_verify_code                AS user_verify_code,
    cur_user_verify_code_ts_expiry      AS code_ts_expiry,
    cur_user_verify_code_dt_expiry      AS code_dt_expiry;
    

END $$

DELIMITER ;
