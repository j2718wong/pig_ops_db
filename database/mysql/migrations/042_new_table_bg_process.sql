-- 042_new_table_bg_process.sql
-- April 17, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_bg_process $$
CREATE PROCEDURE add_table_bg_process()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `bg_process` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(80) DEFAULT NULL,
    `dt_entry` datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`)
    );
    
    

    
END$$

DELIMITER ;

CALL add_table_bg_process();
DROP PROCEDURE add_table_bg_process;
