DELIMITER $$

DROP PROCEDURE IF EXISTS pig_pen_add $$
CREATE PROCEDURE pig_pen_add(
    in_user_id              INT,

    in_pig_farm_id          INT,
    in_pig_pen_type_id      INT,
    
    in_name                 VARCHAR(20)
)  

BEGIN

/** 
 * Will add pen entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PEN                 INT             DEFAULT 33;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_pen_id                          INT             DEFAULT 0;
DECLARE cur_pig_pen_flag                        INT             DEFAULT 0;
DECLARE cur_pig_pen_name                        VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PIG_PEN,
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
INTO    cur_pig_pen_id
FROM    pig_pen
WHERE   pig_farm_id         = in_pig_farm_id   AND
        pig_pen_type_id     = in_pig_pen_type_id AND 
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_pig_pen_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO pig_pen(
    account_id,
    pig_farm_id,
    pig_pen_type_id,
    
    name,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_pig_farm_id,
    in_pig_pen_type_id,
    
    in_name,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_pen_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_pen_id                      AS pig_pen_id;

END $$

DELIMITER ;
