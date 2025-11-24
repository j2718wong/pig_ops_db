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


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GROWING              INT             DEFAULT 4;


/* Default account gestating operation; numdays since insemination*/
DECLARE GESTATING_OPS_NUM_DAYS_CHECK_PREGNANT   INT             DEFAULT 21;
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
    GESTATING_OPS_NUM_DAYS_CHECK_PREGNANT,
    "Check if Pregnant",
    "CheckPregnant"
);

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
    GESTATING_OPS_NUM_DAYS_INJECT_IRON,
    "Inject Iron",
    "Inject Iron"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    1,
    GESTATING_OPS_NUM_DAYS_DEWORM,
    "Deworm",
    "Deworm"
);

UPDATE account SET 
    ver_num_gestating_ops = 1
WHERE id = in_account_id;

END $$

DELIMITER ;
