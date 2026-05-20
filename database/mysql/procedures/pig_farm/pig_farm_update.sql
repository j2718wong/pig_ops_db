DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_update $$
CREATE PROCEDURE pig_farm_update(
    in_user_id              INT,
    in_pig_farm_id          INT,

    in_name                 VARCHAR(50),
    
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5),
    
    in_num_farrowing_crates INT
    
)  

BEGIN

/** 
 * Will update pig farm entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/** app_country.flag bits*/
DECLARE FLAG_BIT_COUNTRY_ENABLE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_COUNTRY_HAS_ADDRESS_LEVELS     INT             DEFAULT 2;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_farm_account_id                     INT             DEFAULT 0;

DECLARE cur_country_id                          INT             DEFAULT 0;
DECLARE cur_country_flag                        INT             DEFAULT 0;


DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_flag                       INT             DEFAULT 0;
DECLARE cur_pig_farm_name                       VARCHAR(50)     DEFAULT '';


DECLARE cur_count                               INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_farm_account_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_FARM,
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


/* This logic is created for easier testing for countries with address or without address levels*/

SELECT  a.country_id, 
        b.flag
        
INTO    cur_country_id,
        cur_country_flag
        
FROM pig_farm a
LEFT OUTER JOIN app_country b ON a.country_id = b.id
WHERE a.id =  in_pig_farm_id;

IF cur_country_flag & FLAG_BIT_COUNTRY_HAS_ADDRESS_LEVELS > 0 THEN 
    UPDATE pig_farm SET
        name                = in_name,
        
        address_level_1_id  = in_address_level_1_id,
        address_level_2_id  = in_address_level_2_id,
        address_level_3_id  = in_address_level_3_id,
        latitude            = in_latitude,
        longitude           = in_longitude,
        
        num_farrowing_crates= in_num_farrowing_crates,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP,
        
        data_ver_num_farm   = data_ver_num_farm + 1
    WHERE id =  in_pig_farm_id;
ELSE
    UPDATE pig_farm SET
        name                = in_name,
        
        latitude            = in_latitude,
        longitude           = in_longitude,
        
        num_farrowing_crates= in_num_farrowing_crates,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP,
        
        data_ver_num_farm   = data_ver_num_farm + 1
    WHERE id =  in_pig_farm_id;

END IF;


SELECT  COUNT(*)
INTO    cur_count
FROM    pig_farm
WHERE   account_id = cur_farm_account_id;

IF cur_count = 1 THEN 
    UPDATE account SET
        name = in_name
    WHERE id = cur_farm_account_id;

END IF;




END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_flag,
    cur_pig_farm_name
FROM pig_farm
WHERE id = in_pig_farm_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_id                     AS pig_farm_id,
    cur_pig_farm_flag                   AS pig_farm_flag,
    cur_pig_farm_name                   AS pig_farm_name;
    

END $$

DELIMITER ;
