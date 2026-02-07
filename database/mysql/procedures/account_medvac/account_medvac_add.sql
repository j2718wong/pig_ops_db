DELIMITER $$

DROP PROCEDURE IF EXISTS account_medvac_add $$
CREATE PROCEDURE account_medvac_add(
    in_user_id              INT,
    in_medvac_brand_id      INT,
    in_medvac_type_id       INT,
    
    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will add account medvac entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since January 14, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;




DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';



DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_account_medvac_id                   INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;

DECLARE in_name_upper                           VARCHAR(80)     DEFAULT '';

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";




CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, 
    
    BUSINESS_OBJ_ID_FEED_BUY, /* TODO */
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


SET in_name_upper = UPPER(in_name);


/* Check for duplicate entry */

SELECT  id
INTO    cur_account_medvac_id
FROM    account_medvac
WHERE   UPPER(name) = in_name_upper
LIMIT   1;


IF cur_account_medvac_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO account_medvac(
    account_id,
    
    medvac_brand_id,
    medvac_type_id,
    
    name,
    added_by_user_id

) VALUES (
    cur_user_account_id,
    
    in_medvac_brand_id,
    in_medvac_type_id,
    
    in_name,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_medvac_id;





END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_medvac_id               AS medvac_id;

END $$

DELIMITER ;
