DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_sow_due_chklst_add $$
CREATE PROCEDURE pig_farm_sow_due_chklst_add(
    in_pig_farm_id                  INT
)  

BEGIN

/** 
 * Will add account_sow_due_chklst entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 19, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;




DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 8;




DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;

DECLARE cur_pig_farm_chklst_id                  INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";




CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, 
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS, /* TODO */
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


SELECT  account_id
INTO    cur_pig_farm_account_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;


/** Create pig_farm_sow_due_chklst entry. */
INSERT INTO pig_farm_sow_due_chklst(
    date_start_show

) VALUES (
    CURRENT_DATE
);

SELECT LAST_INSERT_ID() INTO cur_pig_farm_chklst_id;


/** Update pig_farm. */
UPDATE pig_farm SET 
    last_sow_due_chklst_id = cur_pig_farm_chklst_id
WHERE id = in_pig_farm_id;


/** Create pf_sow_due_chklst_item entries*/
INSERT INTO pf_sow_due_chklst_item(
    pf_sow_due_chklst_id,
    acc_sow_due_chklst_id
)

SELECT
    cur_pig_farm_chklst_id,
    id
FROM account_sow_due_chklst
WHERE account_id = cur_pig_farm_account_id
ORDER BY name;


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_chklst_id              AS pig_farm_chklst_id;

END $$

DELIMITER ;
