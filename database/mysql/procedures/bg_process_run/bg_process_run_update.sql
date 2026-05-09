DELIMITER $$

DROP PROCEDURE IF EXISTS bg_process_run_update $$
CREATE PROCEDURE bg_process_run_update(
    in_bg_process_run_id    INT,
    
    in_duration_secs        INT,
    in_proc_status          INT,
    in_records_processed    INT

)  

BEGIN

/** 
 * Will update bg_process_run.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since April 17, 2026
 *
 */



UPDATE bg_process_run SET
    duration_secs       = in_duration_secs,
    proc_status         = in_proc_status,
    records_processed   = in_records_processed
WHERE id = in_bg_process_run_id;

SELECT in_bg_process_run_id AS  bg_process_run_id;

END $$



DELIMITER ;
