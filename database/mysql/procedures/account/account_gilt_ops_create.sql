DELIMITER $$

DROP PROCEDURE IF EXISTS account_gilt_ops_create $$
CREATE PROCEDURE account_gilt_ops_create(
    in_account_id               INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since December 12, 2025
 *
 */


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;



/* Default account lactating piglets operation; numdays since birth*/
DECLARE GILT_OPS_NUM_DAYS_HCV                   INT             DEFAULT 161;
DECLARE GILT_OPS_NUM_DAYS_PLE                   INT             DEFAULT 182;
DECLARE GILT_OPS_NUM_DAYS_PCV                   INT             DEFAULT 189;





/* Create default gestating_operation for the account.*/
INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    name,
    short_name,
    description
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GILT_OPS,
    1,
    GILT_OPS_NUM_DAYS_HCV,
    "HCV Vaccine",
    "HCV Vac",
    "Inject HCV vaccine"
);


INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    name,
    short_name,
    description
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GILT_OPS,
    1,
    GILT_OPS_NUM_DAYS_PLE,
    "PLE Vaccine",
    "PLE Vac",
    "Inject PLE vaccine"
);



INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    num_days_since,
    name,
    short_name,
    description
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GILT_OPS,
    1,
    GILT_OPS_NUM_DAYS_PCV,
    "PCV Vaccine",
    "PCV Vac",
    "Inject PCV vaccine"
);


UPDATE account SET 
    ver_num_gilt_ops = 1
WHERE id = in_account_id;




END $$

DELIMITER ;
