DELIMITER $$

DROP PROCEDURE IF EXISTS user_register $$
CREATE PROCEDURE user_register(
    in_username             VARCHAR(50),
    in_name_last            VARCHAR(50),
    in_name_first           VARCHAR(50),
    
    in_email                VARCHAR(50),
    in_mobile_num           VARCHAR(50),
    in_password             VARCHAR(200)
)  

BEGIN

/** 
 * Will create user entry. This is usually used when a user registers from
 * a mobile app or web application. All parameter input cannot be null or empty.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 8, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 1;

DECLARE cur_user_id                             INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  id
INTO    cur_user_id
FROM    user
WHERE   UPPER(username)     = UPPER(in_username)    OR
        UPPER(email)        = UPPER(in_email)       OR
        mobile_num          = in_mobile_num 
LIMIT   1;


process_user : BEGIN

IF cur_user_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;

END IF;


INSERT INTO user(
    username,
    name_last,
    name_first,
    email,
    mobile_num,
    password
) VALUES (
    in_username,
    in_name_last,
    in_name_first,
    in_email,
    in_mobile_num,
    in_password
);

SELECT LAST_INSERT_ID() INTO cur_user_id;

END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_id                         AS user_id,
    0                                   AS user_flag;
    

END $$

DELIMITER ;
