DELIMITER $$

DROP PROCEDURE IF EXISTS bg_process_run_add $$
CREATE PROCEDURE bg_process_run_add(
    in_bg_process_id        INT,

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


DECLARE cur_bg_process_run_id                   INT             DEFAULT 0;



INSERT INTO bg_process_run(
    bg_process_id,
    business_date
) VALUES (
    in_bg_process_id,
    in_business_date
);
SELECT LAST_INSERT_ID() INTO cur_bg_process_run_id;


SELECT cur_bg_process_run_id  AS bg_proc_run_id;

END $$



DELIMITER ;
