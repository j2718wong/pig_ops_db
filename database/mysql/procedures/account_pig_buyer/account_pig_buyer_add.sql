DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_buyer_add $$
CREATE PROCEDURE account_pig_buyer_add(
    in_user_id              INT,
    
    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5),
    
    in_is_boar_customer     INT,
    
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50),
    in_description          VARCHAR(160)
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


/* account_pig_buyer.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED   INT             DEFAULT 1;
DECLARE FLAG_BIT_PIG_BUYER_IS_BOAR_CUSTOMER     INT             DEFAULT 2;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_pig_buyer_id                INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_flag              INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_name              VARCHAR(50)     DEFAULT '';


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


/* Check for duplicate entry */
SELECT  id
INTO    cur_account_pig_buyer_id
FROM    account_pig_buyer
WHERE   account_id          = cur_user_account_id AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_account_pig_buyer_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


SET cur_account_pig_buyer_flag  = 0;
IF in_is_boar_customer > 0 THEN
    SET cur_account_pig_buyer_flag  = FLAG_BIT_PIG_BUYER_IS_BOAR_CUSTOMER;
END IF;

INSERT INTO account_pig_buyer(
    account_id,
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
    messenger,
    
    description,
    
    added_by_user_id
    
) VALUES (
    cur_user_account_id,
    in_country_id,
    in_address_level_1_id,
    in_address_level_2_id,
    in_address_level_3_id,
    
    in_latitude,
    in_longitude,
    
    
    cur_account_pig_buyer_flag,
   
    in_name,
   
    in_contact_number,
    in_whatsapp,
    in_messenger,
    
    in_description,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_pig_buyer_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_buyer_flag,
    cur_account_pig_buyer_name
FROM account_pig_buyer
WHERE id = cur_account_pig_buyer_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_pig_buyer_id            AS account_pig_buyer_id,
    cur_account_pig_buyer_flag          AS account_pig_buyer_flag,
    cur_account_pig_buyer_name          AS account_pig_buyer_name;

END $$

DELIMITER ;
