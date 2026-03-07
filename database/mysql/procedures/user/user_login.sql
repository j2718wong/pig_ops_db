DELIMITER $$

DROP PROCEDURE IF EXISTS user_login $$
CREATE PROCEDURE user_login(
    in_user_id              INT,
    
    in_viewport_width         INT,
    in_viewport_height        INT,
    
    in_ip_address           VARCHAR(24),
    in_ip_loc_trace         VARCHAR(80)
)  

BEGIN

/** 
 * Will create user login entry. 
 *
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since March 1, 2026
 *
 */


DECLARE cur_user_login_id                       INT             DEFAULT 0;



process_user : BEGIN


INSERT INTO user_login(
    user_id, 
          
    viewport_width,  
    viewport_height, 
    
    ip_address,    
    ip_loc_trace 
)
VALUES(
    in_user_id, 
          
    in_viewport_width,  
    in_viewport_height, 
    
    in_ip_address,    
    in_ip_loc_trace
);

SELECT LAST_INSERT_ID() INTO cur_user_login_id;


END process_user;



SELECT 
    
    cur_user_login_id                   AS user_login_id;
    

END $$

DELIMITER ;
