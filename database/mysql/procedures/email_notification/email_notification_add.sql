DELIMITER $$

DROP PROCEDURE IF EXISTS email_notification_add $$
CREATE PROCEDURE email_notification_add(
    in_account_id           INT,
    in_user_id              INT,
    in_bg_process_run_id    INT,
    
    in_notify_type_id       INT,

    in_date_sent            VARCHAR(10)
)  

BEGIN

/** 
 * Will add email notification.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since April 20, 2026
 *
 */


DECLARE BG_PROCESS_NOTIFY_ACCOUNT_NOT_STARTED_TRIAL INT             DEFAULT 1;
DECLARE BG_PROCESS_NOTIFY_USER_INCOMPLETE_ACCOUNT   INT             DEFAULT 2;


DECLARE cur_email_notification_id                   INT             DEFAULT 0;


INSERT INTO email_notification(
    account_id,          
    user_id,             
    bg_process_run_id,   
    
    notification_type_id,
    
    date_sent
) VALUES (
    in_account_id,       
    in_user_id,          
    in_bg_process_run_id,
    
    in_notify_type_id,   
    
    in_date_sent        
);
SELECT LAST_INSERT_ID() INTO cur_email_notification_id;


IF in_notify_type_id = BG_PROCESS_NOTIFY_ACCOUNT_NOT_STARTED_TRIAL THEN 
    UPDATE account SET
        last_notify_inactive_id = cur_email_notification_id
    WHERE id = in_account_id;
END IF;


IF in_notify_type_id = BG_PROCESS_NOTIFY_USER_INCOMPLETE_ACCOUNT THEN 
    UPDATE user SET
        last_notify_inc_account = cur_email_notification_id
    WHERE id = in_user_id;
END IF;


SELECT cur_email_notification_id  AS email_notification_id;

END $$



DELIMITER ;
