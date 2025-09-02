DELIMITER $$

DROP PROCEDURE IF EXISTS account_growing_ops_create $$
CREATE PROCEDURE account_growing_ops_create(
    in_account_id               INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 19, 2025
 *
 */


DECLARE PIG_OPERATION_TYPE_GESTATING          INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING          INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_GROWING            INT             DEFAULT 3;


/* Default account gestating operation; numdays since birth*/
DECLARE LACTATING_OPS_NUM_DAYS_CUT_TEETH_AND_TAIL INT           DEFAULT 2;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_IRON_1    INT             DEFAULT 2;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_IRON_2    INT             DEFAULT 12;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_VITA_1    INT             DEFAULT 13;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_VITA_2    INT             DEFAULT 20;
DECLARE LACTATING_OPS_NUM_DAYS_CASTRATION       INT             DEFAULT 21;
DECLARE LACTATING_OPS_NUM_DAYS_DEWORM           INT             DEFAULT 24;



/* Create default gestating_operation for the account.*/
INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING,
    LACTATING_OPS_NUM_DAYS_CUT_TEETH_AND_TAIL,
    "Cut teeth and tail"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING,
    LACTATING_OPS_NUM_DAYS_INJECT_IRON_1,
    "Inject Iron_1"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING,
    LACTATING_OPS_NUM_DAYS_INJECT_IRON_2,
    "Inject Iron_2"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING,
    LACTATING_OPS_NUM_DAYS_INJECT_VITA_2,
    "Inject Vitamins_2"
);


INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING,
    LACTATING_OPS_NUM_DAYS_INJECT_VITA_1,
    "Inject Vitamins_1"
);


INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING,
    LACTATING_OPS_NUM_DAYS_CASTRATION,
    "Castration"
);


INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING,
    LACTATING_OPS_NUM_DAYS_DEWORM,
    "Deworm"
);


END $$

DELIMITER ;
