DELIMITER $$

DROP PROCEDURE IF EXISTS app_mfa_add $$
CREATE PROCEDURE app_mfa_add(
    in_business_obj_id          INT,
    in_b_table_row_id           INT,
    in_channel_id               INT,
    in_country_code             INT,
    in_mobile_num               VARCHAR(15),
    in_email                    VARCHAR(100),
    
    in_auth_code                INT,
    
    in_ts_expiry                BIGINT,
    in_dt_expiry                VARCHAR(20)
)

BEGIN

/** 
 * Will add multi factor auth entry
 * @author Jack Wong
 * @since January 4, 2024
 *
 */

 
DECLARE cur_mfa_id                              INT             DEFAULT 0;

INSERT INTO app_mfa(
    business_obj_id,
    b_table_row_id,
    channel_id,
    country_code,
    mobile_num,
    email,
    
    auth_code,
    
    ts_expiry,
    dt_expiry
)
VALUES(
    in_business_obj_id,
    in_b_table_row_id,
    in_channel_id,
    in_country_code,
    in_mobile_num,
    in_email,
    
    in_auth_code,
    
    in_ts_expiry,
    in_dt_expiry
);
SELECT LAST_INSERT_ID() INTO cur_mfa_id;


SELECT  
    cur_mfa_id                  AS mfa_id;

END $$

DELIMITER ;
