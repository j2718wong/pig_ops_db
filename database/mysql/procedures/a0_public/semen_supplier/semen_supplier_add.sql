DELIMITER $$

DROP PROCEDURE IF EXISTS semen_supplier_add $$
CREATE PROCEDURE semen_supplier_add(
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
 * Will add semen_supplier entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD                      INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_SEMEN_SUPPLIER          INT             DEFAULT 13;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* semen_supplier.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_IS_DELETED      INT             DEFAULT 1;
DECLARE FLAG_BIT_SEMEN_SUPPLIER_IS_VERIFIED     INT             DEFAULT 2;


DECLARE MAX_UNVERIFIED_ENTRIES_PER_USER         INT             DEFAULT 3;
DECLARE MAX_DELETED_INVALID_ENTRIES_PER_USER    INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_semen_supplier_id                   INT             DEFAULT 0;
DECLARE cur_semen_supplier_flag                 INT             DEFAULT 0;
DECLARE cur_semen_supplier_name                 VARCHAR(50)     DEFAULT '';

DECLARE in_name_upper                           VARCHAR(50)     DEFAULT '';

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
    
    0, /* public business object*/
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


/* All public object names are in UPPER case. Except address names.*/
SET in_name_upper = UPPER(in_name);


/* Check for duplicate entry */
IF in_address_level_3_id IS NULL THEN  
    SELECT  id
    INTO    cur_semen_supplier_id
    FROM    semen_supplier
    WHERE   country_id          = in_country_id   AND
            address_level_1_id  = in_address_level_1_id   AND
            address_level_2_id  = in_address_level_2_id   AND
            UPPER(name)         = in_name_upper
    LIMIT   1;
ELSE
    SELECT  id
    INTO    cur_semen_supplier_id
    FROM    semen_supplier
    WHERE   country_id          = in_country_id   AND
            address_level_1_id  = in_address_level_1_id   AND
            address_level_2_id  = in_address_level_2_id   AND
            address_level_3_id  = in_address_level_3_id   AND
            UPPER(name)         = in_name_upper
    LIMIT   1;
END IF;

IF cur_semen_supplier_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* semen_supplier can be added by any user. To prevent abuse of entering
invalid semen_supplier, unverified entries will be counted and 
deleted entries against the user wil be counted.*/

SELECT  COUNT(*)
INTO    cur_count
FROM    semen_supplier
WHERE   added_by_user_id = in_user_id AND 
        (flag & 3) = 0;

IF cur_count >= MAX_UNVERIFIED_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many unverified entries entered by user.";
    
    LEAVE process_user;

END IF;


SELECT  COUNT(*) 
INTO    cur_count
FROM    semen_supplier
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_SEMEN_SUPPLIER_IS_DELETED) > 0 AND 
        deleted_by_user_id IS NOT NULL AND 
        deleted_by_user_id != in_user_id; 
        
IF cur_count >= MAX_DELETED_INVALID_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many invalid entries entered by user.";
    
    LEAVE process_user;

END IF;




INSERT INTO semen_supplier(
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    name,
    contact_number,
    whatsapp,
    messenger,
    added_by_user_id
    
) VALUES (
   in_country_id,
   in_address_level_1_id,
   in_address_level_2_id,
   in_address_level_3_id,
   
   in_name_upper,
   in_contact_number,
   in_whatsapp,
   in_messenger,
   
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_semen_supplier_id;


SET cur_count = 0;

SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_user_account_id AND 
        semen_supplier_id = cur_semen_supplier_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        semen_supplier_id
    ) VALUES (
        cur_user_account_id,
        cur_semen_supplier_id
    );
END IF;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_supplier_flag,
    cur_semen_supplier_name
FROM semen_supplier
WHERE id = cur_semen_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_semen_supplier_id               AS semen_supplier_id,
    cur_semen_supplier_flag             AS semen_supplier_flag,
    cur_semen_supplier_name             AS semen_supplier_name;

END $$

DELIMITER ;
