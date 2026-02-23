DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_feed_buy_add $$
CREATE PROCEDURE pig_farm_feed_buy_add(
    in_user_id              INT,
    
    in_pig_farm_id          INT,
    
    in_date_buy             VARCHAR(10),
    in_feed_supplier_id     INT,
    in_other_cost           DECIMAL(8,2)
) 
 
BEGIN
/**
 * Will add pig_farm_feed_buy entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 2, 2026
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;

DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;

/* common_supplier.flag bits*/
DECLARE FLAG_BIT_SUPPLIER_IS_DELETED            INT             DEFAULT 1;
DECLARE FLAG_BIT_SUPPLIER_IS_VERIFIED           INT             DEFAULT 2;


DECLARE MIN_COUNT_SUPPLIER_IS_VERIFIED          INT             DEFAULT 3;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_feed_buy_id                INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  account_id
INTO    cur_pig_farm_account_id
FROM    pig_farm 
WHERE   id = in_pig_farm_id;

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


process_user: BEGIN
IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;

/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_farm_feed_buy_id
FROM    pig_farm_feed_buy
WHERE   pig_farm_id         = in_pig_farm_id    AND
        date_buy            = in_date_buy       AND
        feed_supplier_id    = in_feed_supplier_id
LIMIT   1;

IF cur_pig_farm_feed_buy_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    LEAVE process_user;
END IF;



INSERT INTO pig_farm_feed_buy(
    account_id,
    pig_farm_id,
    
    date_buy,
    feed_supplier_id,
    other_cost,
    
    added_by_user_id
) VALUES (
    cur_pig_farm_account_id,
    in_pig_farm_id,
    
    in_date_buy,
    in_feed_supplier_id,
    in_other_cost,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_farm_feed_buy_id;

SET cur_count = 0;

SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id = cur_pig_farm_account_id AND 
        feed_supplier_id = in_feed_supplier_id;

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        feed_supplier_id,
        added_by_user_id
    ) VALUES (
        cur_pig_farm_account_id, 
        in_feed_supplier_id,
        in_user_id
    );
END IF;


/*Compute common_supplier.flag.FLAG_BIT_SUPPLIER_IS_VERIFIED*/
SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   (feed_supplier_id = in_feed_supplier_id OR
        semen_supplier_id = in_feed_supplier_id OR
        gilt_supplier_id  = in_feed_supplier_id) AND 
        
        account_id !=  cur_user_account_id;
        
/* Update common_supplier.flag.FLAG_BIT_SUPPLIER_IS_VERIFIED*/
IF cur_count >= MIN_COUNT_SUPPLIER_IS_VERIFIED THEN
    UPDATE common_supplier SET 
        flag = flag | FLAG_BIT_SUPPLIER_IS_VERIFIED
    WHERE id = in_feed_supplier_id;
END IF;


/* Update supplier account counter and usage*/
SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   feed_supplier_id = in_feed_supplier_id;

UPDATE  common_supplier SET 
    fs_account_counter  = cur_count,
    fs_usage_counter    = fs_usage_counter + 1
WHERE id = in_feed_supplier_id;


UPDATE pig_farm SET 
    data_ver_num_feed_buy = data_ver_num_feed_buy + 1
WHERE id = in_pig_farm_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    cur_pig_farm_feed_buy_id            AS pig_farm_feed_buy_id;

END $$

DELIMITER ;
