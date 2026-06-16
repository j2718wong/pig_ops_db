DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_update_fixed_expense $$
CREATE PROCEDURE pig_farm_update_fixed_expense(
    in_user_id              INT,
    in_pig_farm_id          INT,
    
    
    in_budget_electric      DECIMAL(8,2),
    in_budget_water         DECIMAL(8,2),
    in_budget_internet      DECIMAL(8,2),
    in_budget_staff         DECIMAL(8,2),
    in_budget_fuel          DECIMAL(8,2),
    in_budget_supplies      DECIMAL(8,2),
    in_budget_other         DECIMAL(8,2)

) 
 
BEGIN
/**
 * Will update pig_farm fixed expenses .
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since June 16, 2026
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;

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
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_FARM,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user: BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


UPDATE pig_farm SET
    fixed_expense_electric  = in_budget_electric,
    fixed_expense_water     = in_budget_water,   
    fixed_expense_internet  = in_budget_internet,
    fixed_expense_staff     = in_budget_staff,   
    fixed_expense_fuel      = in_budget_fuel,    
    fixed_expense_supplies  = in_budget_supplies,
    fixed_expense_other     = in_budget_other,
    
    data_ver_num_fixed_expense = data_ver_num_fixed_expense + 1   
WHERE id = in_pig_farm_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc;

END $$

DELIMITER ;
