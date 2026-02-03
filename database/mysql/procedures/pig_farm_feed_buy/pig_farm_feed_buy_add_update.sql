DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_feed_buy_update $$
CREATE PROCEDURE pig_farm_feed_buy_update(
    in_user_id              INT,
    
    in_pig_farm_feed_buy_id INT,
    
    in_date_buy             VARCHAR(10),
    in_feed_supplier_id     INT
)  

BEGIN

/** 
 * Will add pig_farm_feed_buy entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 2, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;




DECLARE cur_pig_farm_feed_buy_id                INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.pig_farm_id,
        a.account_id 

INTO    cur_pig_farm_id,
        cur_pig_farm_account_id
        
FROM pig_farm_feed_buy a 
WHERE a.id = in_pig_farm_feed_buy_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
    FLAG_BIT_OPERATION_ADD,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



UPDATE pig_farm_feed_buy SET 
    date_buy            = in_date_buy,
    feed_supplier_id    = in_feed_supplier_id,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_pig_farm_feed_buy_id;



END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_farm_feed_buy_id             AS pig_farm_feed_buy_id;

END $$

DELIMITER ;