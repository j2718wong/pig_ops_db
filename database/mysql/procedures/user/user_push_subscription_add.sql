DELIMITER $$

DROP PROCEDURE IF EXISTS user_push_subscription_add $$
CREATE PROCEDURE user_push_subscription_add(
    in_user_id              INT,
    
    in_subscription_endpoint        VARCHAR(500),
    in_subscription_keys_p256dh     VARCHAR(200),
    in_subscription_keys_auth       VARCHAR(100),

    in_device_name                  VARCHAR(100), 
    in_browser_name                 VARCHAR(50),
    in_os_name                      VARCHAR(50) 
)  

BEGIN

/** 
 * Will add user_push_susbcription.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 7, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;




/* user_push_subscription.flag bits*/
DECLARE FLAG_BIT_PUSH_NOTIFICATION_ENABLED      INT             DEFAULT 1;
DECLARE FLAG_BIT_PUSH_NOTIFICATION_DEACTIVATED  INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_user_push_subscription_id           INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;

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


SELECT  id
INTO    cur_user_push_subscription_id 
FROM    user_push_subscription
WHERE   user_id = in_user_id AND subscription_endpoint = in_subscription_endpoint
LIMIT   1;

IF cur_user_push_subscription_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/*Insert into user_push_subscription*/
INSERT INTO user_push_subscription(
    user_id,
    
    flag,
    
    subscription_endpoint,   
    subscription_keys_p256dh,
    subscription_keys_auth,  
    
    device_name,             
    browser_name,            
    os_name                 
    
) VALUES (
    in_user_id,
    
    FLAG_BIT_PUSH_NOTIFICATION_ENABLED,
    
    in_subscription_endpoint,   
    in_subscription_keys_p256dh,
    in_subscription_keys_auth,  
    
    in_device_name,             
    in_browser_name,            
    in_os_name                 
);
SELECT LAST_INSERT_ID() INTO cur_user_push_subscription_id;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_push_subscription_id       AS push_susbcription_id;

END $$

DELIMITER ;
