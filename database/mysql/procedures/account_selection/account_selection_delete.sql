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


/* semen_supplier.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_IS_DELETED      INT             DEFAULT 1;
DECLARE FLAG_BIT_SEMEN_SUPPLIER_IS_VERIFIED     INT             DEFAULT 2;


/* semen_supplier_semen.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_DELETED      INT       DEFAULT 1;
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED     INT       DEFAULT 2;



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
    
    
    SELECT  COUNT(*)
    INTO    cur_count
    FROM    account_selection
    WHERE   semen_supplier_id = in_semen_supplier_id AND 
            account_id != cur_user_account_id;


    /* Delete the semen_supplier on these condiitons:
    1.) The account who created it, is the one hwo deleted it.
    Nobody else is using it.
    
    2.) The semen_supplier is not verified.
    semen_supplier.flag.FLAG_BIT_SEMEN_SUPPLIER_IS_VERIFIED = 0
    
    
    
    */
    IF cur_count = 0 THEN
        UPDATE semen_supplier SET 
            flag = flag | FLAG_BIT_SEMEN_SUPPLIER_IS_DELETED,
            deleted_by_user_id = in_user_id,
            dt_last_update = CURRENT_TIMESTAMP
        WHERE id = in_semen_supplier_id;
        
        
        /* Delete semen_supplier_semen of the deleted semen_supplier if 
        nobody is using them

        */
        
        UPDATE semen_supplier_semen SET 
            flag = flag | FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_DELETED,
            last_update_user_id = in_user_id,
            dt_last_update = CURRENT_TIMESTAMP
        WHERE semen_supplier_id = in_semen_supplier_id AND 
            usage_counter = 0;
        
        
    END IF;
    
    
END IF;



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS account_id;

END $$

DELIMITER ;
