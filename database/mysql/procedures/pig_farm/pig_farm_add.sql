DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_add $$
CREATE PROCEDURE pig_farm_add(
    in_user_id              INT,

    in_name                 VARCHAR(50),
    
    in_new_country_code     VARCHAR(5),
    in_new_country_name     VARCHAR(50),
    
    
    in_country_id           INT, 
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5)
    
)  

BEGIN

/** 
 * Will add pig farm entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_app_country_id                      INT             DEFAULT 0;


DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_flag                       INT             DEFAULT 0;
DECLARE cur_pig_farm_name                       VARCHAR(50)     DEFAULT '';

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
    
    BUSINESS_OBJ_ID_PIG_FARM,
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
INTO    cur_pig_farm_id
FROM    pig_farm
WHERE   account_id = cur_user_account_id AND UPPER(name)  = UPPER(in_name)
LIMIT   1;

IF cur_pig_farm_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* Create new app_country if not yet created.*/
IF in_new_country_code IS NOT NULL THEN 
    SELECT  id 
    INTO    cur_app_country_id
    FROM    app_country
    WHERE   country_code = in_new_country_code
    LIMIT   1;
    
    IF cur_app_country_id = 0 THEN 
        INSERT INTO app_country(
            country_code,
            name
        )
        VALUES(
            in_new_country_code,
            in_new_country_name
        );
        
        SELECT LAST_INSERT_ID() INTO cur_app_country_id;
    
    END IF;
    
    SET in_country_id = cur_app_country_id;

END IF;



INSERT INTO pig_farm(
    account_id,
    flag,
    name,
    
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    latitude,
    longitude,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    1,    
    in_name,
    
    in_country_id,
    in_address_level_1_id,
    in_address_level_2_id,
    in_address_level_3_id,
    in_latitude,
    in_longitude,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_farm_id;


/*Insert into user_pig_farm*/
INSERT INTO user_pig_farm(
    pig_farm_id,
    user_id,
    added_by_user_id
) VALUES (
    cur_pig_farm_id,
    in_user_id,
    in_user_id
);



/* Count the farms already in the account*/
SELECT  COUNT(*)
INTO    cur_count
FROM    pig_farm
WHERE   account_id =  cur_user_account_id;


/* Update the account country based on the first pig_farm country. */
IF cur_count = 1 THEN 
    UPDATE account SET
        country_id      = in_country_id,
        default_farm_id = cur_pig_farm_id
    WHERE id = cur_user_account_id;

END IF;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_flag,
    cur_pig_farm_name
FROM pig_farm
WHERE id = cur_pig_farm_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_id                     AS pig_farm_id,
    cur_pig_farm_flag                   AS pig_farm_flag,
    cur_pig_farm_name                   AS pig_farm_name;
    

END $$

DELIMITER ;
