-- 003_new_table_pig_farm_report.sql
-- New table pig_farm_report
-- March 28, 2026
-- Jack Wong (j2718wong@gmail.com) ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_pig_farm_report $$
CREATE PROCEDURE add_table_pig_farm_report()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS pig_farm_report  (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        account_id INT UNSIGNED,
        pig_farm_id INT UNSIGNED,
        report_type_id INT UNSIGNED,
        flag INT UNSIGNED DEFAULT 0,
        report_date DATE,
        
        file_path VARCHAR(255),
        notes VARCHAR(160),
        
        added_by_user_id INT UNSIGNED,
        last_update_user_id INT UNSIGNED,
        dt_last_update DATETIME,
        dt_entry DATETIME DEFAULT CURRENT_TIMESTAMP,
        INDEX INDEX_ACCOUNT_ID (account_id),
        INDEX INDEX_PIG_FARM_ID (pig_farm_id)
    );

    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'pig_farm' 
        AND COLUMN_NAME = 'last_summary_report_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE pig_farm 
        ADD COLUMN last_summary_report_id INT UNSIGNED DEFAULT 0  
        AFTER dt_entry;
    END IF;
    
    
END$$

DELIMITER ;

CALL add_table_pig_farm_report();
DROP PROCEDURE add_table_pig_farm_report;
