-- 005_add_column_user_login.sql
-- Add columns to user_login table
-- March 27, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_column_coordinates_user_login $$
CREATE PROCEDURE add_column_coordinates_user_login()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_login' 
        AND COLUMN_NAME = 'longitude';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_login 
        ADD COLUMN longitude DECIMAL(10,5)   
        AFTER login_loc_trace_id;
    END IF;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_login' 
        AND COLUMN_NAME = 'latitude';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_login 
        ADD COLUMN latitude DECIMAL(10,5)   
        AFTER login_loc_trace_id;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_column_coordinates_user_login();
DROP PROCEDURE add_column_coordinates_user_login;
