DELIMITER $$

DROP PROCEDURE IF EXISTS account_gestating_ops_create $$
CREATE PROCEDURE account_gestating_ops_create(
    in_account_id               INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 19, 2025
 *
 */

/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC      INT             DEFAULT 2;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* Default account gestating operation; num_days since insemination*/
DECLARE GESTATING_OPS_NUM_DAYS_CHECK_REHEAT     INT             DEFAULT 21;
DECLARE GESTATING_OPS_NUM_DAYS_INJECT_IRON      INT             DEFAULT 80;
DECLARE GESTATING_OPS_NUM_DAYS_DEWORM           INT             DEFAULT 100;





/* Create default gestating_operation for the account.*/
INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    1,
    GESTATING_OPS_NUM_DAYS_CHECK_REHEAT,
    "Check Reheat",
    "Check Reheat"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    1,
    GESTATING_OPS_NUM_DAYS_INJECT_IRON,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Inject Iron",
    "Inject Iron"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    flag,
    
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    1,
    GESTATING_OPS_NUM_DAYS_DEWORM,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Deworm",
    "Deworm"
);

UPDATE account SET 
    ver_num_gestating_ops = 1
WHERE id = in_account_id;

END $$

DELIMITER ;
