DELIMITER $$

DROP PROCEDURE IF EXISTS user_access_code_add $$
CREATE PROCEDURE user_access_code_add(
    in_user_id              INT,
    in_code                 INT,
    
    in_dt_expiry            VARCHAR(20)
)  

BEGIN

/** 
 * Will add user_access_code. This is sent to user email and the user should 
 * enter this code to access account.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since October 9, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE cur_user_id                             INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



process_user : BEGIN

/* DELETE all previous access_code related to user.*/
DELETE FROM user_access_code
WHERE user_id = in_user_id;

INSERT INTO user_access_code(
    user_id,
    code,
    dt_expiry
) VALUES (
    in_user_id,
    in_code,
    in_dt_expiry
);

END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_user_id                          AS user_id;
    

END $$

DELIMITER ;
