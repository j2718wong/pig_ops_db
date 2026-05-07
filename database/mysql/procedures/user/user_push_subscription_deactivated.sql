DELIMITER $$

DROP PROCEDURE IF EXISTS user_push_subscription_deactivated $$
CREATE PROCEDURE user_push_subscription_deactivated(
    in_user_push_subscription_id        INT
)  

BEGIN

/** 
 * Will deactivate user_push_subscription.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 8, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;





/* user_push_subscription.flag bits*/
DECLARE FLAG_BIT_PUSH_NOTIFICATION_ENABLED      INT             DEFAULT 1;
DECLARE FLAG_BIT_PUSH_NOTIFICATION_DEACTIVATED  INT             DEFAULT 2;


DECLARE cur_count                               INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



process_user : BEGIN

UPDATE user_push_subscription SET 
    flag = flag | FLAG_BIT_PUSH_NOTIFICATION_DEACTIVATED
WHERE id = in_user_push_subscription_id;

END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc;

END $$

DELIMITER ;
