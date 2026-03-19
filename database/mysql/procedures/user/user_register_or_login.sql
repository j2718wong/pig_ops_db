DELIMITER $$

DROP PROCEDURE IF EXISTS user_register_or_login $$
CREATE PROCEDURE user_register_or_login(
    in_login_social_media_id INT,
    in_social_media_user_id VARCHAR(120),/* This should be NULL if in_login_social_media_id is 0 or NULL*/

    in_acc_access_code_id   INT,


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
2026-03-18: Notes on login without email or social media.

1.) The previous flow of users who wish to join a pig farm account is
- create user (via email or social media).
- then request an account access; these users need to input the account code of the farm account.
- then the account owner codes access to the user via user_request table.
- this is the default flow and is working.


User creation via pre approved tokens.
======================================

As of this writing the social media login proves to be challenging as it requires 
business papers and will take time to review the process.

2.) So another solution is explored. Only the account owner (which is likely 
the farm owner or manager) needs an email to register. 


3.) The owner can create pre approved tokens who wants  to access the farm data
and has a pre assigned role.

The user who needs to register this method must provide

1.) user first name - filled up by user
2.) user last name - filled up by user
3.) token_id - this is given by the farm account owner to user. This is saved 
in account_access_code table; 

There is still some deliberation if this is a one-time access and cannot be 
recycled. But as of this writing this is assumed resusable until revoked by farm  
manager.


This access can elevate a user to a Manager or Admin role as well; in this case
there should be a mechanism to force the user to have an email for recovery
purposes.

*/


/** 
 * Will create user entry. This is usually used when a user registers from
 * a mobile app or web application. All parameter input cannot be null or empty.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 8, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_INVALID_ACCESS_CODE            INT             DEFAULT 1;


DECLARE NUM_MINUTES_CODE_EXPIRY                 INT             DEFAULT 5;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;



DECLARE cur_access_code_account_id              INT             DEFAULT 0;
DECLARE cur_access_code_user_group_id           INT             DEFAULT 0;
DECLARE cur_access_code_used_by_user_id         INT             DEFAULT 0;

DECLARE cur_account_default_farm_id             INT             DEFAULT 0;


DECLARE cur_user_unverified_id                  INT             DEFAULT 0;
DECLARE cur_user_verify_id                      INT             DEFAULT 0; 

DECLARE cur_user_verify_code                    INT             DEFAULT NULL;
DECLARE cur_user_verify_code_ts_expiry          BIGINT          DEFAULT 0;
DECLARE cur_user_verify_code_dt_expiry          DATETIME        DEFAULT NULL;
    

DECLARE cur_user_id                             INT             DEFAULT 0;
DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


DECLARE cur_user_login_id                       INT             DEFAULT 0;
DECLARE cur_user_using_social_media_id          INT             DEFAULT 0;


/* Resolves user from either email or social ID */
DECLARE use_this_user_id                        INT             DEFAULT 0;


DECLARE cur_country_id                          INT             DEFAULT 0;
DECLARE cur_login_loc_trace_id                  INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


/** Save country if not yet saved;*/
IF in_login_country_code IS NOT NULL THEN

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



    /** Save IP location trace*/
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

END IF;



/* Trust to only to God; everything else is unverified until proven otherwise.*/
/* Only verified emails are inserted into user table; not verified are assumed garbage.*/


/* Check first if email is in the user_unverified*/
SELECT  id
INTO    cur_user_unverified_id
FROM    user_unverified
WHERE   email        = in_email
LIMIT   1;


/* Check email if already in user table.*/
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


IF in_acc_access_code_id IS NOT NULL THEN 
    SELECT  account_id,
            user_group_id,
            used_by_user_id
    
    INTO    cur_access_code_account_id,
            cur_access_code_user_group_id,
            cur_access_code_used_by_user_id
    
    FROM account_access_code
    WHERE id =  in_acc_access_code_id;
    
    
    IF cur_access_code_account_id = 0 THEN 
        SET res_num     = RES_NUM_INVALID_ACCESS_CODE;
        SET res_code    = "RES_NUM_INVALID_ACCESS_CODE";
    
        LEAVE process_user;
    END IF;
    
    
    /* Get default farm of the account*/
    SELECT  default_farm_id
    INTO    cur_account_default_farm_id
    FROM    account
    WHERE   id = cur_access_code_account_id;
    
    
    
    SELECT  id
    INTO    cur_access_code_user_group_id
    FROM    user_group
    WHERE   account_id = cur_access_code_account_id AND
            group_num = cur_access_code_user_group_id
    LIMIT   1;
    
    
    /** Still DELIBERATION FOR one time access or waht*/
    
    
    
    
    SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE;


    /* User will have an automatic account, from the access_code_account.*/
    INSERT INTO user(
        name_last,
        name_first,
        
        account_id,
        account_access_code_id,
        
        user_group_id,
        
        flag,
        login_count,
        
        signup_country_id,
        signup_social_media_id,
        social_media_user_id
        
    ) VALUES (
        in_name_last,
        in_name_first,
        
        cur_access_code_account_id,
        in_acc_access_code_id,
        
        cur_access_code_user_group_id,
        
        cur_user_flag,
        1,
        
        cur_country_id,
        in_login_social_media_id,
        in_social_media_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_user_id;
    
    
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
        in_login_country_code,
        cur_login_loc_trace_id     
    );
    SELECT LAST_INSERT_ID() INTO cur_user_login_id; 
    
    UPDATE user SET 
        last_user_login_id      = cur_user_login_id
    WHERE id = cur_user_id;

    
    /* Assign user to account default farm.*/
    INSERT INTO user_pig_farm(
        pig_farm_id,
        user_id,
        added_by_user_id
    ) VALUES(
        cur_account_default_farm_id,
        cur_user_id,
        cur_user_id
    );
    
    
    UPDATE account_access_code SET 
        used_by_user_id = cur_user_id
    WHERE id = in_acc_access_code_id;
    
    
    
    /* The user now has the same account_id as access_code.*/
    SET cur_user_account_id     = cur_access_code_account_id;
    
    
    LEAVE process_user;
END IF;





IF in_login_social_media_id IS NULL THEN 
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
        


    /* Unverified user signup or login. */
    IF cur_user_unverified_id = 0 AND cur_user_id = 0 THEN 
        /* Insert to user_unverified. */
        INSERT INTO user_unverified(
            email,
            signup_country_id,
            login_count,
            login_loc_trace_id,
            
            date_signup
        ) VALUES (
            in_email,
            cur_country_id,
            1,
            cur_login_loc_trace_id,
            
            CURRENT_DATE
        );
        SELECT LAST_INSERT_ID() INTO cur_user_unverified_id;
        

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
    
    
    
    /* This is a manual email login; The cur_user_id > 0; this means the user 
    need to input authentication code. Generate Verify code.  
    */
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
    SELECT LAST_INSERT_ID() INTO cur_user_login_id; 
    
    
    
    UPDATE user SET 
        last_user_verify_id     = cur_user_verify_id,
        last_user_login_id      = cur_user_login_id
    WHERE id = cur_user_id;
    
    
    SELECT  ts_expiry,
            dt_expiry
            
    INTO    cur_user_verify_code_ts_expiry,
            cur_user_verify_code_dt_expiry
    
    FROM    user_verify
    WHERE   id = cur_user_verify_id;

    LEAVE process_user;
    
END IF;



/* At this point it is either 
- user login or signup using social media; If user is using social media
to login or signup, it is assumed verified. 

- user already registered and verified.
*/

IF cur_user_unverified_id > 0 THEN 
    DELETE FROM user_unverified 
    WHERE id = cur_user_unverified_id;

END IF;



/**
2026-03-18: Notes on login using Social Media
As of this writing, there are 3 Social Media channel supported or to be supported.

Login Via   To be supported     Development Status
==========  ===============     ===============
Google      fully supported     working correctly
Facebook    must be supported   on development
Tiktok      must be supported   not visible to users


1.) Login using these social media are always assumed they are verified.
So NO need to ask for verification codes.

2.) The Google login, always provide user email, user name, user last name and 
user first name.

3.) Other social media aside from google are assumed they may or may not
provide email.

 
- Every login now creates user_login record
- Screen dimensions captured for device analytics
- Last login ID stored in user table for quick lookup
- Location data enriched with IP trace


*/


/** Google does not provide this, only email that creates uniqueness.*/

IF in_social_media_user_id IS NOT NULL THEN 
    SELECT  id
    INTO    cur_user_using_social_media_id
    FROM    user
    WHERE   signup_social_media_id = in_login_social_media_id AND
            social_media_user_id = in_social_media_user_id
    LIMIT 1;
    

END IF;



/* It is possible now not to have any user email as long as there is a 
verified social media login.*/
    

IF cur_user_id = 0 AND cur_user_using_social_media_id = 0 THEN 
    /* User signup using social media*/

    IF in_email IS NOT NULL THEN 
        SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE + FLAG_BIT_USER_EMAIL_VERIFIED;
    ELSE
        SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE;
    END IF;


    INSERT INTO user(
        name,
        name_last,
        name_first,
        email,
        
        flag,
        login_count,
        
        signup_country_id,
        signup_social_media_id,
        social_media_user_id
        
    ) VALUES (
        in_name,
        in_name_last,
        in_name_first,
        in_email,
        
        cur_user_flag,
        1,
        
        cur_country_id,
        in_login_social_media_id,
        in_social_media_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_user_id;
    
    
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
        in_login_country_code,
        cur_login_loc_trace_id     
    );
    SELECT LAST_INSERT_ID() INTO cur_user_login_id; 
    
    UPDATE user SET 
        last_user_login_id      = cur_user_login_id
    WHERE id = cur_user_id;
    

ELSE
    /* user login using social media*/
    
    IF cur_user_id > 0 THEN 
        SET use_this_user_id = cur_user_id;
    ELSE
        SET use_this_user_id = cur_user_using_social_media_id;
    END IF;
    
    
    UPDATE user SET 
        name                    = in_name,
    
        name_last               = in_name_last,
        name_first              = in_name_first,
        
        login_count             = login_count + 1
    WHERE id = use_this_user_id;
    
    
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
        use_this_user_id,
        
        in_viewport_width,
        in_viewport_height,
        
        in_ip_address,
        in_login_country_code,
        cur_login_loc_trace_id     
    );
    SELECT LAST_INSERT_ID() INTO cur_user_login_id; 
    
    UPDATE user SET 
        last_user_login_id      = cur_user_login_id
    WHERE id = use_this_user_id;

END IF;


END process_user;




SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id        = cur_user_id;



SELECT 
    res_num                         AS result_number,
    res_code                        AS result_code,
    res_desc                        AS result_desc,
        
    cur_user_id                     AS user_id,
    cur_user_account_id             AS user_account_id,
    cur_user_flag                   AS user_flag,
    
    cur_user_unverified_id          AS user_unverified_id,
    cur_user_verify_id              AS user_verify_code_id,                  
    cur_user_verify_code            AS user_verify_code,
    cur_user_verify_code_ts_expiry  AS code_ts_expiry,
    cur_user_verify_code_dt_expiry  AS code_dt_expiry,
    NUM_MINUTES_CODE_EXPIRY         AS expiry_minutes;
    

END $$

DELIMITER ;
