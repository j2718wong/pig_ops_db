DELIMITER $$

DROP PROCEDURE IF EXISTS bill_notify_trace_add $$
CREATE PROCEDURE bill_notify_trace_add(
    in_account_bill_id      INT,
    in_user_id              INT, 
    in_notify_type          VARCHAR(2),
    in_notify_message       VARCHAR(30)
)  

BEGIN

/** 
 * Will add bill_notify_trace entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 16, 2026
 *
 */


DECLARE cur_bill_notify_trace_id                INT             DEFAULT 0;


INSERT INTO bill_notify_trace(
    account_bill_id,
    user_id,
    notify_type,     
    notify_message,  
    dt_notify 
) VALUES (
    in_account_bill_id,
    in_user_id,        
    in_notify_type,    
    in_notify_message, 
    CONVERT_TZ(CURRENT_TIMESTAMP, '+00:00', '+08:00')
    
);
    

SELECT LAST_INSERT_ID() INTO cur_bill_notify_trace_id;



SELECT 
    cur_bill_notify_trace_id            AS bill_notify_trace_id;

END $$

DELIMITER ;
