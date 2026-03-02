DELIMITER $$

DROP PROCEDURE IF EXISTS user_register_or_login $$
CREATE PROCEDURE user_register_or_login(
    in_social_media_id    INT,
    
    in_name_last            VARCHAR(50),
    in_name_first           VARCHAR(50),
    
    in_email                VARCHAR(50),
    
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



DECLARE cur_user_id                             INT             DEFAULT 0;
DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



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

IF cur_user_id = 0 THEN 

    INSERT INTO user(
        name_last,
        name_first,
        email,
        
        social_media_id
    ) VALUES (
        in_name_last,
        in_name_first,
        in_email,
        
        in_social_media_id
    );

    SELECT LAST_INSERT_ID() INTO cur_user_id;


    IF in_social_media_id > 0 THEN  
        SET cur_user_flag = FLAG_BIT_USER_IS_ACTIVE + FLAG_BIT_USER_EMAIL_VERIFIED;
        UPDATE user SET
            flag = cur_user_flag
        WHERE id = cur_user_id;
    
    
        /** Will also create a user_login entry and user should be automatically logged in*/
        INSERT INTO user_login(
            user_id,
            viewport_width,
            viewport_height,
            ip_address
        ) 
        VALUES (
            cur_user_id,
            
            in_viewport_width,
            in_viewport_height,
            in_ip_address     
        );
    END IF;
    
    
    /** If user is registered via manual email not via email from social media,
    user needes to verify email first. 
    */
    
ELSE
    IF in_social_media_id > 0 THEN 
        UPDATE user SET 
            name_last           = in_name_last,
            name_first          = in_name_first,
            
            social_media_id     = social_media_id 
        WHERE id = cur_user_id;
        
        
        /** Will also create a user_login entry and user should be automatically logged in*/
        INSERT INTO user_login(
            user_id,
            viewport_width,
            viewport_height,
            ip_address
        ) 
        VALUES (
            cur_user_id,
            
            in_viewport_width,
            in_viewport_height,
            in_ip_address     
        );

        
    END IF;

    


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
    cur_user_flag                       AS user_flag;
    

END $$

DELIMITER ;
