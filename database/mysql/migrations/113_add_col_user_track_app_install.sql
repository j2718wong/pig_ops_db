-- 113_acc_col_user_track_app_install.sql
-- Add OS and browser tracking columns to user_track_app_install
-- May 13, 2026
-- Jack Wong

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col_user_track_app_install $$
CREATE PROCEDURE add_col_user_track_app_install()
BEGIN
    DECLARE col_exists      INT DEFAULT 0;
    DECLARE index_exists    INT DEFAULT 0;
    
    -- Add os column
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_track_app_install' 
        AND COLUMN_NAME = 'os';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_track_app_install
        ADD COLUMN os VARCHAR(50) NULL 
        AFTER screen_height;
    END IF;
    
    -- Add os_version column
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_track_app_install' 
        AND COLUMN_NAME = 'os_version';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_track_app_install
        ADD COLUMN os_version VARCHAR(20) NULL 
        AFTER os;
    END IF;
    
    -- Add browser column
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_track_app_install' 
        AND COLUMN_NAME = 'browser';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_track_app_install
        ADD COLUMN browser VARCHAR(50) NULL 
        AFTER os_version;
    END IF;
    
    -- Add browser_version column
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_track_app_install' 
        AND COLUMN_NAME = 'browser_version';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_track_app_install
        ADD COLUMN browser_version VARCHAR(20) NULL 
        AFTER browser;
    END IF;
    
    -- Add device_type column
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_track_app_install' 
        AND COLUMN_NAME = 'device_type';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_track_app_install
        ADD COLUMN device_type VARCHAR(20) NULL 
        AFTER browser_version;
    END IF;
    
    -- Add is_webview column
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_track_app_install' 
        AND COLUMN_NAME = 'is_webview';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_track_app_install
        ADD COLUMN is_webview INT UNSIGNED NULL 
        AFTER device_type;
    END IF;
    
    -- Add webview_platform column
    SET col_exists = 0;
    
    SELECT COUNT(*) INTO col_exists
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_track_app_install' 
        AND COLUMN_NAME = 'webview_platform';
    
    IF col_exists = 0 THEN
        ALTER TABLE user_track_app_install
        ADD COLUMN webview_platform VARCHAR(30) NULL 
        AFTER is_webview;
    END IF;
    
    -- Create index on os column
    SET index_exists = 0;
    
    SELECT COUNT(*) INTO index_exists
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_track_app_install' 
        AND INDEX_NAME = 'INDEX_USER_TRACK_OS';
    
    IF index_exists = 0 THEN
        CREATE INDEX INDEX_USER_TRACK_OS 
        ON user_track_app_install (os);
    END IF;
    
    -- Create index on browser column
    SET index_exists = 0;
    
    SELECT COUNT(*) INTO index_exists
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_track_app_install' 
        AND INDEX_NAME = 'INDEX_USER_TRACK_BROWSER';
    
    IF index_exists = 0 THEN
        CREATE INDEX INDEX_USER_TRACK_BROWSER 
        ON user_track_app_install (browser);
    END IF;
    
    -- Create composite index for analytics queries
    SET index_exists = 0;
    
    SELECT COUNT(*) INTO index_exists
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'user_track_app_install' 
        AND INDEX_NAME = 'INDEX_USER_TRACK_OS_EVENT';
    
    IF index_exists = 0 THEN
        CREATE INDEX INDEX_USER_TRACK_OS_EVENT 
        ON user_track_app_install (os, event);
    END IF;
    
END$$

DELIMITER ;

CALL add_col_user_track_app_install();
DROP PROCEDURE add_col_user_track_app_install;
