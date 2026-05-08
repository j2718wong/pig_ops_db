-- 096_add_col_user_push_subscription_push_subscription.sql
-- Add user.num_push_subscription 
-- May 8, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_user_push_subscription $$
CREATE PROCEDURE add_col_user_push_subscription()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_push_subscription' 
        AND COLUMN_NAME = 'account_id';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_push_subscription
        ADD COLUMN account_id INT UNSIGNED    
        AFTER id;
    END IF;
    
    
    SET index_exists = 0;
    
    SELECT COUNT(*) INTO index_exists
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_push_subscription' 
        AND INDEX_NAME = 'INDEX_ACCOUNT_ID';

    IF index_exists = 0 THEN
        CREATE INDEX INDEX_ACCOUNT_ID 
        ON user_push_subscription (account_id);
    END IF;
    
    
    
END$$

DELIMITER ;

CALL add_col_user_push_subscription();
DROP PROCEDURE add_col_user_push_subscription;
