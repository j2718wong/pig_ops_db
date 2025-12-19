DELIMITER $$

DROP PROCEDURE IF EXISTS account_selection_delete $$
CREATE PROCEDURE account_selection_delete(
    in_user_id              INT,
    
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    in_semen_supplier_id    INT
)  

BEGIN

/** 
 * Will add account_selection entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 19, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;




/* account_selection.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED   INT             DEFAULT 1;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    0,
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF in_feed_supplier_id > 0 THEN 
    /* The already deleted entries, should not be updated
    to preserve who and when the entries were deleted.
    */
    
    UPDATE account_selection SET
        flag = flag | FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED,
        last_update_user_id = in_user_id,
        dt_last_update = CURRENT_TIMESTAMP
    
    WHERE account_id = cur_user_account_id          AND 
          feed_supplier_id = in_feed_supplier_id    AND 
          (flag & FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED) = 0;

END IF;


IF in_semen_supplier_id > 0 THEN 
    /* The already deleted entries, should not be updated
    to preserve who and when the entries were deleted.
    */
    
    UPDATE account_selection SET
        flag = flag | FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED,
        last_update_user_id = in_user_id,
        dt_last_update = CURRENT_TIMESTAMP
    
    WHERE account_id = cur_user_account_id          AND 
          semen_supplier_id = in_semen_supplier_id  AND 
          (flag & FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED) = 0;

END IF;



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS account_id;

END $$

DELIMITER ;
