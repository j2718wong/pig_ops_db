DELIMITER $$

DROP PROCEDURE IF EXISTS feed_supplier_add $$
CREATE PROCEDURE feed_supplier_add(
    in_user_id              INT,

    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will add feed_supplier entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD                      INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_SUPPLIER           INT             DEFAULT 14;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* feed_supplier.flag bits*/
DECLARE FLAG_BIT_FEED_SUPPLIER_IS_DELETED       INT             DEFAULT 1;
DECLARE FLAG_BIT_FEED_SUPPLIER_IS_VERIFIED      INT             DEFAULT 2;


DECLARE MAX_UNVERIFIED_ENTRIES_PER_USER         INT             DEFAULT 3;
DECLARE MAX_DELETED_INVALID_ENTRIES_PER_USER    INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_feed_supplier_id                    INT             DEFAULT 0;
DECLARE cur_feed_supplier_flag                  INT             DEFAULT 0;
DECLARE cur_feed_supplier_name                  VARCHAR(50)     DEFAULT '';

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
    
    BUSINESS_OBJ_ID_FEED_SUPPLIER,
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


/* Check for duplicate entry */
IF in_address_level_3_id IS NULL THEN
    SELECT  id
    INTO    cur_feed_supplier_id
    FROM    feed_supplier
    WHERE   country_id              = in_country_id   AND
            address_level_1_id      = in_address_level_1_id     AND
            address_level_2_id      = in_address_level_2_id     AND
            UPPER(name)             = UPPER(in_name)
    LIMIT   1;
ELSE
    SELECT  id
    INTO    cur_feed_supplier_id
    FROM    feed_supplier
    WHERE   country_id              = in_country_id   AND
            address_level_1_id      = in_address_level_1_id     AND
            address_level_2_id      = in_address_level_2_id     AND
            address_level_3_id      = in_address_level_3_id     AND
            UPPER(name)             = UPPER(in_name)
    LIMIT   1;
END IF;

IF cur_feed_supplier_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* feed_supplier can be added by any user. To prevent abuse of entering
invalid feed_supplier, unverified entries will be counted and 
deleted entries against the user wil be counted.*/

SELECT  COUNT(*)
INTO    cur_count
FROM    feed_supplier
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_FEED_SUPPLIER_IS_VERIFIED) = 0;

IF cur_count >= MAX_UNVERIFIED_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many unverified entries entered by user.";
    
    LEAVE process_user;

END IF;


SELECT  COUNT(*) 
INTO    cur_count
FROM    feed_supplier
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_FEED_SUPPLIER_IS_DELETED) > 0;
        
IF cur_count >= MAX_DELETED_INVALID_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many invalid entries entered by user.";
    
    LEAVE process_user;

END IF;



INSERT INTO feed_supplier(
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    name,
    added_by_user_id
    
) VALUES (
   in_country_id,
   in_address_level_1_id,
   in_address_level_2_id,
   in_address_level_3_id,
   
   in_name,
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_supplier_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_feed_supplier_flag,
    cur_feed_supplier_name
FROM feed_supplier
WHERE id = cur_feed_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_supplier_id                AS feed_supplier_id,
    cur_feed_supplier_flag              AS feed_supplier_flag,
    cur_feed_supplier_name              AS feed_supplier_name;

END $$

DELIMITER ;
