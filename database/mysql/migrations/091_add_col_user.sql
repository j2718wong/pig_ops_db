-- 091_add_col_user.sql
-- Add user.num_push_subscription 
-- May 7, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_user $$
CREATE PROCEDURE add_col_user()
BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user' 
        AND COLUMN_NAME = 'num_push_subscription';
    
    IF col_exists = 0 THEN
        ALTER TABLE user
        ADD COLUMN num_push_subscription INT UNSIGNED DEFAULT 0    
        AFTER flag;
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_user();
DROP PROCEDURE add_col_user;
