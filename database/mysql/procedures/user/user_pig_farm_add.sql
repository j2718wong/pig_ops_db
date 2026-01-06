DELIMITER $$

DROP PROCEDURE IF EXISTS user_pig_farm_add $$
CREATE PROCEDURE user_pig_farm_add(
    in_user_id              INT,
    
    in_pig_farm_id          INT,
    in_user_id_to_add       INT
)  

BEGIN

/** 
 * Will add user_id into a pig_farm.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;




/* account_selection.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_SELECTION_IS_DELETED   INT             DEFAULT 1;


DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_farm_account_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id,
    
    0,
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


SELECT  COUNT(*) 
INTO    cur_count 
FROM    user_pig_farm
WHERE   pig_farm_id = in_pig_farm_id AND user_id = in_user_id_to_add;

IF cur_count > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/*Insert into user_pig_farm*/
INSERT INTO user_pig_farm(
    pig_farm_id,
    user_id,
    added_by_user_id
) VALUES (
    in_pig_farm_id,
    in_user_id_to_add,
    in_user_id
);



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc;

END $$

DELIMITER ;
