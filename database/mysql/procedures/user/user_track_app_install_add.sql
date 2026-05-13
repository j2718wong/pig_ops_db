DELIMITER $$

DROP PROCEDURE IF EXISTS user_track_app_install_add $$
CREATE PROCEDURE user_track_app_install_add(
    in_user_id              INT,
    
    in_event                VARCHAR(30),
    
    in_screen_width         INT,
    in_screen_height        INT,
    
    in_is_webview           INT,
    
    in_browser              VARCHAR(50),
    in_browser_version      VARCHAR(20),
    in_webview_platform     VARCHAR(30),
    
    in_os                   VARCHAR(50),
    in_os_version           VARCHAR(20),
    
    in_device_type          VARCHAR(20)
    
    
)  

BEGIN

/** 
 * Will add user_track_app_install event.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since April 25, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


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
DECLARE FLAG_BIT_USER_PWA_APP_INSTALLED         INT             DEFAULT 512;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_user_track_app_install_id           INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";





CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    0,
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


INSERT INTO user_track_app_install(
    user_id,
    
    event,
 
    screen_width,
    screen_height,

    is_webview,      
    
    browser,         
    browser_version, 
    webview_platform,
    
    os,              
    os_version,      
    
    device_type,
    
    date_event
) VALUES (
    in_user_id,
    
    in_event,

    in_screen_width,
    in_screen_height,
    
    in_is_webview,      
    
    in_browser,         
    in_browser_version, 
    in_webview_platform,
    
    in_os,              
    in_os_version,      
    
    in_device_type,     
    
    CURRENT_DATE
);

SELECT LAST_INSERT_ID() INTO cur_user_track_app_install_id;


IF in_event = 'PWA_INSTALLED' THEN 
    UPDATE user SET 
        flag = flag | FLAG_BIT_USER_PWA_APP_INSTALLED
    WHERE id = in_user_id;
END IF;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_track_app_install_id       AS track_app_install_id;

END $$

DELIMITER ;
