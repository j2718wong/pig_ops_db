DELIMITER $$

DROP PROCEDURE IF EXISTS account_lactating_ops_create $$
CREATE PROCEDURE account_lactating_ops_create(
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



/* Default account lactating piglets operation; num_days since birth*/
DECLARE LACTATING_OPS_NUM_DAYS_CUT_TEETH        INT             DEFAULT 0;
DECLARE LACTATING_OPS_NUM_DAYS_CUT_TAIL         INT             DEFAULT 3;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_IRON_1    INT             DEFAULT 3;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_IRON_2    INT             DEFAULT 13;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_VITA_1    INT             DEFAULT 14;
DECLARE LACTATING_OPS_NUM_DAYS_INJECT_VITA_2    INT             DEFAULT 21;
DECLARE LACTATING_OPS_NUM_DAYS_CASTRATION       INT             DEFAULT 22;
DECLARE LACTATING_OPS_NUM_DAYS_DEWORM           INT             DEFAULT 25;


/* Default account lactating sow operation; num_days since birth*/
DECLARE LACTATING_SOW_OPS_NUM_DAYS_DEWORM       INT             DEFAULT 30;




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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_CUT_TEETH,
    
    "Cut Teeth",
    "Cut Teeth",
    "Cut Teeth"
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_CUT_TAIL,
    
    "Cut Tail",
    "Cut Tail",
    "Cut Tail"
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_INJECT_IRON_1,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,

    "Inject Iron_1",
    "InjIron1"
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_INJECT_IRON_2,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Inject Iron_2",
    "InjIron2"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    version_num,
    flag,
    
    num_days_since,
    name,
    short_name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_INJECT_VITA_1,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Inject Vitamins_1",
    "InjVita1"
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_INJECT_VITA_2,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Inject Vitamins_2",
    "InjVita2"
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_CASTRATION,
    
    "Castration",
    "Castration"
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    1,
    LACTATING_OPS_NUM_DAYS_DEWORM,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Deworm",
    "Deworm"
);

UPDATE account SET 
    ver_num_lactating_piglets_ops = 1
WHERE id = in_account_id;



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
    PIG_OPERATION_TYPE_LACTATING_SOW,
    1,
    LACTATING_SOW_OPS_NUM_DAYS_DEWORM,
    FLAG_BIT_ACCOUNT_PIG_OPS_IS_MEDVAC,
    
    "Deworm",
    "Deworm"
);

UPDATE account SET 
    ver_num_lactating_sow_ops = 1
WHERE id = in_account_id;




END $$

DELIMITER ;
