DELIMITER $$

DROP PROCEDURE IF EXISTS bg_process_run_update_push_notify $$
CREATE PROCEDURE bg_process_run_update_push_notify(
    in_bg_process_run_id    INT,
    
    in_push_notify_result   VARCHAR(200)
)  

BEGIN

/** 
 * Will update bg_process_run.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 9, 2026
 *
 */



UPDATE bg_process_run SET
    push_notify_result  = in_push_notify_result,
    dt_send_push_notify = CURRENT_TIMESTAMP
WHERE id = in_bg_process_run_id;

SELECT in_bg_process_run_id AS  bg_process_run_id;

END $$



DELIMITER ;
