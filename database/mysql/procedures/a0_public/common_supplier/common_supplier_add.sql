DELIMITER $$

DROP PROCEDURE IF EXISTS common_supplier_add $$
CREATE PROCEDURE common_supplier_add(
    in_user_id              INT,

    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_is_feed_supplier     INT,
    in_is_gilt_supplier     INT,
    in_is_semen_supplier    INT,
    
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5),
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will add common_supplier entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 21, 2025
 *
 */

/** 2026-05-18 Notes:

1.) Up until to this date, the common_supplier is shared between accounts. 
The account_selection table points which suppliers relate to account.

2.) The common supplier works if the country has address_levels, because 
when filtering suppliers, they can be filtered by address levels.

    The original address design has address levels business objects:
    - country_id
    - address_level_1_id; bigger geographic division
    - address_level_2_id
    - address_level_3_id; smallest geographic division

3.) The problem is countries that dont have address_levels set up yet, 
cannot filter suppliers. It takes an effort to set up the countries address levels.
Only the country Philippines has address_levels setup.

4.) From this day forward, the address_level will be optional for any objects
that require address; only the country_id is needed. 

5.) A new column is introduced

    common_supplier.account_id
    
This directly relates the account to the suppliers.

6.) If the country has no address_levels, the common_supplier.account_id
should not be zero.

7.) There should be also duplicate checks for suppliers with address levels
and suppliers directly related to account.

*/

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD                      INT             DEFAULT 21;


/* app_country.flag bits*/
DECLARE FLAG_BIT_COUNTRY_ENABLE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_COUNTRY_HAS_ADDRESS_LEVELS     INT             DEFAULT 2;


/* common_supplier.flag bits*/
DECLARE FLAG_BIT_COMMON_SUPPLIER_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_COMMON_SUPPLIER_IS_VERIFIED    INT             DEFAULT 2;


DECLARE MAX_UNVERIFIED_ENTRIES_PER_USER         INT             DEFAULT 3;
DECLARE MAX_DELETED_INVALID_ENTRIES_PER_USER    INT             DEFAULT 3;


DECLARE USER_AUDIT_ACTION_ADD                   VARCHAR(3)      DEFAULT 'ADD';
DECLARE USER_AUDIT_ACTION_UPDATE                VARCHAR(3)      DEFAULT 'UPD';
DECLARE USER_AUDIT_ACTION_DELETE                VARCHAR(3)      DEFAULT 'DEL';




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_country_flag                        INT             DEFAULT 0;

DECLARE cur_common_supplier_id                  INT             DEFAULT 0;
DECLARE cur_common_supplier_flag                INT             DEFAULT 0;
DECLARE cur_common_supplier_name                VARCHAR(50)     DEFAULT '';

DECLARE in_name_upper                           VARCHAR(50)     DEFAULT '';

DECLARE is_shared_supplier                      INT             DEFAULT 0;

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


SELECT  flag
INTO    cur_country_flag
FROM    app_country
WHERE   id = in_country_id;




/* Check for duplicate entry */

IF cur_country_flag & FLAG_BIT_COUNTRY_HAS_ADDRESS_LEVELS > 0 THEN 

    IF in_address_level_3_id IS NULL THEN  
        SELECT  id
        INTO    cur_common_supplier_id
        FROM    common_supplier
        WHERE   country_id          = in_country_id             AND
                address_level_1_id  = in_address_level_1_id     AND
                address_level_2_id  = in_address_level_2_id     AND
                flag & FLAG_BIT_COMMON_SUPPLIER_IS_DELETED = 0  AND 
                UPPER(name)         = in_name_upper
        LIMIT   1;
    ELSE
        SELECT  id
        INTO    cur_common_supplier_id
        FROM    common_supplier
        WHERE   country_id          = in_country_id             AND
                address_level_1_id  = in_address_level_1_id     AND
                address_level_2_id  = in_address_level_2_id     AND
                address_level_3_id  = in_address_level_3_id     AND
                flag & FLAG_BIT_COMMON_SUPPLIER_IS_DELETED = 0  AND 
                UPPER(name)         = in_name_upper
        LIMIT   1;
    END IF;
    
    
    SET is_shared_supplier = 1;

ELSE
    SELECT      id
    INTO        cur_common_supplier_id
    FROM        common_supplier
    WHERE       account_id          = cur_user_account_id AND 
                UPPER(name)         = in_name_upper
    LIMIT       1;

    SET is_shared_supplier = 0;

END IF;

IF cur_common_supplier_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* common_supplier can be added by any user. To prevent abuse of entering
invalid common_supplier, unverified entries will be counted and 
deleted entries against the user will be counted.*/

IF is_shared_supplier > 0 THEN 
    SELECT  COUNT(*)
    INTO    cur_count
    FROM    common_supplier
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
    FROM    common_supplier
    WHERE   added_by_user_id = in_user_id AND 
            (flag & FLAG_BIT_COMMON_SUPPLIER_IS_DELETED) > 0 AND 
            deleted_by_user_id IS NOT NULL AND 
            deleted_by_user_id != in_user_id; 
            
    IF cur_count >= MAX_DELETED_INVALID_ENTRIES_PER_USER THEN 
        SET res_num     = RES_NUM_CANNOT_ADD;
        SET res_code    = "RES_NUM_CANNOT_ADD";
        SET res_desc    = "Too many invalid entries entered by user.";
        
        LEAVE process_user;

    END IF;

END IF;


IF is_shared_supplier > 0 THEN 
    INSERT INTO common_supplier(
        country_id,
        address_level_1_id,
        address_level_2_id,
        address_level_3_id,
        
        is_feed_supplier,
        is_gilt_supplier,
        is_semen_supplier,
        
        latitude,
        longitude,
        
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
        
        in_is_feed_supplier,
        in_is_gilt_supplier,
        in_is_semen_supplier,
        
        in_latitude,
        in_longitude,
        
        in_name_upper,
        in_contact_number,
        in_whatsapp,
        in_messenger,
        
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_common_supplier_id;
ELSE
    INSERT INTO common_supplier(
        account_id,
        country_id,
        
        is_feed_supplier,
        is_gilt_supplier,
        is_semen_supplier,
        
        latitude,
        longitude,
        
        name,
        contact_number,
        whatsapp,
        messenger,
        
        added_by_user_id
        
    ) VALUES (
        cur_user_account_id,
        in_country_id,
       
        in_is_feed_supplier,
        in_is_gilt_supplier,
        in_is_semen_supplier,
        
        in_latitude,
        in_longitude,
        
        in_name_upper,
        in_contact_number,
        in_whatsapp,
        in_messenger,
        
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_common_supplier_id;

END IF;


/* Insert into account_selection.*/

SET cur_count = 0;
IF in_is_feed_supplier > 0 THEN
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id =  cur_user_account_id AND 
            feed_supplier_id = cur_common_supplier_id;
            

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            feed_supplier_id
        ) VALUES (
            cur_user_account_id,
            cur_common_supplier_id
        );
    END IF;
END IF;


SET cur_count = 0;
IF in_is_gilt_supplier > 0 THEN
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id =  cur_user_account_id AND 
            gilt_supplier_id = cur_common_supplier_id;
            

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            gilt_supplier_id
        ) VALUES (
            cur_user_account_id,
            cur_common_supplier_id
        );
    END IF;
END IF;


SET cur_count = 0;
IF in_is_semen_supplier > 0 THEN
    SELECT  COUNT(*) 
    INTO    cur_count
    FROM    account_selection
    WHERE   account_id =  cur_user_account_id AND 
            semen_supplier_id = cur_common_supplier_id;
            

    IF cur_count = 0 THEN 
        INSERT INTO account_selection(
            account_id,
            semen_supplier_id
        ) VALUES (
            cur_user_account_id,
            cur_common_supplier_id
        );
    END IF;
END IF;




IF is_shared_supplier > 0 THEN 
    /* Add user audit trail, since this is a public record to easily identify
    who changes what. */
    INSERT INTO common_supplier_audit(
        common_supplier_id,
        audit_user_id,
        audit_action,

        country_id,
        address_level_1_id,
        address_level_2_id,
        address_level_3_id,
        
        is_feed_supplier,
        is_gilt_supplier,
        is_semen_supplier,
        
        latitude,
        longitude,
        
        name,
        contact_number,
        whatsapp,
        messenger
        
    ) VALUES (
        cur_common_supplier_id,
        in_user_id,
        USER_AUDIT_ACTION_ADD,

        in_country_id,
        in_address_level_1_id,
        in_address_level_2_id,
        in_address_level_3_id,
        
        in_is_feed_supplier,
        in_is_gilt_supplier,
        in_is_semen_supplier,

        in_latitude,
        in_longitude,

        in_name_upper,
        in_contact_number,
        in_whatsapp,
        in_messenger
    );
END IF;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_common_supplier_flag,
    cur_common_supplier_name
FROM common_supplier
WHERE id = cur_common_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_common_supplier_id              AS common_supplier_id,
    cur_common_supplier_flag            AS common_supplier_flag,
    cur_common_supplier_name            AS common_supplier_name;

END $$

DELIMITER ;
