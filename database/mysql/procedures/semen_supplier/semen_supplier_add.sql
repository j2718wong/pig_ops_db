DELIMITER $$

DROP PROCEDURE IF EXISTS semen_supplier_add $$
CREATE PROCEDURE semen_supplier_add(
    in_user_id              INT,

    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    
    in_name                 VARCHAR(50)
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


DECLARE BUSINESS_OBJ_ID_SEMEN_SUPPLIER          INT             DEFAULT 13;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* semen_supplier.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_IS_DELETED      INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


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
SELECT  id
INTO    cur_semen_supplier_id
FROM    semen_supplier
WHERE   country_id          = in_country_id   AND
        address_level_1_id  = in_address_level_1_id   AND
        address_level_2_id  = in_address_level_2_id   AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_semen_supplier_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO semen_supplier(
    country_id,
    address_level_1_id,
    address_level_2_id,
    
    name,
    added_by_user_id
    
) VALUES (
   in_country_id,
   in_address_level_1_id,
   in_address_level_2_id,
   
   in_name,
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_semen_supplier_id;



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
