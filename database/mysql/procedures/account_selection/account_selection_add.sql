DELIMITER $$

DROP PROCEDURE IF EXISTS account_selection_add $$
CREATE PROCEDURE account_selection_add(
    in_user_id              INT,
    
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    in_semen_supplier_id    INT
)  

BEGIN

/** 
 * Will add account_pig_buyer entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER       INT             DEFAULT 7;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



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
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER,
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


IF in_feed_supplier_id > 0 THEN 
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id =  cur_user_account_id AND 
            feed_supplier_id = in_feed_supplier_id;
            

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            feed_supplier_id
        ) VALUES (
            cur_user_account_id,
            in_feed_supplier_id
        );
    END IF;

END IF;


IF in_semen_supplier_id > 0 THEN 
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id =  cur_user_account_id AND 
            semen_supplier_id = in_semen_supplier_id;
            

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            semen_supplier_id
        ) VALUES (
            cur_user_account_id,
            in_semen_supplier_id
        );
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
