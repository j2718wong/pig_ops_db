DELIMITER $$

DROP PROCEDURE IF EXISTS email_notification_add $$
CREATE PROCEDURE email_notification_add(
    in_account_id           INT,
    in_user_id              INT,
    
    in_notify_type_id       INT,

    in_business_date        VARCHAR(10)
)  

BEGIN

/** 
 * Will add bg_process_run.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since April 17, 2026
 *
 */


DECLARE cur_email_notification_id                   INT             DEFAULT 0;



INSERT INTO bg_process_run(
    bg_process_id,
    business_date
) VALUES (
    in_bg_process_id,
    in_business_date
);
SELECT LAST_INSERT_ID() INTO cur_email_notification_id;


SELECT cur_email_notification_id  AS bg_proc_run_id;

END $$



DELIMITER ;
