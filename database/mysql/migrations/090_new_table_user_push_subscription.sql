-- 090_new_table_user_push_susbcription.sql
-- May 7, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_user_push_susbcription $$
CREATE PROCEDURE add_table_user_push_susbcription()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE user_push_subscription (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id INT UNSIGNED NOT NULL,
        
        flag INT UNSIGNED DEFAULT 0,
        
        -- Store the unique subscription data from the browser
        subscription_endpoint VARCHAR(500) NOT NULL UNIQUE, -- Unique constraint stays here
        subscription_keys_p256dh VARCHAR(200) NOT NULL,
        subscription_keys_auth VARCHAR(100) NOT NULL,
    
        -- Device identification (Important for user management)
        device_name VARCHAR(100) DEFAULT NULL, -- Allow NULL for older entries
        browser_name VARCHAR(50) DEFAULT NULL,
        os_name VARCHAR(50) DEFAULT NULL,
        
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        
        INDEX INDEX_USER_ID (user_id)
    );

    
END$$

DELIMITER ;

CALL add_table_user_push_susbcription();
DROP PROCEDURE add_table_user_push_susbcription;
