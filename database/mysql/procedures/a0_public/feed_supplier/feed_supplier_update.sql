DELIMITER $$

DROP PROCEDURE IF EXISTS feed_supplier_update $$
CREATE PROCEDURE feed_supplier_update(
    in_user_id              INT,
    
    in_feed_supplier_id     INT,

    in_address_level_3_id   INT,
    
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5),
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will update feed_supplier entry to the system.
 *
 * The feed_supplier object is a shared business object for all users,
 * even for users of different accounts.
 * 
 * Only these users are allowed to update:
 *
 * 1.) users of the account of the  original user who added the entry,
 *      including the original user.
 *
 * 2.) system users
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_NOT_ALLOWED_TO_UPDATE           INT             DEFAULT 21;


/* user.flag bits*/
DECLARE FLAG_BIT_SYSTEM_SUPER_USER              INT             DEFAULT 131072;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


DECLARE cur_added_by_user_id                    INT             DEFAULT 0;
DECLARE cur_user_orig_account_id                INT             DEFAULT 0;


DECLARE cur_feed_supplier_id                    INT             DEFAULT 0;
DECLARE cur_feed_supplier_country_id            INT             DEFAULT 0;
DECLARE cur_feed_supplier_address_level_1_id    INT             DEFAULT 0;
DECLARE cur_feed_supplier_address_level_2_id    INT             DEFAULT 0;
DECLARE cur_feed_supplier_address_level_3_id    INT             DEFAULT 0;
DECLARE cur_feed_supplier_address_latitude      DECIMAL(10,5)   DEFAULT NULL;
DECLARE cur_feed_supplier_address_longitude     DECIMAL(10,5)   DEFAULT NULL;



DECLARE cur_feed_supplier_flag                  INT             DEFAULT 0;
DECLARE cur_feed_supplier_name                  VARCHAR(50)     DEFAULT '';
DECLARE cur_feed_supplier_contact_number        VARCHAR(20)     DEFAULT NULL;
DECLARE cur_feed_supplier_whatsapp              VARCHAR(20)     DEFAULT NULL;
DECLARE cur_feed_supplier_messenger             VARCHAR(50)     DEFAULT NULL;



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


/* The feed_supplier object is shared accross accounts. 
If there are MIN_COUNT_ACCOUNT_FEED_SUPPLIER_IS_VERIFIED or more, 
the feed_supplier is verified and cannot be upated anymore.
*/


/* Get the account_id of the user who originally entered this entry. */
SELECT  flag,
        added_by_user_id

INTO    cur_feed_supplier_flag,
        cur_added_by_user_id

FROM    feed_supplier
WHERE   id = in_feed_supplier_id;

SELECT  account_id
INTO    cur_user_orig_account_id
FROM    user
WHERE   id = cur_added_by_user_id;


/* Get user flag*/
SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id = in_user_id;


/* Only users of the account who added this entry can update.
Or a SYSTEM_SUPER_USER.
*/
IF cur_user_orig_account_id != cur_user_account_id THEN 
    IF (cur_user_flag & FLAG_BIT_SYSTEM_SUPER_USER) = 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        
        LEAVE process_user;
    END IF;
    
    /* Will allow update only if user.flag.FLAG_BIT_SYSTEM_SUPER_USER is SET*/
    
ELSE
    IF (cur_feed_supplier_flag & FLAG_BIT_FEED_SUPPLIER_IS_VERIFIED) > 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        SET res_code    = "Feed supplier is already verified";
        
        LEAVE process_user;
    END IF;
    
    /* Will allow update only if feed_supplier.flag.FLAG_BIT_FEED_SUPPLIER_IS_VERIFIED 
    is CLEAR*/
END IF;


UPDATE feed_supplier  SET 
    address_level_3_id  = in_address_level_3_id,
    
    latitude            = in_latitude,
    longitude           = in_longitude,
    
    name                = UPPER(in_name),
    contact_number      = in_contact_number,
    whatsapp            = in_whatsapp,
    messenger           = in_messenger,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_feed_supplier_id;


END process_user;


SELECT
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    latitude,
    longitude,
    
    flag,
    name,
    contact_number,
    whatsapp,
    messenger
    
INTO 
    cur_feed_supplier_country_id,
    
    cur_feed_supplier_address_level_1_id,
    cur_feed_supplier_address_level_2_id,
    cur_feed_supplier_address_level_3_id,
    
    cur_feed_supplier_address_latitude,
    cur_feed_supplier_address_longitude,
    
    cur_feed_supplier_flag,
    cur_feed_supplier_name,
    cur_feed_supplier_contact_number,
    cur_feed_supplier_whatsapp,
    cur_feed_supplier_messenger
    
FROM feed_supplier
WHERE id = in_feed_supplier_id;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_feed_supplier_id                 AS feed_supplier_id,
    cur_feed_supplier_flag              AS flag,
    cur_feed_supplier_name              AS name,
    cur_feed_supplier_contact_number    AS contact_number,
    cur_feed_supplier_whatsapp          AS whatsapp,
    cur_feed_supplier_messenger         AS messenger,
    
    
    cur_feed_supplier_country_id           AS country_id,
    cur_feed_supplier_address_level_1_id   AS level_1_id,
    cur_feed_supplier_address_level_2_id   AS level_2_id,
    cur_feed_supplier_address_level_3_id   AS level_3_id,
    
    cur_feed_supplier_address_latitude     AS latitude,
    cur_feed_supplier_address_longitude    AS longitude;
    

END $$

DELIMITER ;
