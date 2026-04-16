-- 043_new_table_bg_process_run.sql
-- April 17, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_bg_process_run $$
CREATE PROCEDURE add_table_bg_process_run()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `bg_process_run` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `bg_process_id` int(10) unsigned DEFAULT NULL,
    `duration_secs` int(10) unsigned DEFAULT NULL,
    `proc_status` int(10) unsigned DEFAULT NULL,
    `records_processed` int(10) unsigned DEFAULT NULL,
    `business_date` DATE DEFAULT NULL,
    `dt_entry` datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `index_bg_process_id` (`bg_process_id`),
    KEY `index_business_date` (`business_date`)
    );
    
    

    
END$$

DELIMITER ;

CALL add_table_bg_process_run();
DROP PROCEDURE add_table_bg_process_run;
