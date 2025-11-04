DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_add $$
CREATE PROCEDURE account_pig_ops_add(
    in_user_id              INT,
    in_operation_type       INT,
    in_num_days_since       INT,
    
    in_name                 VARCHAR(50),
    in_description          VARCHAR(160)
)  

BEGIN

/** 
 * Will add account_pig_ops entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 8;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_ver_num_gestating_ops       INT             DEFAULT 0;

DECLARE cur_account_pig_ops_id                  INT             DEFAULT 0;
DECLARE cur_account_pig_ops_flag                INT             DEFAULT 0;
DECLARE cur_account_pig_ops_name                VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS,
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
INTO    cur_account_pig_ops_id
FROM    account_pig_ops
WHERE   account_id      = cur_user_account_id   AND 
        operation_type  = in_operation_type     AND
        UPPER(name)     = UPPER(in_name)
LIMIT   1;

IF cur_account_pig_ops_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* Get the version number of the account_pig_ops_gestating*/
SELECT  ver_num_gestating_ops
INTO    cur_account_ver_num_gestating_ops
FROM    account 
WHERE   id = cur_user_account_id;

SET cur_account_ver_num_gestating_ops = cur_account_ver_num_gestating_ops + 1;


INSERT INTO account_pig_ops(
    account_id,
    operation_type,
    num_days_since,
    version_num,
    
    name,
    description,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_operation_type,
    in_num_days_since,
    cur_account_ver_num_gestating_ops,
    
    in_name,
    in_description,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_pig_ops_id;


UPDATE account SET 
    ver_num_gestating_ops = cur_account_ver_num_gestating_ops
WHERE id = cur_user_account_id;


IF in_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
    CALL account_pig_ops_add_update_prod_gestating(
        cur_user_account_id,
        in_operation_type,
        cur_account_pig_ops_id,
        in_num_days_since
    );
END IF;

IF  in_operation_type = PIG_OPERATION_TYPE_LACTATING_SOW OR
    in_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS  THEN 
    
    CALL account_pig_ops_add_update_prod_lactating(
        cur_user_account_id,
        in_operation_type,
        cur_account_pig_ops_id,
        in_num_days_since
    );
END IF;


 

END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_ops_flag,
    cur_account_pig_ops_name
FROM account_pig_ops
WHERE id = cur_account_pig_ops_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_pig_ops_id              AS account_pig_ops_id,
    cur_account_pig_ops_flag            AS account_pig_ops_flag,
    cur_account_pig_ops_name            AS account_pig_ops_name;

END $$

DELIMITER ;
