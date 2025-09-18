DELIMITER $$

DROP PROCEDURE IF EXISTS semen_supplier_update $$
CREATE PROCEDURE semen_supplier_update(
    in_user_id              INT,
    
    in_semen_supplier_id    INT, 

    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will update semen_supplier entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;

DECLARE RES_NUM_NOT_ALLOWED_TO_UPDATE           INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_SEMEN_SUPPLIER          INT             DEFAULT 13;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* semen_supplier.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_IS_DELETED      INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


DECLARE cur_added_by_user_id                    INT             DEFAULT 0;
DECLARE cur_user_orig_account_id                INT             DEFAULT 0;


DECLARE cur_semen_supplier_id                   INT             DEFAULT 0;
DECLARE cur_semen_supplier_flag                 INT             DEFAULT 0;
DECLARE cur_semen_supplier_name                 VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_SEMEN_SUPPLIER,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* Get the account_id of the user who originally entered this entry. */
SELECT  added_by_user_id
INTO    cur_added_by_user_id
FROM    semen_supplier
WHERE   id = in_semen_supplier_id;

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
    IF cur_user_flag & FLAG_BIT_SYSTEM_SUPER_USER = 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        
        LEAVE process_user;
    END IF;
END IF;



UPDATE semen_supplier SET    
    name                = in_name,
    contact_number      = in_contact_number,
    whatsapp            = in_whatsapp,
    messenger           = in_messenger,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_semen_supplier_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_supplier_flag,
    cur_semen_supplier_name
FROM semen_supplier
WHERE id = in_semen_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_semen_supplier_id               AS semen_supplier_id,
    cur_semen_supplier_flag             AS semen_supplier_flag,
    cur_semen_supplier_name             AS semen_supplier_name;

END $$

DELIMITER ;
