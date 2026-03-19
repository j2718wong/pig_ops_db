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

DECLARE cur_user_last_user_login_id             INT             DEFAULT 0;
DECLARE cur_user_last_user_login_ip_address     VARCHAR(24)     DEFAULT NULL;
DECLARE cur_user_last_user_login_country_code   VARCHAR(5)      DEFAULT NULL;

DECLARE cur_user_login_id                       INT             DEFAULT 0;



SELECT  a.last_user_login_id,
        b.ip_address,
        b.country_code_login
        
INTO    cur_user_last_user_login_id,
        cur_user_last_user_login_ip_address,
        cur_user_last_user_login_country_code

FROM    user a
LEFT OUTER JOIN user_login b ON a.last_user_login_id = b.id
WHERE   a.id = in_user_id;


IF cur_user_last_user_login_country_code IS NULL THEN 
    UPDATE user_login SET
        login_country_code      = in_login_country_code,   
        login_country_name      = in_login_country_name,   
        login_city              = in_login_city,           
        login_region            = in_login_region,         
                                
                                 
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


IF cur_user_last_user_login_ip_address != in_ip_address THEN 
    INSERT user_login(
        login_country_code, 
        login_country_name, 
        login_city,         
        login_region,       
                           
                           
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
        in_login_country_code,
        in_login_country_name,
        in_login_city,        
        in_login_region,      
        
        
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
        login_count = cur_user_login_id +1
    WHERE id = in_user_id;

END IF;

SELECT cur_user_login_id    AS  user_login_id; 


END $$

DELIMITER ;
