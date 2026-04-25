-- 052_new_table_user_track_app_install.sql
-- April 21, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_user_track_app_install $$
CREATE PROCEDURE add_table_user_track_app_install()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE `user_track_app_install` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `user_id` int(10) unsigned DEFAULT 0,
      `event` varchar(20) DEFAULT NULL,
      `screen_width` int(10) unsigned DEFAULT NULL,
      `screen_height` int(10) unsigned DEFAULT NULL,
      `date_event` date DEFAULT NULL,
      `dt_entry` datetime DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `INDEX_USER_ID` (`user_id`),
      KEY `INDEX_DATE_EVENT` (`date_event`)
    );
    
    

    
END$$

DELIMITER ;

CALL add_table_user_track_app_install();
DROP PROCEDURE add_table_user_track_app_install;
