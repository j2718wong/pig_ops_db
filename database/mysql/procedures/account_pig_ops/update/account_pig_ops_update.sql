DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_update $$
CREATE PROCEDURE account_pig_ops_update(
    in_user_id              INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT,
    
    is_medvac               INT,
    
    in_name                 VARCHAR(50),
    in_short_name           VARCHAR(15),
    in_description          VARCHAR(160)
    
)

BEGIN

/** 
 * Will update account_pig_ops entry.
 * @author Jack Wong
 * @since August 10, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS   INT                   DEFAULT 10;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC      INT             DEFAULT 2;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_ver_num_gestating_ops       INT             DEFAULT 0;

DECLARE cur_pig_ops_operation_type              INT             DEFAULT 0;
DECLARE cur_pig_ops_num_days_since              INT             DEFAULT 0;
        
DECLARE cur_account_pig_ops_account_id          INT             DEFAULT 0;
DECLARE cur_account_pig_ops_flag                INT             DEFAULT 0;
DECLARE cur_account_pig_ops_name                VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_account_pig_ops_account_id
FROM    account_pig_ops
WHERE   id = in_account_pig_ops_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_pig_ops_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS,
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


SELECT  operation_type,
        num_days_since,
        version_num,
        flag 
        
INTO    cur_pig_ops_operation_type,
        cur_pig_ops_num_days_since,
        cur_account_ver_num_gestating_ops,
        cur_account_pig_ops_flag

FROM    account_pig_ops
WHERE   id = in_account_pig_ops_id;




SET cur_account_pig_ops_flag = cur_account_pig_ops_flag & ~FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC;
IF is_medvac > 0 THEN 
    SET cur_account_pig_ops_flag = cur_account_pig_ops_flag | FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC;
END IF;


UPDATE account_pig_ops SET
    num_days_since      = in_num_days_since,
    version_num         = cur_account_ver_num_gestating_ops,
    flag                = cur_account_pig_ops_flag,
    
    name                = in_name,
    short_name          = in_short_name,
    description         = in_description,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_account_pig_ops_id;



IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
    UPDATE account SET 
        ver_num_gestating_ops = ver_num_gestating_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
END IF;


IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS THEN
    UPDATE account SET 
        ver_num_lactating_piglets_ops = ver_num_lactating_piglets_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
END IF;


IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_SOW THEN 
    UPDATE account SET 
        ver_num_lactating_sow_ops = ver_num_lactating_sow_ops + 1
    WHERE id = cur_account_pig_ops_account_id;    
END IF;
    

IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_GILT_OPS THEN 
    UPDATE account SET 
        ver_num_gilt_ops = ver_num_gilt_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
END IF;


IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS THEN 
    UPDATE account SET 
        ver_num_weaning_sow_ops = ver_num_weaning_sow_ops + 1
    WHERE id = cur_account_pig_ops_account_id;
END IF;



IF cur_pig_ops_num_days_since != in_num_days_since THEN 
    IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
        CALL account_pig_ops_update_update_prod_gestating(
            cur_user_account_id,
            in_account_pig_ops_id,
            in_num_days_since
        );
    END IF;

    IF  cur_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_SOW OR
        cur_pig_ops_operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS  THEN 
        
        CALL account_pig_ops_update_update_prod_lactating(
            cur_user_account_id,
            in_account_pig_ops_id,
            in_num_days_since
        );
    END IF;
    
    
    IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_GILT_OPS THEN 
        CALL account_pig_ops_update_update_gilts(
            cur_user_account_id,
            in_account_pig_ops_id,
            in_num_days_since
        );
    END IF;
    
    
    IF cur_pig_ops_operation_type = PIG_OPERATION_TYPE_WEANING_SOW_OPS THEN
        CALL account_pig_ops_update_update_weaning_sows(
            cur_user_account_id,
            in_account_pig_ops_id,
            in_num_days_since
        );
    END IF; 
END IF;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_ops_flag,
    cur_account_pig_ops_name
FROM account_pig_ops
WHERE id = in_account_pig_ops_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_pig_ops_id               AS account_pig_ops_id,
    cur_account_pig_ops_flag            AS account_pig_ops_flag,
    cur_account_pig_ops_name            AS account_pig_ops_name;
    


END $$

DELIMITER ;
