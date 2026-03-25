DELIMITER $$

DROP PROCEDURE IF EXISTS user_update_login $$
CREATE PROCEDURE user_update_login(
    in_user_id              INT,
    
    
    in_login_country_code   VARCHAR(3),  /* This should be in upper case*/
    in_login_country_name   VARCHAR(50),
    in_login_city           VARCHAR(50), /* This should be in upper case*/
    in_login_region         VARCHAR(50), /* This should be in upper case*/
    
    
    in_viewport_width       INT,
    in_viewport_height      INT,
    in_ip_address           VARCHAR(24),
    
    in_is_mobile            INT,
    in_is_webview           INT,
    
    in_browser              VARCHAR(50),
    in_browser_version      VARCHAR(20),
    in_webview_platform     VARCHAR(30),
    in_os                   VARCHAR(50),
    in_os_version           VARCHAR(20),
    in_device               VARCHAR(50),
    in_device_type          VARCHAR(20)
    
)  

BEGIN


DECLARE cur_country_id                          INT             DEFAULT 0;
DECLARE cur_login_loc_trace_id                  INT             DEFAULT 0;

DECLARE cur_user_last_user_login_id             INT             DEFAULT 0;
DECLARE cur_user_last_user_login_ip_address     VARCHAR(24)     DEFAULT NULL;
DECLARE cur_user_last_user_login_country_code   VARCHAR(5)      DEFAULT NULL;

DECLARE cur_user_login_id                       INT             DEFAULT 0;
    
DECLARE cur_count                               INT             DEFAULT 0;                                  


SELECT  id
INTO    cur_country_id
FROM    app_country 
WHERE   country_code = in_login_country_code;


IF cur_country_id = 0 THEN 
    INSERT INTO app_country(
        country_code,
        name
    )
    VALUES(
        in_login_country_code,
        in_login_country_name
    );
    
    SELECT LAST_INSERT_ID() INTO cur_country_id;
END IF;



/** Save IP location trace*/
IF in_login_city IS NOT NULL AND in_login_region IS NOT NULL THEN 
    SELECT  id 
    INTO    cur_login_loc_trace_id
    FROM    user_login_ip_loc_trace
    WHERE   app_country_id      = cur_country_id AND
            ip_loc_trace_city   = in_login_city AND 
            ip_loc_trace_region = in_login_region
    LIMIT   1;

ELSE
    IF in_login_city IS NOT NULL THEN
        SELECT  id 
        INTO    cur_login_loc_trace_id
        FROM    user_login_ip_loc_trace
        WHERE   app_country_id      = cur_country_id AND
                ip_loc_trace_city   = in_login_city AND 
                ip_loc_trace_region = NULL
        LIMIT   1;
    END IF;
    
    IF in_login_region IS NOT NULL THEN
        SELECT  id 
        INTO    cur_login_loc_trace_id
        FROM    user_login_ip_loc_trace
        WHERE   app_country_id      = cur_country_id AND
                ip_loc_trace_region = in_login_region AND 
                ip_loc_trace_city   = NULL
        LIMIT   1;
    END IF;
        
END IF;



IF cur_login_loc_trace_id = 0 THEN 
    INSERT INTO user_login_ip_loc_trace (
        app_country_id,
        ip_loc_trace_city,
        ip_loc_trace_region
    ) VALUES(
        cur_country_id,
        in_login_city,
        in_login_region
    );
    
    SELECT LAST_INSERT_ID() INTO cur_login_loc_trace_id;
END IF;



SELECT  a.last_user_login_id,
        b.ip_address,
        b.country_code_login
        
INTO    cur_user_last_user_login_id,
        cur_user_last_user_login_ip_address,
        cur_user_last_user_login_country_code

FROM    user a
LEFT OUTER JOIN user_login b ON a.last_user_login_id = b.id
WHERE   a.id = in_user_id;


/* Solution for already deleted entries*/
SELECT  COUNT(*)
INTO    cur_count
FROM    user_login
WHERE   id = cur_user_last_user_login_id;

IF cur_count = 1 THEN 
    /** Entry still existing*/
    IF in_ip_address IS NOT  NULL THEN 
        UPDATE user_login SET
          
            country_code_login      = in_login_country_code,
            login_loc_trace_id      = cur_login_loc_trace_id,
                                     
            viewport_width          = in_viewport_width,       
            viewport_height         = in_viewport_height,      
            ip_address              = in_ip_address,           
                                     
            is_mobile               = in_is_mobile,            
            is_webview              = in_is_webview,           
                                     
            browser                 = in_browser,              
            browser_version         = in_browser_version,      
            webview_platform        = in_webview_platform,     
            os                      = in_os,                   
            os_version              = in_os_version,           
            device                  = in_device,               
            device_type             = in_device_type,
            
            date_login              = CURRENT_DATE          
        WHERE id = cur_user_last_user_login_id;
        
        SET cur_user_login_id = cur_user_last_user_login_id;
    END IF;
END IF;



IF in_ip_address IS NOT  NULL THEN 

    IF cur_count = 0 OR cur_user_last_user_login_ip_address != in_ip_address THEN 
        

        INSERT user_login(
            user_id,
        
            country_code_login,
            login_loc_trace_id, 
                               
            viewport_width,     
            viewport_height,    
            ip_address,         
                               
            is_mobile,          
            is_webview,         
                               
            browser,            
            browser_version,    
            webview_platform,   
            os,                 
            os_version,         
            device,             
            device_type,        
            
            date_login         
        ) VALUES (
            in_user_id,
        
            in_login_country_code,
            cur_login_loc_trace_id,     
            
            
            in_viewport_width,    
            in_viewport_height,   
            in_ip_address,        
            
            in_is_mobile,         
            in_is_webview,        
            
            in_browser,           
            in_browser_version,   
            in_webview_platform,  
            in_os,                
            in_os_version,        
            in_device,            
            in_device_type,
            
            CURRENT_DATE          
        );
        
        SELECT LAST_INSERT_ID() INTO cur_user_login_id;
        
        UPDATE user SET 
            last_user_login_id =  cur_user_login_id,
            login_count = login_count +1
        WHERE id = in_user_id;

    END IF;

END IF;

SELECT cur_user_login_id    AS  user_login_id; 


END $$

DELIMITER ;
