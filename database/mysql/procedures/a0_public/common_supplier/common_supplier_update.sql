DELIMITER $$

DROP PROCEDURE IF EXISTS common_supplier_update $$
CREATE PROCEDURE common_supplier_update(
    in_user_id              INT,
    
    in_common_supplier_id   INT, 
    
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
 * Will update common_supplier entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;

DECLARE RES_NUM_NOT_ALLOWED_TO_UPDATE           INT             DEFAULT 21;



/* common_supplier.flag bits*/
DECLARE FLAG_BIT_COMMON_SUPPLIER_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_COMMON_SUPPLIER_IS_VERIFIED    INT             DEFAULT 2;


/* user.flag bits*/
DECLARE FLAG_BIT_SYSTEM_SUPER_USER              INT             DEFAULT 131072;

DECLARE USER_AUDIT_ACTION_ADD                   VARCHAR(3)      DEFAULT 'ADD';
DECLARE USER_AUDIT_ACTION_UPDATE                VARCHAR(3)      DEFAULT 'UPD';
DECLARE USER_AUDIT_ACTION_DELETE                VARCHAR(3)      DEFAULT 'DEL';


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


DECLARE cur_added_by_user_id                    INT             DEFAULT 0;
DECLARE cur_user_orig_account_id                INT             DEFAULT 0;


DECLARE in_name_upper                           VARCHAR(50)     DEFAULT '';


DECLARE cur_common_supplier_id                  INT             DEFAULT 0;
DECLARE cur_common_supplier_country_id          INT             DEFAULT 0;
DECLARE cur_common_supplier_address_level_1_id  INT             DEFAULT 0;
DECLARE cur_common_supplier_address_level_2_id  INT             DEFAULT 0;
DECLARE cur_common_supplier_address_level_3_id  INT             DEFAULT 0;
DECLARE cur_common_supplier_is_feed_supplier    INT             DEFAULT 0;
DECLARE cur_common_supplier_is_gilt_supplier    INT             DEFAULT 0;
DECLARE cur_common_supplier_is_semen_supplier   INT             DEFAULT 0;
DECLARE cur_common_supplier_latitude            DECIMAL(10,5)   DEFAULT NULL;
DECLARE cur_common_supplier_longitude           DECIMAL(10,5)   DEFAULT NULL;



DECLARE cur_common_supplier_flag                INT             DEFAULT 0;
DECLARE cur_common_supplier_name                VARCHAR(50)     DEFAULT '';
DECLARE cur_common_supplier_contact_number      VARCHAR(20)     DEFAULT NULL;
DECLARE cur_common_supplier_whatsapp            VARCHAR(20)     DEFAULT NULL;
DECLARE cur_common_supplier_messenger           VARCHAR(50)     DEFAULT NULL;



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


/* Read updatable data entered by user before update*/
SELECT  country_id,
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
        
        flag,
        added_by_user_id
        
INTO    cur_common_supplier_country_id,
        cur_common_supplier_address_level_1_id,
        cur_common_supplier_address_level_2_id,
        cur_common_supplier_address_level_3_id,
        
        cur_common_supplier_is_feed_supplier,
        cur_common_supplier_is_gilt_supplier,
        cur_common_supplier_is_semen_supplier,
    
        cur_common_supplier_latitude,
        cur_common_supplier_longitude,
    
        cur_common_supplier_name,
        cur_common_supplier_contact_number,
        cur_common_supplier_whatsapp,
        cur_common_supplier_messenger,
        
        cur_common_supplier_flag,
        cur_added_by_user_id
        
FROM    common_supplier
WHERE   id = in_common_supplier_id;

SELECT  account_id
INTO    cur_user_orig_account_id
FROM    user
WHERE   id = cur_added_by_user_id;


/* Get user flag*/
SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id = in_user_id;


SET in_name_upper = UPPER(in_name);


/* Check for duplicate entry */
IF in_address_level_3_id IS NULL THEN 
    SELECT  id
    INTO    cur_common_supplier_id
    FROM    common_supplier
    WHERE   country_id          = cur_common_supplier_country_id AND 
            address_level_1_id  = cur_common_supplier_address_level_1_id    AND
            address_level_2_id  = cur_common_supplier_address_level_2_id    AND
            id                  != in_common_supplier_id AND 
            UPPER(name)         = in_name_upper
    LIMIT   1;
ELSE
    SELECT  id
    INTO    cur_common_supplier_id
    FROM    common_supplier
    WHERE   country_id          = cur_common_supplier_country_id AND 
            address_level_1_id  = cur_common_supplier_address_level_1_id    AND
            address_level_2_id  = cur_common_supplier_address_level_2_id    AND
            address_level_3_id  = cur_common_supplier_address_level_3_id    AND
            id                  != in_common_supplier_id AND 
            UPPER(name)         = in_name_upper
    LIMIT   1;
END IF;

IF cur_common_supplier_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;





/* Only users of the account who added this entry can update.
Or a SYSTEM_SUPER_USER.
*/
IF cur_user_orig_account_id != cur_user_account_id THEN 
    IF cur_user_flag & FLAG_BIT_SYSTEM_SUPER_USER = 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        
        LEAVE process_user;
    END IF;
    
    /* Will allow update only if user.flag.FLAG_BIT_SYSTEM_SUPER_USER is SET*/

ELSE
    IF (cur_common_supplier_flag & FLAG_BIT_COMMON_SUPPLIER_IS_VERIFIED) > 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        SET res_code    = "Supplier is already verified";
        
        LEAVE process_user;
    END IF;
    
    /* Will allow update only if common_supplier.flag.FLAG_BIT_COMMON_SUPPLIER_IS_VERIFIED 
    is CLEAR*/


END IF;



UPDATE common_supplier SET
    address_level_3_id  = in_address_level_3_id,
    
    is_feed_supplier    = in_is_feed_supplier,
    is_gilt_supplier    = in_is_gilt_supplier,
    is_semen_supplier   = in_is_semen_supplier,
    
    latitude            = in_latitude,
    longitude           = in_longitude,

    name                = in_name_upper,
    contact_number      = in_contact_number,
    whatsapp            = in_whatsapp,
    messenger           = in_messenger,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_common_supplier_id;


/* Add audit trail*/
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
    in_common_supplier_id,
    in_user_id,
    USER_AUDIT_ACTION_UPDATE,

    cur_common_supplier_country_id,
    cur_common_supplier_address_level_1_id,
    cur_common_supplier_address_level_2_id,
    cur_common_supplier_address_level_3_id,
    
    cur_common_supplier_is_feed_supplier,
    cur_common_supplier_is_gilt_supplier,
    cur_common_supplier_is_semen_supplier,

    cur_common_supplier_latitude,
    cur_common_supplier_longitude,

    cur_common_supplier_name,
    cur_common_supplier_contact_number,
    cur_common_supplier_whatsapp,
    cur_common_supplier_messenger
        
);



END process_user;


SELECT
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    latitude,
    longitude,
    
    is_feed_supplier,
    is_gilt_supplier,
    is_semen_supplier,
    
    flag,
    name,
    contact_number,
    whatsapp,
    messenger
    
INTO 
    cur_common_supplier_country_id,
    cur_common_supplier_address_level_1_id,
    cur_common_supplier_address_level_2_id,
    cur_common_supplier_address_level_3_id,
    
    cur_common_supplier_latitude,
    cur_common_supplier_longitude,
    
    cur_common_supplier_is_feed_supplier,
    cur_common_supplier_is_gilt_supplier,
    cur_common_supplier_is_semen_supplier,
    
    cur_common_supplier_flag,
    cur_common_supplier_name,
    cur_common_supplier_contact_number,
    cur_common_supplier_whatsapp,
    cur_common_supplier_messenger
    
FROM common_supplier
WHERE id = in_common_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    
    in_common_supplier_id                AS common_supplier_id,
    cur_common_supplier_flag             AS flag,
    cur_common_supplier_name             AS name,
    cur_common_supplier_contact_number   AS contact_number,
    cur_common_supplier_whatsapp         AS whatsapp,
    cur_common_supplier_messenger        AS messenger,
    
    cur_common_supplier_is_feed_supplier AS is_feed_supplier,
    cur_common_supplier_is_gilt_supplier AS is_gilt_supplier,
    cur_common_supplier_is_semen_supplier AS is_semen_supplier,
    
    cur_common_supplier_country_id           AS country_id,
    cur_common_supplier_address_level_1_id   AS level_1_id,
    cur_common_supplier_address_level_2_id   AS level_2_id,
    cur_common_supplier_address_level_3_id   AS level_3_id,
    
    cur_common_supplier_latitude        AS latitude,
    cur_common_supplier_longitude       AS longitude;
    
    

END $$

DELIMITER ;
