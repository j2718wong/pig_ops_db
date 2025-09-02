DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_staff_add $$
CREATE PROCEDURE pig_farm_staff_add(
    in_user_id              INT,

    in_pig_farm_id          INT,
    in_name                 VARCHAR(50)

)  

BEGIN

/** 
 * Will add pig_farm_staff entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF          INT             DEFAULT 10;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_staff_id                   INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_flag                 INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_name                 VARCHAR(50)     DEFAULT '';



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PIG_FARM_STAFF,
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
INTO    cur_pig_farm_staff_id
FROM    pig_farm_staff
WHERE   account_id = cur_user_account_id    AND
        pig_farm_id = in_pig_farm_id        AND
        UPPER(name)  = UPPER(in_name)
LIMIT   1;

IF cur_pig_farm_staff_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO pig_farm_staff(
    account_id,
    pig_farm_id,
    name,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_pig_farm_id,
    in_name,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_farm_staff_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_staff_flag,
    cur_pig_farm_staff_name
FROM pig_farm_staff
WHERE id = cur_pig_farm_staff_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_staff_id               AS pig_farm_id,
    cur_pig_farm_staff_flag             AS pig_farm_flag,
    cur_pig_farm_staff_name             AS pig_farm_name;
    

END $$

DELIMITER ;
