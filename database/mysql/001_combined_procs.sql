DELIMITER $$

DROP PROCEDURE IF EXISTS basic_user_check $$
CREATE PROCEDURE basic_user_check(
    in_user_id                  INT,
    in_user_must_have_account   INT,
    in_compare_to_account_id    INT,
    
    in_business_obj_id_to_access INT, 
    in_business_obj_operation   INT, /* This must be a FLAG_BIT_OPERATION value*/
    
    OUT out_user_account_id     INT,
    OUT out_user_group_id       INT,
    
    OUT res_num                 INT,
    OUT res_code                VARCHAR(80),
    OUT res_desc                VARCHAR(180)
)  

BEGIN

/** 
 * Will perform user flag checks, account checks and user group checks.
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 18, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_USER_IS_INACTIVE                INT             DEFAULT 1;
DECLARE RES_NUM_USER_NOT_EMAIL_VERIFIED         INT             DEFAULT 2;
DECLARE RES_NUM_USER_NOT_ACCOUNT_ADMIN          INT             DEFAULT 3;
DECLARE RES_NUM_USER_NO_ACCOUNT_SET             INT             DEFAULT 4;
DECLARE RES_NUM_USER_NO_USER_GROUP_SET          INT             DEFAULT 5;


DECLARE RES_NUM_ACCOUNT_DISABLED                INT             DEFAULT 6;
DECLARE RES_NUM_ACCOUNT_STATUS_TRIAL_EXPIRED    INT             DEFAULT 7;
DECLARE RES_NUM_ACCOUNT_MISMATCH                INT             DEFAULT 8;
DECLARE RES_NUM_ACCOUNT_STATUS_UNPAID_BILL      INT             DEFAULT 9;


DECLARE RES_NUM_USER_GROUP_HAS_NO_ACCESS        INT             DEFAULT 12;
DECLARE RES_NUM_USER_GROUP_NO_ADD_PRIVILEGE     INT             DEFAULT 13;
DECLARE RES_NUM_USER_GROUP_NO_UPDATE_PRIVILEGE  INT             DEFAULT 14;
DECLARE RES_NUM_USER_GROUP_NO_DELETE_PRIVILEGE  INT             DEFAULT 15;

/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


/* These system bits can be also embedded into user.flag*/
DECLARE FLAG_BIT_SYSTEM_SUPPORT                 INT             DEFAULT 131072; /* 2^17*/
DECLARE FLAG_BIT_SYSTEM_MARKETING               INT             DEFAULT 262144; /* 2^18*/
DECLARE FLAG_BIT_SYSTEM_RESERVE_1               INT             DEFAULT 528288; /* 2^19*/
DECLARE FLAG_BIT_SYSTEM_ADMIN                   INT             DEFAULT 1048576; /* 2^20*/

/* reserved bits for future use*/
DECLARE FLAG_BIT_SYSTEM_SUPER_USER              INT             DEFAULT 33554432; /* 2^25*/



/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;

DECLARE ACCOUNT_STATUS_ID_ON_TRIAL              INT             DEFAULT 1;
DECLARE ACCOUNT_STATUS_ID_TRIAL_EXPIRED         INT             DEFAULT 2;
DECLARE ACCOUNT_STATUS_ID_UNPAID_BILL           INT             DEFAULT 3;



/* This is read from a02_business_object table. */
DECLARE BUSINESS_OBJ_ID_USER                    INT             DEFAULT 1;
DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_REQUEST         INT             DEFAULT 3;
DECLARE BUSINESS_OBJ_ID_USER_GROUP              INT             DEFAULT 4;

DECLARE BUSINESS_OBJ_ID_ACCOUNT_TRANSLATION     INT             DEFAULT 5;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_BILLING         INT             DEFAULT 6;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER       INT             DEFAULT 7;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 8;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;
DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF          INT             DEFAULT 10;
DECLARE BUSINESS_OBJ_ID_PIG_RACE                INT             DEFAULT 11;
DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;


DECLARE BUSINESS_OBJ_ID_SEMEN_SUPPLIER          INT             DEFAULT 13;
DECLARE BUSINESS_OBJ_ID_FEED_SUPPLIER           INT             DEFAULT 14;
DECLARE BUSINESS_OBJ_ID_FEED_BRAND              INT             DEFAULT 15;
DECLARE BUSINESS_OBJ_ID_FEED_TYPE               INT             DEFAULT 16;
DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;
DECLARE BUSINESS_OBJ_ID_FEED_BALANCE            INT             DEFAULT 18;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;
DECLARE BUSINESS_OBJ_ID_SEMEN_SOURCE            INT             DEFAULT 20;
DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_AI             INT             DEFAULT 22;



DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;

DECLARE BUSINESS_OBJ_ID_SOW_BOAR_BALANCE        INT             DEFAULT 27;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_RESERVED_2     INT             DEFAULT 28;

DECLARE BUSINESS_OBJ_ID_PRODUCTION_GROUP        INT             DEFAULT 29;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE SYS_USER_FLAG_MASK                      INT             DEFAULT 0;

DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_is_system_super_user           INT             DEFAULT 0;

DECLARE cur_biz_obj_flag_bit_num                INT             DEFAULT 0;

DECLARE cur_user_grp_flag_business_obj          INT             DEFAULT 0;
        
DECLARE cur_user_grp_flag_priv_user             INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_account          INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_request      INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_user_group       INT             DEFAULT 0;


DECLARE cur_user_grp_flag_priv_acc_translation  INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_billing      INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_pig_buyer    INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_pig_ops      INT             DEFAULT 0;


DECLARE cur_user_grp_flag_priv_pig_farm         INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_farm_staff   INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_race         INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_race_line    INT             DEFAULT 0;




DECLARE cur_user_grp_flag_priv_semen_supplier   INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_feed_supplier    INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_feed_brand       INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_feed_type        INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_feed_buy         INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_feed_balance     INT             DEFAULT 0;


DECLARE cur_user_grp_flag_priv_sow_boar         INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_semen_source     INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_production   INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_ai      INT             DEFAULT 0;



DECLARE cur_user_grp_flag_priv_pig_prod_pig_ops INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_pig_dead INT            DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_notes   INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_harvest INT             DEFAULT 0;

DECLARE cur_user_grp_flag_priv_sow_boar_balance INT             DEFAULT 0;


DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;


DECLARE flag_bit                                INT             DEFAULT 0;
DECLARE cur_group_flag                          INT             DEFAULT 0;


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";

SELECT  bit_num
INTO    cur_biz_obj_flag_bit_num
FROM    a02_business_object
WHERE   id = in_business_obj_id_to_access;


SELECT  
    a.flag,
    a.account_id,
    a.user_group_id,
    
    b.flag_business_obj,
    
    b.flag_priv_user,
    b.flag_priv_account,
    b.flag_priv_acc_request,
    b.flag_priv_user_group,
    
    b.flag_priv_acc_translation,
    b.flag_priv_acc_billing,
    b.flag_priv_acc_pig_buyer,
    b.flag_priv_acc_pig_ops,
    
    b.flag_priv_pig_farm,
    b.flag_priv_pig_farm_staff,
    b.flag_priv_pig_race,
    b.flag_priv_pig_race_line,
    
    b.flag_priv_semen_supplier,
    b.flag_priv_feed_supplier,
    b.flag_priv_feed_brand,
    b.flag_priv_feed_type,
    b.flag_priv_feed_buy,
    b.flag_priv_feed_balance,
    
    
    b.flag_priv_sow_boar,
    b.flag_priv_semen_source,
    b.flag_priv_pig_production,
    b.flag_priv_pig_prod_ai,
    
    
    b.flag_priv_pig_prod_pig_ops,
    b.flag_priv_pig_prod_pig_dead,
    b.flag_priv_pig_prod_notes,
    b.flag_priv_pig_prod_harvest,
    
    b.flag_priv_sow_boar_balance
    

INTO    
    cur_user_flag,
    out_user_account_id,
    out_user_group_id,
        
    cur_user_grp_flag_business_obj,
        
    cur_user_grp_flag_priv_user,
    cur_user_grp_flag_priv_account,
    cur_user_grp_flag_priv_acc_request,
    cur_user_grp_flag_priv_user_group,
    
    cur_user_grp_flag_priv_acc_translation,
    cur_user_grp_flag_priv_acc_billing,
    cur_user_grp_flag_priv_acc_pig_buyer,
    cur_user_grp_flag_priv_acc_pig_ops,
    
    cur_user_grp_flag_priv_pig_farm,
    cur_user_grp_flag_priv_pig_farm_staff,
    cur_user_grp_flag_priv_pig_race,
    cur_user_grp_flag_priv_pig_race_line,
    
    
    cur_user_grp_flag_priv_semen_supplier,
    cur_user_grp_flag_priv_feed_supplier,
    cur_user_grp_flag_priv_feed_brand,
    cur_user_grp_flag_priv_feed_type,
    cur_user_grp_flag_priv_feed_buy,
    cur_user_grp_flag_priv_feed_balance,
    
    
    cur_user_grp_flag_priv_sow_boar,
    cur_user_grp_flag_priv_semen_source,
    cur_user_grp_flag_priv_pig_production,
    cur_user_grp_flag_priv_pig_prod_ai,
    
    
    cur_user_grp_flag_priv_pig_prod_pig_ops,
    cur_user_grp_flag_priv_pig_prod_pig_dead,
    cur_user_grp_flag_priv_pig_prod_notes,
    cur_user_grp_flag_priv_pig_prod_harvest,
    
    cur_user_grp_flag_priv_sow_boar_balance
    
FROM  user a 
LEFT OUTER JOIN  user_group b ON  a.user_group_id = b.id
WHERE   a.id = in_user_id;



process_user : BEGIN

/* Check user*/
IF cur_user_flag & FLAG_BIT_USER_IS_ACTIVE = 0 THEN 
    SET res_num     = RES_NUM_USER_IS_INACTIVE;
    SET res_code    = "RES_NUM_USER_IS_INACTIVE";

    LEAVE process_user;    
END IF;


IF cur_user_flag & FLAG_BIT_USER_EMAIL_VERIFIED = 0 THEN 
    SET res_num     = RES_NUM_USER_NOT_EMAIL_VERIFIED;
    SET res_code    = "RES_NUM_USER_NOT_EMAIL_VERIFIED";

    LEAVE process_user;
END IF;


IF in_user_must_have_account = 0 THEN 
    LEAVE process_user;
END IF;


/* Check if the user is a  system super user*/
IF cur_user_flag & FLAG_BIT_SYSTEM_SUPER_USER > 0 THEN 
    SET cur_user_is_system_super_user = 1;
END IF;


/* User must be associated to an account */

IF out_user_account_id = 0 THEN 
    SET res_num     = RES_NUM_USER_NO_ACCOUNT_SET;
    SET res_code    = "RES_NUM_USER_NO_ACCOUNT_SET";

    LEAVE process_user;
END IF;


IF out_user_group_id = 0 THEN 
    SET res_num     = RES_NUM_USER_NO_USER_GROUP_SET;
    SET res_code    = "RES_NUM_USER_NO_USER_GROUP_SET";

    LEAVE process_user;
END IF;




/* Check account*/
SELECT 
    flag,
    status_id
INTO
    cur_account_flag,
    cur_account_status_id
    
FROM account
WHERE id = out_user_account_id;


/* Will ignore these checks if user is a system super user. */
IF cur_user_is_system_super_user = 0 THEN
    IF cur_account_flag & FLAG_BIT_ACCOUNT_ENABLE = 0 THEN 
        SET res_num     = RES_NUM_ACCOUNT_DISABLED;
        SET res_code    = "RES_NUM_ACCOUNT_DISABLED";
        
        IF cur_account_status_id = ACCOUNT_STATUS_ID_UNPAID_BILL THEN
            SET res_num     = RES_NUM_ACCOUNT_STATUS_UNPAID_BILL;
            SET res_code    = "RES_NUM_ACCOUNT_STATUS_UNPAID_BILL";
        
        END IF;
        
        LEAVE process_user;
    END IF;


    IF in_compare_to_account_id > 0 THEN 
        IF out_user_account_id != in_compare_to_account_id THEN 
            SET res_num     = RES_NUM_ACCOUNT_MISMATCH;
            SET res_code    = "RES_NUM_ACCOUNT_MISMATCH";

            LEAVE process_user;
        END IF;

    END IF;


    /* Check user.usergroup privileges. */

    SET flag_bit = POWER(2, cur_biz_obj_flag_bit_num);

    IF cur_user_grp_flag_business_obj & flag_bit =  0 THEN
        SET res_num     = RES_NUM_USER_GROUP_HAS_NO_ACCESS;
        SET res_code    = "RES_NUM_USER_GROUP_HAS_NO_ACCESS";

        LEAVE process_user;
    END IF;

END IF;



CASE in_business_obj_id_to_access

WHEN BUSINESS_OBJ_ID_USER THEN 
    SET cur_group_flag = cur_user_grp_flag_priv_user;

WHEN BUSINESS_OBJ_ID_ACCOUNT THEN
    SET cur_group_flag = cur_user_grp_flag_priv_account;

WHEN BUSINESS_OBJ_ID_ACCOUNT_REQUEST THEN
    SET cur_group_flag = cur_user_grp_flag_priv_acc_request;

WHEN BUSINESS_OBJ_ID_USER_GROUP THEN
    SET cur_group_flag = cur_user_grp_flag_priv_user_group;
    
    
    
WHEN BUSINESS_OBJ_ID_ACCOUNT_TRANSLATION THEN
    SET cur_group_flag = cur_user_grp_flag_priv_acc_translation;
    
WHEN BUSINESS_OBJ_ID_ACCOUNT_BILLING THEN
    SET cur_group_flag = cur_user_grp_flag_priv_acc_billing;
    
WHEN BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER THEN
    SET cur_group_flag = cur_user_grp_flag_priv_acc_pig_buyer;
    
WHEN BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS THEN
    SET cur_group_flag = cur_user_grp_flag_priv_acc_pig_ops;
    
    
WHEN BUSINESS_OBJ_ID_PIG_FARM THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_farm;
    
WHEN BUSINESS_OBJ_ID_PIG_FARM_STAFF THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_farm_staff;
    
WHEN BUSINESS_OBJ_ID_PIG_RACE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_race;
    
WHEN BUSINESS_OBJ_ID_PIG_RACE_LINE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_race_line;



    
WHEN BUSINESS_OBJ_ID_SEMEN_SUPPLIER THEN
    SET cur_group_flag = cur_user_grp_flag_priv_semen_supplier;
     
WHEN BUSINESS_OBJ_ID_FEED_SUPPLIER THEN
    SET cur_group_flag = cur_user_grp_flag_priv_feed_supplier;
    
WHEN  BUSINESS_OBJ_ID_FEED_BRAND THEN
    SET cur_group_flag = cur_user_grp_flag_priv_feed_brand;
    
WHEN BUSINESS_OBJ_ID_FEED_TYPE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_feed_type;
        
WHEN BUSINESS_OBJ_ID_FEED_BUY THEN
    SET cur_group_flag = cur_user_grp_flag_priv_feed_buy;
        
WHEN BUSINESS_OBJ_ID_FEED_BALANCE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_feed_balance;
           

WHEN BUSINESS_OBJ_ID_SOW_BOAR THEN
    SET cur_group_flag = cur_user_grp_flag_priv_sow_boar;
        
WHEN BUSINESS_OBJ_ID_SEMEN_SOURCE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_semen_source;
    
WHEN BUSINESS_OBJ_ID_PIG_PRODUCTION THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_production;
              
WHEN BUSINESS_OBJ_ID_PIG_PROD_AI THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_ai;


WHEN BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_pig_ops;
        
WHEN BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_pig_dead;
        
WHEN BUSINESS_OBJ_ID_PIG_PROD_NOTES THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_notes;

WHEN BUSINESS_OBJ_ID_PIG_PROD_HARVEST THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_harvest;
    

WHEN BUSINESS_OBJ_ID_SOW_BOAR_BALANCE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_sow_boar_balance;

END CASE;


/* Will ignore these checks if user is a system super user. */
IF cur_user_is_system_super_user = 0 THEN

    IF in_business_obj_operation = FLAG_BIT_OPERATION_ADD THEN 
        IF cur_group_flag & FLAG_BIT_OPERATION_ADD = 0 THEN 
            SET res_num     = RES_NUM_USER_GROUP_NO_ADD_PRIVILEGE;
            SET res_code    = "RES_NUM_USER_GROUP_NO_ADD_PRIVILEGE";
        
            LEAVE process_user;
        END IF;
    END IF;

    IF in_business_obj_operation = FLAG_BIT_OPERATION_UPDATE THEN 
        IF cur_group_flag & FLAG_BIT_OPERATION_UPDATE = 0 THEN 
            SET res_num     = RES_NUM_USER_GROUP_NO_UPDATE_PRIVILEGE;
            SET res_code    = "RES_NUM_USER_GROUP_NO_UPDATE_PRIVILEGE";
        
            LEAVE process_user;
        END IF;
    END IF;

    IF in_business_obj_operation = FLAG_BIT_OPERATION_DELETE THEN 
        IF cur_group_flag & FLAG_BIT_OPERATION_DELETE = 0 THEN 
            SET res_num     = RES_NUM_USER_GROUP_NO_DELETE_PRIVILEGE;
            SET res_code    = "RES_NUM_USER_GROUP_NO_DELETE_PRIVILEGE";
        
            LEAVE process_user;
        END IF;
    END IF;

END IF;




END process_user;





END $$

DELIMITER ;
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
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    GESTATING_OPS_NUM_DAYS_CHECK_PREGNANT,
    "Check if pregnant"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    GESTATING_OPS_NUM_DAYS_INJECT_IRON,
    "Inject Iron"
);

INSERT INTO account_pig_ops (
    account_id,
    operation_type,
    num_days_since,
    name
) VALUES (
    in_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    GESTATING_OPS_NUM_DAYS_DEWORM,
    "Deworm"
);


END $$

DELIMITER ;
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


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_GROWING              INT             DEFAULT 4;


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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
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
    PIG_OPERATION_TYPE_LACTATING_PIGLETS,
    LACTATING_OPS_NUM_DAYS_DEWORM,
    "Deworm"
);


END $$

DELIMITER ;
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


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS       INT             DEFAULT 8;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


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



INSERT INTO account_pig_ops(
    account_id,
    operation_type,
    num_days_since,
    
    name,
    description,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_operation_type,
    in_num_days_since,
    
    in_name,
    in_description,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_pig_ops_id;


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
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_delete $$
CREATE PROCEDURE account_pig_ops_delete(
    in_user_id              INT,
    
    in_account_pig_ops_id   INT
)  

BEGIN

/** 
 * Will delete account_pig_ops entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 21, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 10;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_pig_ops_account_id          INT             DEFAULT 0;
DECLARE cur_account_pig_ops_flag                INT             DEFAULT 0;
DECLARE cur_account_pig_ops_name                VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


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
    FLAG_BIT_OPERATION_DELETE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



UPDATE account_pig_ops SET
    flag                = flag | FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_account_pig_ops_id;




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
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_update $$
CREATE PROCEDURE account_pig_ops_update(
    in_user_id                  INT,
    
    in_account_pig_ops_id       INT,
    in_num_days_since           INT,
    
    in_name                     VARCHAR(50),
    in_description              VARCHAR(160)
    
)

BEGIN

/** 
 * Will update account_pig_ops entry.
 * @author Jack Wong
 * @since August 10, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS   INT             DEFAULT 10;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

        
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



UPDATE account_pig_ops SET
    num_days_since      = in_num_days_since,
    
    name                = in_name,
    description         = in_description,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_account_pig_ops_id;

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
DELIMITER $$

DROP PROCEDURE IF EXISTS account_register $$
CREATE PROCEDURE account_register(
    in_user_id              INT,
    
    in_country_id           INT,
    in_name                 VARCHAR(100)
)  

BEGIN

/** 
 * Will add account entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 8, 2025
 *
 */

DECLARE LOV_ID_ACCOUNT_NUMDAYS_FREE_TRIAL       INT             DEFAULT 1;


DECLARE RES_NUM_SUCCESS                             INT         DEFAULT 0;

DECLARE RES_NUM_ACCOUNT_ALREADY_REGISTERED_FOR_USER INT         DEFAULT 21;
DECLARE RES_NUM_DUPLICATE_ENTRY                     INT         DEFAULT 22;


DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


DECLARE BUSINESS_OBJ_ID_ACCOUNT                	INT             DEFAULT 2;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;




/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;

DECLARE ACCOUNT_STATUS_ID_ON_TRIAL              INT             DEFAULT 1;
DECLARE ACCOUNT_STATUS_ID_TRIAL_EXPIRED         INT             DEFAULT 2;
DECLARE ACCOUNT_STATUS_ID_UNPAID_BILL           INT             DEFAULT 3;




DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";



DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_account_id                     INT             DEFAULT 0;

DECLARE cur_num_days_trial                      INT             DEFAULT 0;


DECLARE cur_account_id                          INT             DEFAULT 0;
DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;
DECLARE cur_account_status_name                 VARCHAR(50);
DECLARE cur_account_name                        VARCHAR(100); 
DECLARE cur_account_date_trial_start            DATE;
DECLARE cur_account_date_trial_end              DATE;

DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    0, /* user has no account yet*/
    0,
    
    BUSINESS_OBJ_ID_ACCOUNT,
    FLAG_BIT_OPERATION_ADD,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN


IF cur_user_account_id > 0 THEN
    SET res_num     = RES_NUM_ACCOUNT_ALREADY_REGISTERED_FOR_USER;
    SET res_code    = "RES_NUM_ACCOUNT_ALREADY_REGISTERED_FOR_USER";
    
    LEAVE process_user;
END IF;


SELECT  val_int 
INTO    cur_num_days_trial
FROM    a01_list_of_values
WHERE   id = LOV_ID_ACCOUNT_NUMDAYS_FREE_TRIAL;


/* Check account duplicate. */
SELECT  id
INTO    cur_account_id
FROM    account
WHERE   country_id = in_country_id AND UPPER(name)  = UPPER(in_name)
LIMIT   1;


IF cur_account_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;

END IF;





INSERT INTO account(
    name,
    country_id,
    flag,
    status_id,
    date_trial_start,
    date_trial_end
) VALUES (
    in_name,
    in_country_id,
    1,
    ACCOUNT_STATUS_ID_ON_TRIAL,
    CURRENT_DATE,
    DATE_ADD(CURRENT_DATE, INTERVAL cur_num_days_trial DAY)
);

SELECT LAST_INSERT_ID() INTO cur_account_id;


CALL account_user_groups_create(cur_account_id);


SELECT  id 
INTO    cur_user_group_id
FROM    user_group
WHERE   account_id = cur_account_id AND group_num = 1;


/* The user that registers the account is an account admin. */
UPDATE user SET
    account_id      = cur_account_id,
    user_group_id   = cur_user_group_id,
    flag            = flag | FLAG_BIT_USER_IS_ACCOUNT_ADMIN
WHERE id = in_user_id;


CALL account_gestating_ops_create(cur_account_id);

CALL account_lactating_ops_create(cur_account_id);


/* Insert app_audit_log. */
SET s_desc = CONCAT("Account registered; acc_name = ", in_name);
INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_user_id,
    cur_account_id,
    AUDIT_ACTION_ADD,
    s_desc,
    CURRENT_DATE
); 


SET s_desc = "User set to ACCOUNT ADMIN";
INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_user_id,
    cur_account_id,
    AUDIT_ACTION_ADD,
    s_desc,
    CURRENT_DATE
); 


END process_user;


SELECT
    a.name,
    a.flag,
    a.status_id,
    b.name,
    a.date_trial_start,
    a.date_trial_end
INTO
    cur_account_name,
    cur_account_flag,
    cur_account_status_id,
    cur_account_status_name,
    cur_account_date_trial_start,
    cur_account_date_trial_end
FROM account a
LEFT OUTER JOIN account_status b ON a.status_id = b.id
WHERE a.id = cur_account_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_id                      AS acc_id,
    cur_account_name                    AS acc_name,
    cur_account_flag                    AS acc_flag,
    cur_account_status_id               AS acc_status_id,
    cur_account_status_name             AS acc_status_name,
    cur_account_date_trial_start        AS date_trial_start,
    cur_account_date_trial_end          AS date_trial_end;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_update $$
CREATE PROCEDURE account_update(
    in_user_id                  INT,
    
    in_name                     VARCHAR(100)
    
)

BEGIN

/** 
 * Will update account
 * @author Jack Wong
 * @since August 10, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;
DECLARE RES_NUM_USER_IS_INACTIVE                INT             DEFAULT 1;
DECLARE RES_NUM_USER_HAS_NO_ACCOUNT             INT             DEFAULT 2;
DECLARE RES_NUM_ACCOUNT_DISABLED                INT             DEFAULT 3;
DECLARE RES_NUM_ACCOUNT_STATUS_TRIAL_EXPIRED    INT             DEFAULT 4;
DECLARE RES_NUM_ACCOUNT_STATUS_UNPAID_BILL      INT             DEFAULT 5;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;


DECLARE BUSINESS_OBJ_ID_ACCOUNT                	INT             DEFAULT 2;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;
DECLARE cur_account_status_name                 VARCHAR(50);
DECLARE cur_account_name                        VARCHAR(100); 
DECLARE cur_account_date_trial_start            DATE;
DECLARE cur_account_date_trial_end              DATE;




DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";

CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, 
    
    BUSINESS_OBJ_ID_ACCOUNT,
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



UPDATE account SET
    name                = in_name,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = cur_user_account_id;


/* Insert app_audit_log. */
SET s_desc = CONCAT("old_acc_name = ", cur_account_name, "; new_acc_name = ",
    in_name);

INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_user_id,
    cur_user_account_id,
    AUDIT_ACTION_UPDATE,
    s_desc,
    CURRENT_DATE
);


END process_user;


SELECT
    a.name,
    a.flag,
    a.status_id,
    b.name,
    a.date_trial_start,
    a.date_trial_end
INTO
    cur_account_name,
    cur_account_flag,
    cur_account_status_id,
    cur_account_status_name,
    cur_account_date_trial_start,
    cur_account_date_trial_end
FROM account a
LEFT OUTER JOIN account_status b ON a.status_id = b.id
WHERE a.id = cur_user_account_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS acc_id,
    cur_account_name                    AS acc_name,
    cur_account_flag                    AS acc_flag,
    cur_account_status_id               AS acc_status_id,
    cur_account_status_name             AS acc_status_name,
    cur_account_date_trial_start        AS date_trial_start,
    cur_account_date_trial_end          AS date_trial_end;




END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_update_settings $$
CREATE PROCEDURE account_update_settings(
    in_user_id                  INT,
    
    in_day_1_on_dob             INT
    
)

BEGIN

/** 
 * Will update account
 * @author Jack Wong
 * @since September 13, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;


DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* account.flag_settings bits*/
/* If this is SET, day 1 counting will start on date of birth; otherwise next day after birth.*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_flag_settings               INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";

CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, 
    
    BUSINESS_OBJ_ID_ACCOUNT,
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


SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account
WHERE   id = cur_user_account_id;

IF in_day_1_on_dob > 0 THEN  
    SET cur_account_flag_settings = cur_account_flag_settings | FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH;
ELSE
    SET cur_account_flag_settings = cur_account_flag_settings & ~FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH;
END IF;


UPDATE account SET
    flag_settings       = cur_account_flag_settings,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = cur_user_account_id;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_account_id                 AS acc_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_user_groups_create $$
CREATE PROCEDURE account_user_groups_create(
    in_account_id               INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 19, 2025
 *
 */


DECLARE ACCOUNT_USER_GROUP_ADMIN                INT             DEFAULT 1;
DECLARE ACCOUNT_USER_GROUP_MANAGEMENT           INT             DEFAULT 2;
DECLARE ACCOUNT_USER_GROUP_OPERATIONS           INT             DEFAULT 3;
DECLARE ACCOUNT_USER_GROUP_FARM_STAFF           INT             DEFAULT 4;


/* This is read from a02_business_object table. */
DECLARE BUSINESS_OBJ_ID_USER                    INT             DEFAULT 1;
DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_REQUEST         INT             DEFAULT 3;
DECLARE BUSINESS_OBJ_ID_USER_GROUP              INT             DEFAULT 4;

DECLARE BUSINESS_OBJ_ID_ACCOUNT_TRANSLATION     INT             DEFAULT 5;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_BILLING         INT             DEFAULT 6;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER       INT             DEFAULT 7;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 8;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;
DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF          INT             DEFAULT 10;
DECLARE BUSINESS_OBJ_ID_PIG_RACE                INT             DEFAULT 11;
DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;


DECLARE BUSINESS_OBJ_ID_SEMEN_SUPPLIER          INT             DEFAULT 13;
DECLARE BUSINESS_OBJ_ID_FEED_SUPPLIER           INT             DEFAULT 14;
DECLARE BUSINESS_OBJ_ID_FEED_BRAND              INT             DEFAULT 15;
DECLARE BUSINESS_OBJ_ID_FEED_TYPE               INT             DEFAULT 16;
DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;
DECLARE BUSINESS_OBJ_ID_FEED_BALANCE            INT             DEFAULT 18;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;
DECLARE BUSINESS_OBJ_ID_SEMEN_SOURCE            INT             DEFAULT 20;
DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_AI             INT             DEFAULT 22;



DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_ADD        INT             DEFAULT 27;

DECLARE BUSINESS_OBJ_ID_SOW_BOAR_BALANCE        INT             DEFAULT 28;


DECLARE BUSINESS_OBJ_ID_PRODUCTION_GROUP        INT             DEFAULT 29;

DECLARE BUSINESS_OBJ_ID_PIG_PEN                 INT             DEFAULT 31;



/* Admin users can access all business objects, 2^31 -1*/
DECLARE FLAG_BUSINESS_OBJ_ADMIN                 BIGINT          DEFAULT 2147483647;
DECLARE FLAG_BUSINESS_OBJ_MANAGEMENT            INT             DEFAULT 0;
DECLARE FLAG_BUSINESS_OBJ_OPERATIONS            INT             DEFAULT 0;



DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE OPERATION_ADD_UPDATE_DELETE             INT             DEFAULT 7;
DECLARE OPERATION_ADD_UPDATE_ONLY               INT             DEFAULT 3;




SELECT SUM(a.flag_val)
INTO FLAG_BUSINESS_OBJ_MANAGEMENT
FROM (
    SELECT  POWER(2, bit_num) AS flag_val
    FROM    a02_business_object
    WHERE   id IN ( BUSINESS_OBJ_ID_USER,
                    BUSINESS_OBJ_ID_ACCOUNT_REQUEST,
                    
                    BUSINESS_OBJ_ID_ACCOUNT_TRANSLATION,
                    BUSINESS_OBJ_ID_ACCOUNT_BILLING,
                    BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER,
                    BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS,
                    
                                        
                    BUSINESS_OBJ_ID_PIG_FARM,
                    BUSINESS_OBJ_ID_PIG_FARM_STAFF,
                    BUSINESS_OBJ_ID_PIG_RACE,
                    BUSINESS_OBJ_ID_PIG_RACE_LINE, 
                    
                    
                    BUSINESS_OBJ_ID_SEMEN_SUPPLIER,
                    BUSINESS_OBJ_ID_FEED_SUPPLIER,
                    BUSINESS_OBJ_ID_FEED_BRAND,
                    BUSINESS_OBJ_ID_FEED_TYPE,
                    BUSINESS_OBJ_ID_FEED_BUY,
                    BUSINESS_OBJ_ID_FEED_BALANCE,
                    
                    
                    BUSINESS_OBJ_ID_SOW_BOAR, 
                    BUSINESS_OBJ_ID_SEMEN_SOURCE,
                    BUSINESS_OBJ_ID_PIG_PRODUCTION,
                    BUSINESS_OBJ_ID_PIG_PROD_AI,
                    
                    
                    BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS,
                    BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD,
                    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
                    BUSINESS_OBJ_ID_PIG_PROD_HARVEST,
                    BUSINESS_OBJ_ID_PIG_PROD_PIG_ADD,
                    
                    BUSINESS_OBJ_ID_SOW_BOAR_BALANCE
                    
                )
    ) a;
    
    
    
SELECT SUM(a.flag_val)
INTO FLAG_BUSINESS_OBJ_OPERATIONS
FROM (
    SELECT  POWER(2, bit_num) AS flag_val
    FROM    a02_business_object
    WHERE   id IN ( BUSINESS_OBJ_ID_SOW_BOAR,
                    BUSINESS_OBJ_ID_PIG_PRODUCTION,
                    BUSINESS_OBJ_ID_PIG_PROD_AI,
                    
                    BUSINESS_OBJ_ID_FEED_BALANCE, 

                    BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS,

                    BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD,
                    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
                    BUSINESS_OBJ_ID_PIG_PROD_HARVEST,
                    
                    BUSINESS_OBJ_ID_SOW_BOAR_BALANCE
                )
    ) a;




/* Create account default user_groups. Each account will have a fix 
number of user groups*/
INSERT INTO user_group(
    account_id,
    group_num,
    flag_business_obj,
    name,
    
    flag_priv_user,
    flag_priv_account,
    flag_priv_acc_request,
    flag_priv_user_group,
    
    flag_priv_acc_translation,
    flag_priv_acc_billing,
    flag_priv_acc_pig_buyer,
    flag_priv_acc_pig_ops,
    
    flag_priv_pig_farm,
    flag_priv_pig_farm_staff,
    flag_priv_pig_race,
    flag_priv_pig_race_line,
    
    flag_priv_semen_supplier,
    flag_priv_feed_supplier,
    flag_priv_feed_brand,
    flag_priv_feed_type,
    flag_priv_feed_buy,
    flag_priv_feed_balance,
    
    flag_priv_sow_boar,
    flag_priv_semen_source,
    flag_priv_pig_production,
    flag_priv_pig_prod_ai,
    
    flag_priv_pig_prod_pig_ops,
    flag_priv_pig_prod_pig_dead,
    flag_priv_pig_prod_notes,
    flag_priv_pig_prod_harvest,
    flag_priv_pig_prod_pig_add,
    
    flag_priv_sow_boar_balance
    

) VALUES (
    in_account_id,
    ACCOUNT_USER_GROUP_ADMIN,
    FLAG_BUSINESS_OBJ_ADMIN,
    'Admin',
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    

    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE
);


INSERT INTO user_group(
    account_id,
    group_num,
    flag_business_obj,
    name,
    
    flag_priv_user,
    flag_priv_account,
    flag_priv_acc_request,
    flag_priv_user_group,
    
    flag_priv_acc_translation,
    flag_priv_acc_billing,
    flag_priv_acc_pig_buyer,
    flag_priv_acc_pig_ops,
    
    flag_priv_pig_farm,
    flag_priv_pig_farm_staff,
    flag_priv_pig_race,
    flag_priv_pig_race_line,
    
    flag_priv_semen_supplier,
    flag_priv_feed_supplier,
    flag_priv_feed_brand,
    flag_priv_feed_type,
    flag_priv_feed_buy,
    flag_priv_feed_balance,
    
    flag_priv_sow_boar,
    flag_priv_semen_source,
    flag_priv_pig_production,
    flag_priv_pig_prod_ai,
    

    flag_priv_pig_prod_pig_ops,
    flag_priv_pig_prod_pig_dead,
    flag_priv_pig_prod_notes,
    flag_priv_pig_prod_harvest,
    
    flag_priv_sow_boar_balance
    
) VALUES (
    in_account_id,
    ACCOUNT_USER_GROUP_MANAGEMENT,
    FLAG_BUSINESS_OBJ_MANAGEMENT,
    'Management',
    
    OPERATION_ADD_UPDATE_ONLY,
    0,
    OPERATION_ADD_UPDATE_DELETE,
    0,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    

    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    OPERATION_ADD_UPDATE_DELETE,
    
    OPERATION_ADD_UPDATE_DELETE
);


INSERT INTO user_group(
    account_id,
    group_num,
    flag_business_obj,
    name,
    
    
    flag_priv_sow_boar,
    flag_priv_pig_production,
    
    flag_priv_feed_balance,
    
    flag_priv_pig_prod_pig_ops,
    flag_priv_pig_prod_pig_dead,
    flag_priv_pig_prod_notes,
    flag_priv_pig_prod_harvest,
    
    flag_priv_sow_boar_balance
    
) VALUES (
    in_account_id,
    ACCOUNT_USER_GROUP_OPERATIONS,
    FLAG_BUSINESS_OBJ_OPERATIONS,
    'Operations',
    
   
    OPERATION_ADD_UPDATE_ONLY,
    OPERATION_ADD_UPDATE_ONLY,
    
    OPERATION_ADD_UPDATE_ONLY,
    
    OPERATION_ADD_UPDATE_ONLY,
    OPERATION_ADD_UPDATE_ONLY,
    OPERATION_ADD_UPDATE_ONLY,
    OPERATION_ADD_UPDATE_ONLY,
    
    OPERATION_ADD_UPDATE_ONLY
);





END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_buyer_add $$
CREATE PROCEDURE account_pig_buyer_add(
    in_user_id              INT,
    
    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will add account_pig_buyer entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER       INT             DEFAULT 7;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* account_pig_buyer.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED   INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_pig_buyer_id                INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_flag              INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_name              VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER,
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
INTO    cur_account_pig_buyer_id
FROM    account_pig_buyer
WHERE   account_id          = cur_user_account_id AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_account_pig_buyer_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO account_pig_buyer(
    account_id,
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    name,
    
    contact_number,
    whatsapp,
    messenger,
    
    added_by_user_id
    
) VALUES (
    cur_user_account_id,
    in_country_id,
    in_address_level_1_id,
    in_address_level_2_id,
    in_address_level_3_id,
   
    in_name,
   
    in_contact_number,
    in_whatsapp,
    in_messenger,
   
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_account_pig_buyer_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_buyer_flag,
    cur_account_pig_buyer_name
FROM account_pig_buyer
WHERE id = cur_account_pig_buyer_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_pig_buyer_id            AS account_pig_buyer_id,
    cur_account_pig_buyer_flag          AS account_pig_buyer_flag,
    cur_account_pig_buyer_name          AS account_pig_buyer_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_buyer_delete $$
CREATE PROCEDURE account_pig_buyer_delete(
    in_user_id                  INT,
    
    in_account_pig_buyer_id     INT
)  

BEGIN

/** 
 * Will delete account_pig_buyer entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER      	INT             DEFAULT 12;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";

/* account_pig_buyer.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED   INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_pig_buyer_account_id        INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_flag              INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_name              VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_account_pig_buyer_account_id
FROM    account_pig_buyer
WHERE   id = in_account_pig_buyer_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_pig_buyer_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER,
    FLAG_BIT_OPERATION_DELETE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



UPDATE account_pig_buyer SET
    flag                = flag | FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_account_pig_buyer_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_buyer_flag,
    cur_account_pig_buyer_name
FROM account_pig_buyer
WHERE id = in_account_pig_buyer_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_pig_buyer_id             AS account_pig_buyer_id,
    cur_account_pig_buyer_flag          AS account_pig_buyer_flag,
    cur_account_pig_buyer_name          AS account_pig_buyer_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_buyer_update $$
CREATE PROCEDURE account_pig_buyer_update(
    in_user_id              INT,
    
    in_account_pig_buyer_id INT,
    
    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will add account_pig_buyer entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER       INT             DEFAULT 7;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* account_pig_buyer.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_BUYER_IS_DELETED   INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_pig_buyer_id                INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_account_id        INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_flag              INT             DEFAULT 0;
DECLARE cur_account_pig_buyer_name              VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_account_pig_buyer_account_id
FROM    account_pig_buyer
WHERE   id = in_account_pig_buyer_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_account_pig_buyer_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_ACCOUNT_PIG_BUYER,
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


UPDATE account_pig_buyer SET 
    country_id              = in_country_id,
    address_level_1_id         = in_address_level_1_id,
    address_level_2_id         = in_address_level_2_id,
    address_level_3_id         = in_address_level_3_id,
    
    name                    = in_name,    
    contact_number          = in_contact_number,
    whatsapp                = in_whatsapp,
    messenger               = in_messenger,
    
    last_update_user_id     = in_user_id,
    dt_last_update          = CURRENT_TIMESTAMP
    
WHERE id =  in_account_pig_buyer_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_account_pig_buyer_flag,
    cur_account_pig_buyer_name
FROM account_pig_buyer
WHERE id = cur_account_pig_buyer_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_pig_buyer_id            AS account_pig_buyer_id,
    cur_account_pig_buyer_flag          AS account_pig_buyer_flag,
    cur_account_pig_buyer_name          AS account_pig_buyer_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_request_user_add $$
CREATE PROCEDURE account_request_user_add(
    in_account_id               INT,
    in_requesting_user_id       INT
)

BEGIN

/** 
 * Will add account_request; this is initiated by the user.
 * @author Jack Wong
 * @since August 11, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_USER_IS_INACTIVE                INT             DEFAULT 1;
DECLARE RES_NUM_USER_NOT_EMAIL_VERIFIED         INT             DEFAULT 2;
DECLARE RES_NUM_USER_NOT_ACCOUNT_ADMIN          INT             DEFAULT 3;
DECLARE RES_NUM_USER_NO_ACCOUNT_SET             INT             DEFAULT 4;

DECLARE RES_NUM_ACCOUNT_DISABLED                INT             DEFAULT 11;
DECLARE RES_NUM_ACCOUNT_STATUS_TRIAL_EXPIRED    INT             DEFAULT 12;
DECLARE RES_NUM_ACCOUNT_STATUS_UNPAID_BILL      INT             DEFAULT 13;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 50;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;


/* account.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_ENABLE                 INT             DEFAULT 1;


DECLARE ACCOUNT_STATUS_ID_ON_TRIAL              INT             DEFAULT 1;
DECLARE ACCOUNT_STATUS_ID_TRIAL_EXPIRED         INT             DEFAULT 2;
DECLARE ACCOUNT_STATUS_ID_UNPAID_BILL           INT             DEFAULT 3;


DECLARE ACCOUNT_REQUEST_STATUS_ID_PENDING       INT             DEFAULT 1;
DECLARE ACCOUNT_REQUEST_STATUS_ID_APPROVED      INT             DEFAULT 2;
DECLARE ACCOUNT_REQUEST_STATUS_ID_REJECTED      INT             DEFAULT 3;



DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_email                          VARCHAR(100);


DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;
DECLARE cur_account_name                        VARCHAR(100); 
DECLARE cur_account_date_trial_start            DATE;
DECLARE cur_account_date_trial_end              DATE;

DECLARE cur_account_req_id                      INT             DEFAULT 0;
DECLARE cur_account_req_status_id               INT             DEFAULT 0;
DECLARE cur_account_req_status_name             VARCHAR(50)     DEFAULT '';



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        flag,
        email
INTO    
        cur_user_flag,
        cur_user_email
FROM    user 
WHERE   id = in_requesting_user_id;


process_user : BEGIN

/* Check user*/
IF cur_user_flag & FLAG_BIT_USER_IS_ACTIVE = 0 THEN 
    SET res_num     = RES_NUM_USER_IS_INACTIVE;
    SET res_code    = "RES_NUM_USER_IS_INACTIVE";

    LEAVE process_user;
END IF;

IF cur_user_flag & FLAG_BIT_USER_EMAIL_VERIFIED = 0 THEN 
    SET res_num     = RES_NUM_USER_NOT_EMAIL_VERIFIED;
    SET res_code    = "RES_NUM_USER_NOT_EMAIL_VERIFIED";

    LEAVE process_user;    
END IF;



/* Check account*/
SELECT 
    flag,
    status_id,
    name
INTO
    cur_account_flag,
    cur_account_status_id,
    cur_account_name
    
FROM account
WHERE id = in_account_id;


IF cur_account_flag & FLAG_BIT_ACCOUNT_ENABLE = 0 THEN 
    SET res_num     = RES_NUM_ACCOUNT_DISABLED;
    SET res_code    = "RES_NUM_ACCOUNT_DISABLED";
    
    IF cur_account_status_id = ACCOUNT_STATUS_ID_UNPAID_BILL THEN
        SET res_num     = RES_NUM_ACCOUNT_STATUS_UNPAID_BILL;
        SET res_code    = "RES_NUM_ACCOUNT_STATUS_UNPAID_BILL";
    
    END IF;
    
    LEAVE process_user;
END IF;


/* Check duplicate. */
SELECT  id 
INTO    cur_account_req_id
FROM    account_request
WHERE   account_id = in_account_id and requesting_user_id = in_requesting_user_id
LIMIT   1;


IF cur_account_req_id > 0 THEN
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


INSERT INTO account_request(
    account_id,
    requesting_user_id,
    status_id
) VALUES (
    in_account_id,
    in_requesting_user_id,
    ACCOUNT_REQUEST_STATUS_ID_PENDING
);

SELECT LAST_INSERT_ID() INTO cur_account_req_id;


END process_user;


SELECT
    a.status_id,
    b.name
INTO 
    cur_account_req_status_id,
    cur_account_req_status_name
FROM account_request a 
LEFT OUTER JOIN account_request_status b ON a.status_id = b.id
WHERE a.id = in_account_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_account_req_id                  AS acc_req_id,
    cur_account_req_status_id           AS acc_req_status_id,
    cur_account_req_status_name         AS acc_req_status_name;


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS account_request_user_add_approve $$
CREATE PROCEDURE account_request_user_add_approve(
    in_account_request_id       INT,
    in_approving_user_id        INT,
    in_assigned_user_group_id   INT
)

BEGIN

/** 
 * Will approve account_request to add user to account; 
 * This is initiated by the account admin user.
 * @author Jack Wong
 * @since August 11, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;




DECLARE RES_NUM_ACC_REQ_USER_ADD_ALREADY_APPROVED   INT         DEFAULT 20;





DECLARE ACCOUNT_REQUEST_STATUS_ID_PENDING       INT             DEFAULT 1;
DECLARE ACCOUNT_REQUEST_STATUS_ID_APPROVED      INT             DEFAULT 2;
DECLARE ACCOUNT_REQUEST_STATUS_ID_REJECTED      INT             DEFAULT 3;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_acc_req_status_id                   INT             DEFAULT 0;
DECLARE cur_acc_req_account_id                  INT             DEFAULT 0;
DECLARE cur_acc_req_requesting_user_id          INT             DEFAULT 0;
DECLARE cur_acc_req_status_name                 VARCHAR(50)     DEFAULT NULL;
DECLARE cur_acc_req_dt_approved                 DATETIME        DEFAULT NULL;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_approving_user_email                VARCHAR(100)    DEFAULT NULL;
DECLARE cur_approving_user_username             VARCHAR(50)     DEFAULT NULL;
DECLARE cur_approving_user_name_last            VARCHAR(50)     DEFAULT NULL;
DECLARE cur_approving_user_name_first           VARCHAR(50)     DEFAULT NULL;


DECLARE cur_requesting_user_username            VARCHAR(50)     DEFAULT NULL;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';

DECLARE s_desc                                  VARCHAR(200)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        status_id,
        account_id,
        requesting_user_id
INTO    
        cur_acc_req_status_id,
        cur_acc_req_account_id,
        cur_acc_req_requesting_user_id
        
FROM    account_request
WHERE   id = in_account_request_id;


CALL basic_user_check(in_approving_user_id, 1, cur_acc_req_account_id,
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


SELECT  email
INTO    cur_approving_user_email
FROM    user 
WHERE   id = in_approving_user_id;


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_acc_req_status_id = ACCOUNT_REQUEST_STATUS_ID_APPROVED THEN
    SET res_num     = RES_NUM_ACC_REQ_USER_ADD_ALREADY_APPROVED;
    SET res_code    = "RES_NUM_ACC_REQ_USER_ADD_ALREADY_APPROVED";

    LEAVE process_user;
END IF;


UPDATE account_request SET
    status_id           = ACCOUNT_REQUEST_STATUS_ID_APPROVED,
    approved_by_user_id = in_approving_user_id,
    dt_approved         = CURRENT_TIMESTAMP
WHERE id = in_account_request_id;


/* Update approved user. */
UPDATE user SET
    account_id      = cur_acc_req_account_id,
    user_group_id   = in_assigned_user_group_id
WHERE id = cur_acc_req_requesting_user_id;

SELECT  username
INTO    cur_requesting_user_username
FROM    user
WHERE   id = cur_acc_req_requesting_user_id;

/* Insert app_audit_log. */
SET s_desc = CONCAT("User added to account; username = ", cur_requesting_user_username);

INSERT INTO app_audit_log(
    user_id,
    account_id,
    action,
    description,
    date
) VALUES (
    in_approving_user_id,
    cur_acc_req_account_id,
    AUDIT_ACTION_UPDATE,
    s_desc,
    CURRENT_DATE
);


END process_user;


SELECT  
        a.status_id,
        b.name,
        c.username,
        c.name_last,
        c.name_first,
        a.dt_approved
INTO    
        cur_acc_req_status_id,
        cur_acc_req_status_name,
        cur_approving_user_username,
        cur_approving_user_name_last,
        cur_approving_user_name_first,
        cur_acc_req_dt_approved
        
FROM    account_request a 
LEFT OUTER JOIN account_request_status b ON a.status_id = b.id
LEFT OUTER JOIN user c ON a.approved_by_user_id = c.id
WHERE   a.id = in_account_request_id;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_account_request_id               AS acc_req_id,
    cur_acc_req_status_id               AS acc_req_status_id,
    cur_acc_req_status_name             AS acc_req_status_name,
    
    cur_approving_user_username         AS approving_user_username,
    cur_approving_user_name_last        AS approving_user_name_last,
    cur_approving_user_name_first       AS approving_user_name_first,
    cur_acc_req_dt_approved             AS acc_req_dt_approved,
    
    cur_acc_req_requesting_user_id      AS requesting_user_id,
    cur_approving_user_email                      AS requesting_user_email;


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS app_analytics_add $$
CREATE PROCEDURE app_analytics_add(
    in_user_id              INT,

    in_app_function_id      INT
)  

BEGIN

/** 
 * Will add app_analytics entry to the system.
 * This is not a user initiated request but for system usage.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */


DECLARE cur_user_account_id                     INT             DEFAULT 0;


SELECT  account_id
INTO    cur_user_account_id
FROM    user
WHERE   id = in_user_id;

INSERT INTO app_analytics(
    account_id,
    user_id,
    app_function_id,
    date_usage
) VALUES (
    cur_user_account_id,
    in_user_id,
    in_app_function_id,
    CURRENT_DATE
);

END $$

SELECT 1;

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS app_mfa_add $$
CREATE PROCEDURE app_mfa_add(
    in_business_obj_id          INT,
    in_b_table_row_id           INT,
    in_channel_id               INT,
    in_country_code             INT,
    in_mobile_num               VARCHAR(15),
    in_email                    VARCHAR(100),
    
    in_auth_code                INT,
    
    in_ts_expiry                BIGINT,
    in_dt_expiry                VARCHAR(20)
)

BEGIN

/** 
 * Will add multi factor auth entry
 * @author Jack Wong
 * @since January 4, 2024
 *
 */

 
DECLARE cur_mfa_id                              INT             DEFAULT 0;

INSERT INTO app_mfa(
    business_obj_id,
    b_table_row_id,
    channel_id,
    country_code,
    mobile_num,
    email,
    
    auth_code,
    
    ts_expiry,
    dt_expiry
)
VALUES(
    in_business_obj_id,
    in_b_table_row_id,
    in_channel_id,
    in_country_code,
    in_mobile_num,
    in_email,
    
    in_auth_code,
    
    in_ts_expiry,
    in_dt_expiry
);
SELECT LAST_INSERT_ID() INTO cur_mfa_id;


SELECT  
    cur_mfa_id                  AS mfa_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS feed_balance_add $$
CREATE PROCEDURE feed_balance_add(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_prod_group_id        INT,
    
    in_date_balance         VARCHAR(10),
    
    in_num_pigs             INT,
    
    in_num_lactating        DECIMAL(5,1),
    in_num_booster          DECIMAL(5,1),
    in_num_prestarter       DECIMAL(5,1),
    in_num_starter          DECIMAL(5,1),
    in_num_grower           DECIMAL(5,1),
    in_num_finisher         DECIMAL(5,1)
)  

BEGIN

/** 
 * Will add feed_balance entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 25, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BALANCE            INT             DEFAULT 18;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE FEED_TYPE_ID_GESTATING                  INT             DEFAULT 1;
DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;


DECLARE KG_WEIGHT_PER_UNIT_LACTATING            INT             DEFAULT 50;
DECLARE KG_WEIGHT_PER_UNIT_BOOSTER              INT             DEFAULT 1;
DECLARE KG_WEIGHT_PER_UNIT_PRESTARTER           INT             DEFAULT 25;
DECLARE KG_WEIGHT_PER_UNIT_STARTER              INT             DEFAULT 50;
DECLARE KG_WEIGHT_PER_UNIT_GROWER               INT             DEFAULT 50;
DECLARE KG_WEIGHT_PER_UNIT_FINISHER             INT             DEFAULT 50;



DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;
DECLARE cur_pig_prod_last_feed_balance_id       INT             DEFAULT 0;


DECLARE cur_feed_balance_id                     INT             DEFAULT 0;

DECLARE cur_num_days_since_birth                INT             DEFAULT 0;
DECLARE cur_num_weeks_since_birth               INT             DEFAULT 0;

DECLARE cur_kg_total_lactating                  INT             DEFAULT 0;
DECLARE cur_kg_total_booster                    INT             DEFAULT 0;
DECLARE cur_kg_total_prestarter                 INT             DEFAULT 0;
DECLARE cur_kg_total_starter                    INT             DEFAULT 0;
DECLARE cur_kg_total_grower                     INT             DEFAULT 0;
DECLARE cur_kg_total_finisher                   INT             DEFAULT 0;

DECLARE prev_consumed_kg_total                  INT             DEFAULT 0;
DECLARE curr_consumed_kg_total                  INT             DEFAULT 0;
DECLARE diff_consumed_kg_total                  INT             DEFAULT 0;

DECLARE consumption_per_pig                     DECIMAL(5,2)    DEFAULT NULL;


DECLARE cur_consumed_kg_lactating               INT             DEFAULT 0;
DECLARE cur_consumed_kg_booster                 INT             DEFAULT 0;
DECLARE cur_consumed_kg_prestarter              INT             DEFAULT 0;
DECLARE cur_consumed_kg_starter                 INT             DEFAULT 0;
DECLARE cur_consumed_kg_grower                  INT             DEFAULT 0;
DECLARE cur_consumed_kg_finisher                INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        prod_status_id,
        date_actual_birth,
        last_feed_balance_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_actual_birth,
        cur_pig_prod_last_feed_balance_id

    FROM pig_production 
    WHERE id = in_pig_prod_id;

ELSE
    IF in_prod_group_id > 0 THEN 
        SELECT 
            account_id,
            pig_prod_status_id

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM production_group 
        WHERE id = in_prod_group_id;
 
    END IF;
    
END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BALANCE,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


/* Check for duplicate entry */
IF in_pig_prod_id > 0 THEN 
    SELECT  id
    INTO    cur_feed_balance_id
    FROM    feed_balance
    WHERE   pig_prod_id         = in_pig_prod_id    AND
            date_balance        = in_date_balance
    LIMIT   1;
    
ELSE
    
    IF in_prod_group_id > 0 THEN 
        SELECT  id
        INTO    cur_feed_balance_id
        FROM    feed_balance
        WHERE   pig_prod_group_id   = in_prod_group_id    AND
                date_balance        = in_date_balance
        LIMIT   1;
    END IF;
    
END IF;

IF cur_feed_balance_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;




INSERT INTO feed_balance(
    pig_prod_id,
    pig_prod_group_id,
    
    date_balance,
    
    num_pigs,
    
    num_lactating,
    num_booster,
    num_prestarter,
    num_starter,
    num_grower,
    num_finisher,

    added_by_user_id
) VALUES (
    in_pig_prod_id,
    in_prod_group_id,
    
    in_date_balance,
    
    in_num_pigs,
    
    in_num_lactating,
    in_num_booster,
    in_num_prestarter,
    in_num_starter,
    in_num_grower,
    in_num_finisher,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_balance_id;


IF in_pig_prod_id > 0 THEN 
    /* Compute num_days_since_birth, num_weeks_since_birth*/
    IF cur_pig_prod_date_actual_birth IS NOT NULL THEN
        SET cur_num_days_since_birth    = DATEDIFF(in_date_balance, cur_pig_prod_date_actual_birth);
        SET cur_num_weeks_since_birth   = ROUND(cur_num_days_since_birth/7);
    END IF; 
    
    IF cur_pig_prod_last_feed_balance_id IS NOT NULL THEN 
        SELECT  consumed_kg_total
        INTO    prev_consumed_kg_total
        FROM    feed_balance
        WHERE   id = cur_pig_prod_last_feed_balance_id;
    END IF;
    

    UPDATE pig_production SET
        last_feed_balance_m1_id     = cur_pig_prod_last_feed_balance_id,
        last_feed_balance_id        = cur_feed_balance_id
    WHERE id = in_pig_prod_id;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_lactating
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_LACTATING   AND 
            date_buy <= in_date_balance;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_booster
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_BOOSTER     AND 
            date_buy <= in_date_balance;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_prestarter
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_PRESTARTER  AND 
            date_buy <= in_date_balance;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_starter
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_STARTER     AND 
            date_buy <= in_date_balance;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_grower
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_GROWER      AND 
            date_buy <= in_date_balance;
    
    
    SELECT  SUM(kg_total)
    INTO    cur_kg_total_finisher
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id            AND 
            feed_type_id = FEED_TYPE_ID_FINISHER    AND 
            date_buy <= in_date_balance;
    
    
    
    IF cur_kg_total_lactating IS NOT NULL THEN 
        IF in_num_lactating IS NOT NULL THEN
            SET cur_consumed_kg_lactating   = CEIL(cur_kg_total_lactating - in_num_lactating * KG_WEIGHT_PER_UNIT_LACTATING);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_lactating; 
        END IF;
    END IF; 
    
    IF cur_kg_total_booster IS NOT NULL THEN 
        IF in_num_booster IS NOT NULL THEN
            SET cur_consumed_kg_booster     = CEIL(cur_kg_total_booster - in_num_booster * KG_WEIGHT_PER_UNIT_BOOSTER);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_booster;
        END IF;
    END IF;
    
    IF cur_kg_total_prestarter IS NOT NULL THEN 
        IF in_num_prestarter IS NOT NULL THEN
            SET cur_consumed_kg_prestarter  = CEIL(cur_kg_total_prestarter - in_num_prestarter * KG_WEIGHT_PER_UNIT_PRESTARTER);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_prestarter;
        END IF;
    END IF;
    
    IF cur_kg_total_starter IS NOT NULL THEN 
        IF in_num_starter IS NOT NULL THEN
            SET cur_consumed_kg_starter     = CEIL(cur_kg_total_starter - in_num_starter * KG_WEIGHT_PER_UNIT_STARTER);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_starter;
        END IF;
    END IF;
    
    IF cur_kg_total_grower IS NOT NULL THEN 
        IF in_num_grower IS NOT NULL THEN
            SET cur_consumed_kg_grower      = CEIL(cur_kg_total_grower - in_num_grower * KG_WEIGHT_PER_UNIT_GROWER);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_grower;
        END IF;
    END IF;
    
    IF cur_kg_total_finisher IS NOT NULL THEN 
        IF in_num_finisher IS NOT NULL THEN
            SET cur_consumed_kg_finisher    = CEIL(cur_kg_total_finisher - in_num_finisher * KG_WEIGHT_PER_UNIT_FINISHER);
            SET curr_consumed_kg_total      = curr_consumed_kg_total + cur_consumed_kg_finisher;
        END IF;
    END IF;
    
    
    SET diff_consumed_kg_total = curr_consumed_kg_total - prev_consumed_kg_total;
    
    IF in_num_pigs > 0 THEN 
        SET consumption_per_pig = diff_consumed_kg_total / in_num_pigs;
    END IF;
    
    UPDATE feed_balance SET 
        num_days_since_birth    = cur_num_days_since_birth,
        num_weeks_since_birth   = cur_num_weeks_since_birth,
        
        consumed_kg_booster     = cur_consumed_kg_booster,
        consumed_kg_lactating   = cur_consumed_kg_lactating,
        consumed_kg_prestarter  = cur_consumed_kg_prestarter,
        consumed_kg_starter     = cur_consumed_kg_starter,
        consumed_kg_grower      = cur_consumed_kg_grower,
        consumed_kg_finisher    = cur_consumed_kg_finisher,
        
        consumed_kg_total       = curr_consumed_kg_total,
        diff_consumed_kg_total  = diff_consumed_kg_total,
        diff_consumption_per_pig = consumption_per_pig
        
    WHERE id = cur_feed_balance_id;
    
    
END IF;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_balance_id                 AS feed_balance_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS feed_balance_update $$
CREATE PROCEDURE feed_balance_update(
    in_user_id              INT,
    
    in_feed_balance_id      INT,
    
    in_date_balance         VARCHAR(10),
    
    in_num_pigs             INT,
    
    in_num_lactating        DECIMAL(5,1),
    in_num_booster          DECIMAL(5,1),
    in_num_prestarter       DECIMAL(5,1),
    in_num_starter          DECIMAL(5,1),
    in_num_grower           DECIMAL(5,1),
    in_num_finisher         DECIMAL(5,1)
)  

BEGIN

/** 
 * Will update feed_balance entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 25, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_FEED_BALANCE            INT             DEFAULT 18;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE FEED_TYPE_ID_GESTATING                  INT             DEFAULT 1;
DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_group_id                   INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;




DECLARE cur_pig_prod_feed_bal_id                INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  pig_prod_id
        pig_prod_group_id

INTO    cur_pig_prod_id,
        cur_pig_prod_group_id

FROM    feed_balance 
WHERE   id = in_feed_balance_id;


IF cur_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        pig_prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production 
    WHERE id = cur_pig_prod_id;

ELSE
    SELECT 
        account_id,
        pig_prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production_group 
    WHERE id = cur_pig_prod_group_id;

END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BALANCE,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


UPDATE pig_prod_feed_bal SET 
    date_balance        = in_date_balance,
    
    num_pigs            = in_num_pigs,
    
    num_l_lactating     = in_num_lactating,
    num_l_booster       = in_num_booster,
    num_l_prestarter    = in_num_prestarter,
    num_l_starter       = in_num_starter,
    num_l_grower        = in_num_grower,
    num_l_finisher      = in_num_finisher,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_feed_balance_id;

SELECT LAST_INSERT_ID() INTO cur_pig_prod_feed_bal_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_feed_bal_id            AS pig_prod_feed_bal_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS feed_brand_add $$
CREATE PROCEDURE feed_brand_add(
    in_user_id              INT,

    in_country_id           INT,
    
    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will add feed_brand entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_FEED_BRAND              INT             DEFAULT 15;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* feed_brand.flag bits*/
DECLARE FLAG_BIT_FEED_BRAND_IS_DELETED          INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_feed_brand_id                       INT             DEFAULT 0;
DECLARE cur_feed_brand_flag                     INT             DEFAULT 0;
DECLARE cur_feed_brand_name                     VARCHAR(50)     DEFAULT '';

DECLARE in_normalized_name                      VARCHAR(50)     DEFAULT '';

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_FEED_BRAND,
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


SET in_normalized_name = UPPER(in_name);

/* Check for duplicate entry */
SELECT  id
INTO    cur_feed_brand_id
FROM    feed_brand
WHERE   country_id          = in_country_id   AND
        name                = in_normalized_name
LIMIT   1;

IF cur_feed_brand_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO feed_brand(
    country_id,
    
    name,
    added_by_user_id
    
) VALUES (
   in_country_id,
  
   in_normalized_name,
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_brand_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_feed_brand_flag,
    cur_feed_brand_name
FROM feed_brand
WHERE id = cur_feed_brand_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_brand_id                   AS feed_brand_id,
    cur_feed_brand_flag                 AS feed_brand_flag,
    cur_feed_brand_name                 AS feed_brand_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS feed_buy_add $$
CREATE PROCEDURE feed_buy_add(
    in_user_id              INT,
    
    in_pig_farm_id          INT,
    in_pig_prod_id          INT,
    in_prod_group_id        INT,
    
    in_date_buy             VARCHAR(10),
    in_feed_type_id         INT,
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    in_quantity             INT,
    in_kg_per_unit          DECIMAL(5,1),
    
    in_unit_cost            DECIMAL(8,2),
    in_total_cost           DECIMAL(8,2)
)  

BEGIN

/** 
 * Will add feed_buy entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 31, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_feed_quantity                       INT             DEFAULT 0;
DECLARE cur_feed_weight_kg                      INT             DEFAULT 0;
DECLARE cur_total_cost                          DECIMAL(8,2)    DEFAULT 0;


DECLARE cur_feed_quantity_b4                    INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_b4                   INT             DEFAULT 0;
DECLARE cur_total_cost_b4                       DECIMAL(8,2)    DEFAULT 0;




DECLARE cur_feed_buy_id                         INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production 
    WHERE id = in_pig_prod_id;

ELSE 
    IF in_prod_group_id > 0 THEN 
        SELECT 
            account_id,
            prod_status_id

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM production_group 
        WHERE id = in_prod_group_id;
        
    ELSE
        SELECT 
            account_id,
            1

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM pig_farm 
        WHERE id = in_pig_farm_id;
    END IF;

END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


/* Check for duplicate entry */
IF in_pig_prod_id > 0 THEN 
    SELECT  id
    INTO    cur_feed_buy_id
    FROM    feed_buy
    WHERE   pig_prod_id         = in_pig_prod_id    AND
            date_buy            = in_date_buy       AND
            feed_type_id        = in_feed_type_id
    LIMIT   1;
    
ELSE 

    IF in_prod_group_id > 0 THEN 
        SELECT  id
        INTO    cur_feed_buy_id
        FROM    feed_buy
        WHERE   pig_prod_group_id   = in_prod_group_id  AND
                date_buy            = in_date_buy       AND
                feed_type_id        = in_feed_type_id
        LIMIT   1;

    ELSE
        SELECT  id
        INTO    cur_feed_buy_id
        FROM    feed_buy
        WHERE   pig_farm_id         = in_pig_farm_id  AND
                date_buy            = in_date_buy     AND
                feed_type_id        = in_feed_type_id
        LIMIT   1;
    END IF;
    
END IF;

IF cur_feed_buy_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO feed_buy(
    pig_farm_id,
    pig_prod_id,
    pig_prod_group_id,
    
    date_buy,
    
    feed_type_id,
    feed_brand_id,
    feed_supplier_id,
    
    quantity,
    kg_per_unit,
    kg_total,
    
    unit_cost,
    total_cost,
    
    added_by_user_id

) VALUES (
    in_pig_farm_id,
    in_pig_prod_id,
    in_prod_group_id,
    
    in_date_buy,
    
    in_feed_type_id,
    in_feed_brand_id,
    in_feed_supplier_id,
    
    in_quantity,
    in_kg_per_unit,
    in_quantity * in_kg_per_unit,
    
    in_unit_cost,
    in_total_cost,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_buy_id;


IF in_pig_prod_id > 0 THEN
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity,
            cur_feed_weight_kg,
            cur_total_cost
    FROM    feed_buy
    WHERE   pig_prod_id = in_pig_prod_id AND feed_type_id = in_feed_type_id;


    IF in_feed_type_id = FEED_TYPE_ID_LACTATING THEN
        UPDATE pig_production SET 
            num_b_lactating     = cur_feed_quantity,
            num_b_kg_lactating  = cur_feed_weight_kg,
            cost_lactating      = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;

    
    IF in_feed_type_id = FEED_TYPE_ID_BOOSTER THEN
        UPDATE pig_production SET 
            num_b_booster       = cur_feed_quantity,
            num_b_kg_booster    = cur_feed_weight_kg,
            cost_booster        = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;

    
    IF in_feed_type_id = FEED_TYPE_ID_PRESTARTER THEN 
        UPDATE pig_production SET 
            num_b_prestarter    = cur_feed_quantity,
            num_b_kg_prestarter = cur_feed_weight_kg,
            cost_prestarter     = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_STARTER THEN 
        UPDATE pig_production SET 
            num_b_starter       = cur_feed_quantity,
            num_b_kg_starter    = cur_feed_weight_kg,
            cost_starter        = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 
         UPDATE pig_production SET 
            num_b_grower        = cur_feed_quantity,
            num_b_kg_grower     = cur_feed_weight_kg,
            cost_grower         = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;
    
    IF in_feed_type_id = FEED_TYPE_ID_FINISHER THEN 
        UPDATE pig_production SET 
            num_b_finisher      = cur_feed_quantity,
            num_b_kg_finisher   = cur_feed_weight_kg,
            cost_finisher       = cur_total_cost
        WHERE id = in_pig_prod_id;
    END IF;
    
END IF;



IF in_prod_group_id > 0 THEN 

    /* Sum for the group.*/   
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity,
            cur_feed_weight_kg,
            cur_total_cost
    FROM    feed_buy
    WHERE   pig_prod_group_id = in_prod_group_id AND feed_type_id = in_feed_type_id;
        
    
    /* Sum for for each pig prod when not yet in group.*/
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_b4,
            cur_feed_weight_kg_b4,
            cur_total_cost_b4
    FROM    feed_buy
    WHERE   pig_prod_id IN (SELECT pig_prod_id 
                            FROM production_group_pig_prod 
                            WHERE production_group_id = in_prod_group_id) AND feed_type_id = in_feed_type_id;
    
        
    IF in_feed_type_id = FEED_TYPE_ID_LACTATING THEN
        UPDATE pig_production SET 
            num_b_lactating     = cur_feed_quantity,
            num_b_kg_lactating  = cur_feed_weight_kg,
            cost_lactating      = cur_total_cost
        WHERE id = in_prod_group_id;        
    END IF;

    
    IF in_feed_type_id = FEED_TYPE_ID_BOOSTER THEN
        UPDATE pig_production SET 
            num_b_booster       = cur_feed_quantity,
            num_b_kg_booster    = cur_feed_weight_kg,
            cost_booster        = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;

    
    IF in_feed_type_id = FEED_TYPE_ID_PRESTARTER THEN 
        UPDATE pig_production SET 
            num_b_prestarter    = cur_feed_quantity,
            num_b_kg_prestarter = cur_feed_weight_kg,
            cost_prestarter     = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_STARTER THEN 
        UPDATE production_group SET 
            num_b_starter       = cur_feed_quantity,
            num_b_kg_starter    = cur_feed_weight_kg,
            cost_starter        = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 
         UPDATE pig_production SET 
            num_b_grower        = cur_feed_quantity,
            num_b_kg_grower     = cur_feed_weight_kg,
            cost_grower         = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 
         UPDATE pig_production SET 
            num_b_grower        = cur_feed_quantity,
            num_b_kg_grower     = cur_feed_weight_kg,
            cost_grower         = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;
    
    
    IF in_feed_type_id = FEED_TYPE_ID_FINISHER THEN 
        UPDATE pig_production SET 
            num_b_finisher      = cur_feed_quantity,
            num_b_kg_finisher   = cur_feed_weight_kg,
            cost_finisher       = cur_total_cost
        WHERE id = in_prod_group_id;
    END IF;
    

END IF;




/* Nothing to do yet if added by pig_farm_id*/

/* Insert INTO account_selection*/
SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_pig_prod_account_id AND 
        feed_brand_id = in_feed_brand_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        feed_brand_id
    ) VALUES (
        cur_pig_prod_account_id,
        in_feed_brand_id
    );
END IF;


SET cur_count = 0;

SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_pig_prod_account_id AND 
        feed_supplier_id = in_feed_supplier_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        feed_supplier_id
    ) VALUES (
        cur_pig_prod_account_id,
        in_feed_supplier_id
    );
END IF;





END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_buy_id                     AS feed_buy_id;

END $$

DELIMITER ;DELIMITER $$

DROP PROCEDURE IF EXISTS feed_buy_update $$
CREATE PROCEDURE feed_buy_update(
    in_user_id              INT,
    in_feed_buy_id          INT,
    
    in_date_buy             VARCHAR(10),
    in_feed_type_id         INT,
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    in_quantity             INT,
    in_kg_per_unit          DECIMAL(5,1),
    
    in_unit_cost            DECIMAL(8,2),
    in_total_cost           DECIMAL(8,2)
)  

BEGIN

/** 
 * Will update feed_buy entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 31, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_feed_buy_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_feed_buy_pig_prod_id                INT             DEFAULT 0;
DECLARE cur_feed_buy_pig_prod_group_id          INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_feed_quantity_lactating             INT             DEFAULT 0;
DECLARE cur_feed_quantity_booster               INT             DEFAULT 0;
DECLARE cur_feed_quantity_prestarter            INT             DEFAULT 0;
DECLARE cur_feed_quantity_starter               INT             DEFAULT 0;
DECLARE cur_feed_quantity_grower                INT             DEFAULT 0;
DECLARE cur_feed_quantity_finisher              INT             DEFAULT 0;


DECLARE cur_feed_weight_kg_lactating            INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_booster              INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_prestarter           INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_starter              INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_grower               INT             DEFAULT 0;
DECLARE cur_feed_weight_kg_finisher             INT             DEFAULT 0;




DECLARE cur_total_cost_lactating                 DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_total_cost_booster                   DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_total_cost_prestarter                DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_total_cost_starter                   DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_total_cost_grower                    DECIMAL(8,2)    DEFAULT 0;
DECLARE cur_total_cost_finisher                  DECIMAL(8,2)    DEFAULT 0;


DECLARE cur_feed_buy_id                         INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT 
    pig_farm_id,
    pig_prod_id,
    pig_prod_group_id
INTO 
    cur_feed_buy_pig_farm_id,
    cur_feed_buy_pig_prod_id,
    cur_feed_buy_pig_prod_group_id
FROM feed_buy
WHERE id = in_feed_buy_id;


IF cur_feed_buy_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production  
    WHERE id = cur_feed_buy_pig_prod_id;

ELSE

    IF cur_feed_buy_pig_prod_group_id > 0 THEN 
        SELECT 
            account_id,
            prod_status_id

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM production_group  
        WHERE id = cur_feed_buy_pig_prod_group_id;
    
    ELSE
        SELECT 
            account_id,
            1

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM pig_farm 
        WHERE id = in_pig_farm_id;
    
    END IF;
END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


UPDATE feed_buy  SET
    date_buy            = in_date_buy,
    
    feed_type_id        = in_feed_type_id,
    feed_brand_id       = in_feed_brand_id,
    feed_supplier_id    = in_feed_supplier_id,
    
    quantity            = in_quantity,
    kg_per_unit         = in_kg_per_unit,
    kg_total            = in_quantity * in_kg_per_unit,
    
    unit_cost           = in_unit_cost,
    total_cost          = in_total_cost,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_feed_buy_id;



/* It is difficult to know which feed is updated; so update all;*/
IF in_pig_prod_id > 0 THEN 
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_lactating,
            cur_feed_weight_kg_lactating,
            cur_total_cost_lactating
    FROM    feed_buy
    WHERE   pig_prod_id     = in_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_LACTATING;
        
        
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_booster,
            cur_feed_weight_kg_booster,
            cur_total_cost_booster
    FROM    feed_buy
    WHERE   pig_prod_id     = in_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_BOOSTER;
        
        
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_prestarter,
            cur_feed_weight_kg_prestarter,
            cur_total_cost_prestarter
    FROM    feed_buy
    WHERE   pig_prod_id     = in_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_PRESTARTER;
        

    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_starter,
            cur_feed_weight_kg_starter,
            cur_total_cost_starter
    FROM    feed_buy
    WHERE   pig_prod_id     = in_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_STARTER;


    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_grower,
            cur_feed_weight_kg_grower,
            cur_total_cost_grower
    FROM    feed_buy
    WHERE   pig_prod_id     = in_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_GROWER;


    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
            
    INTO    cur_feed_quantity_finisher,
            cur_feed_weight_kg_finisher,
            cur_total_cost_finisher
    FROM    feed_buy
    WHERE   pig_prod_id     = in_pig_prod_id AND 
            feed_type_id    = FEED_TYPE_ID_FINISHER;

    
    /* Convert zero values to NULL*/
    IF cur_feed_quantity_lactating = 0 THEN 
        SET cur_feed_quantity_lactating     = NULL;
        SET cur_feed_weight_kg_lactating    = NULL;
        SET cur_total_cost_lactating        = NULL;
    END IF;
    
    IF cur_feed_quantity_booster = 0 THEN 
        SET cur_feed_quantity_booster       = NULL;
        SET cur_feed_weight_kg_booster      = NULL;
        SET cur_total_cost_booster          = NULL;
    END IF;
    
    IF cur_feed_quantity_prestarter = 0 THEN 
        SET cur_feed_quantity_prestarter    = NULL;
        SET cur_feed_weight_kg_prestarter   = NULL;
        SET cur_total_cost_prestarter       = NULL; 
    END IF;
    
    IF cur_feed_quantity_starter = 0 THEN 
        SET cur_feed_quantity_starter       = NULL;
        SET cur_feed_weight_kg_starter      = NULL;
        SET cur_total_cost_starter          = NULL;
    END IF;
    
    IF cur_feed_quantity_grower = 0 THEN 
        SET cur_feed_quantity_grower        = NULL;
        SET cur_feed_weight_kg_grower       = NULL;
        SET cur_total_cost_grower           = NULL;
    END IF;
    
    IF cur_feed_quantity_finisher = 0 THEN 
        SET cur_feed_quantity_finisher      = NULL;
        SET cur_feed_weight_kg_finisher     = NULL;
        SET cur_total_cost_finisher         = NULL;
    END IF;
    
        
    UPDATE pig_production SET 
        num_b_lactating     = cur_feed_quantity_lactating,
        num_b_booster       = cur_feed_quantity_booster,
        num_b_prestarter    = cur_feed_quantity_prestarter,
        num_b_starter       = cur_feed_quantity_starter,
        num_b_grower        = cur_feed_quantity_grower,
        num_b_finisher      = cur_feed_quantity_finisher,
        
        
        num_b_kg_lactating  = cur_feed_weight_kg_lactating,
        num_b_kg_booster    = cur_feed_weight_kg_booster,
        num_b_kg_prestarter = cur_feed_weight_kg_prestarter,
        num_b_kg_starter    = cur_feed_weight_kg_starter,
        num_b_kg_grower     = cur_feed_weight_kg_grower,
        num_b_kg_finisher   = cur_feed_weight_kg_finisher,
        
        
        cost_lactating      = cur_total_cost_lactating,
        cost_booster        = cur_total_cost_booster,
        cost_prestarter     = cur_total_cost_prestarter,
        cost_starter        = cur_total_cost_starter,
        cost_grower         = cur_total_cost_grower,
        cost_finisher       = cur_total_cost_finisher,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP
    WHERE id = in_pig_prod_id;

END IF;




IF cur_feed_buy_pig_prod_group_id > 0 THEN 

    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_lactating,
            cur_total_cost_lactating
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_LACTATING;
        
        
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_booster,
            cur_total_cost_booster
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_BOOSTER;
        
        
    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_prestarter,
            cur_total_cost_prestarter
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_PRESTARTER;
        

    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_starter,
            cur_total_cost_starter
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_STARTER;


    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_grower,
            cur_total_cost_grower
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_GROWER;


    SELECT  SUM(quantity),
            SUM(kg_total),
            SUM(total_cost)
    INTO    cur_feed_quantity_finisher,
            cur_total_cost_finisher
    FROM    feed_buy
    WHERE   pig_prod_group_id   = in_pig_prod_group_id AND 
            feed_type_id        = FEED_TYPE_ID_FINISHER;

        
        
    UPDATE production_group SET 
        num_b_lactating     = cur_feed_quantity_lactating,
        num_b_booster       = cur_feed_quantity_booster,
        num_b_prestarter    = cur_feed_quantity_prestarter,
        num_b_starter       = cur_feed_quantity_starter,
        num_b_grower        = cur_feed_quantity_grower,
        num_b_finisher      = cur_feed_quantity_finisher,
        
        cost_lactating      = cur_total_cost_lactating,
        cost_booster        = cur_total_cost_booster,
        cost_prestarter     = cur_total_cost_prestarter,
        cost_starter        = cur_total_cost_starter,
        cost_grower         = cur_total_cost_grower,
        cost_finisher       = cur_total_cost_finisher,
        
        last_update_user_id = in_user_id,
        dt_last_update      = CURRENT_TIMESTAMP
    WHERE id = in_pig_prod_group_id;


END IF;


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_feed_buy_id                      AS feed_buy_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS feed_supplier_add $$
CREATE PROCEDURE feed_supplier_add(
    in_user_id              INT,

    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will add feed_supplier entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_FEED_SUPPLIER           INT             DEFAULT 14;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* feed_supplier.flag bits*/
DECLARE FLAG_BIT_FEED_SUPPLIER_IS_DELETED       INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_feed_supplier_id                    INT             DEFAULT 0;
DECLARE cur_feed_supplier_flag                  INT             DEFAULT 0;
DECLARE cur_feed_supplier_name                  VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_FEED_SUPPLIER,
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
IF in_address_level_3_id IS NULL THEN
    SELECT  id
    INTO    cur_feed_supplier_id
    FROM    feed_supplier
    WHERE   country_id              = in_country_id   AND
            address_level_1_id      = in_address_level_1_id     AND
            address_level_2_id      = in_address_level_2_id     AND
            UPPER(name)             = UPPER(in_name)
    LIMIT   1;
ELSE
    SELECT  id
    INTO    cur_feed_supplier_id
    FROM    feed_supplier
    WHERE   country_id              = in_country_id   AND
            address_level_1_id      = in_address_level_1_id     AND
            address_level_2_id      = in_address_level_2_id     AND
            address_level_3_id      = in_address_level_3_id     AND
            UPPER(name)             = UPPER(in_name)
    LIMIT   1;
END IF;

IF cur_feed_supplier_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO feed_supplier(
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    name,
    added_by_user_id
    
) VALUES (
   in_country_id,
   in_address_level_1_id,
   in_address_level_2_id,
   in_address_level_3_id,
   
   in_name,
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_supplier_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_feed_supplier_flag,
    cur_feed_supplier_name
FROM feed_supplier
WHERE id = cur_feed_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_supplier_id                AS feed_supplier_id,
    cur_feed_supplier_flag              AS feed_supplier_flag,
    cur_feed_supplier_name              AS feed_supplier_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS feed_supplier_update $$
CREATE PROCEDURE feed_supplier_update(
    in_user_id              INT,
    
    in_feed_supplier_id     INT,

    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will update feed_supplier entry to the system.
 *
 * The feed_supplier object is a shared business object for all users,
 * even for users of different accounts.
 * 
 * Only these users are allowed to update:
 *
 * 1.) users of the account of the  original user who added the entry,
 *      including the original user.
 *
 * 2.) system users
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_NOT_ALLOWED_TO_UPDATE           INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_SUPPLIER           INT             DEFAULT 14;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* user.flag bits*/
DECLARE FLAG_BIT_SYSTEM_SUPER_USER              INT             DEFAULT 131072;


/* feed_supplier.flag bits*/
DECLARE FLAG_BIT_FEED_SUPPLIER_IS_DELETED       INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


DECLARE cur_added_by_user_id                    INT             DEFAULT 0;
DECLARE cur_user_orig_account_id                INT             DEFAULT 0;


DECLARE cur_feed_supplier_id                    INT             DEFAULT 0;
DECLARE cur_feed_supplier_flag                  INT             DEFAULT 0;
DECLARE cur_feed_supplier_name                  VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0, 
    
    BUSINESS_OBJ_ID_FEED_SUPPLIER,
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


/* Get the account_id of the user who originally entered this entry. */
SELECT  added_by_user_id
INTO    cur_added_by_user_id
FROM    feed_supplier
WHERE   id = in_feed_supplier_id;

SELECT  account_id
INTO    cur_user_orig_account_id
FROM    user
WHERE   id = cur_added_by_user_id;


/* Get user flag*/
SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id = in_user_id;


/* Only users of the account who added this entry can update.
Or a SYSTEM_SUPER_USER.
*/
IF cur_user_orig_account_id != cur_user_account_id THEN 
    IF cur_user_flag & FLAG_BIT_SYSTEM_SUPER_USER = 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        
        LEAVE process_user;
    END IF;
END IF;


UPDATE feed_supplier  SET 
    address_level_2_id  = in_address_level_2_id,
    address_level_3_id  = in_address_level_3_id,
    name                = in_name,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_feed_supplier_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_feed_supplier_flag,
    cur_feed_supplier_name
FROM feed_supplier
WHERE id = cur_feed_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_supplier_id                AS feed_supplier_id,
    cur_feed_supplier_flag              AS feed_supplier_flag,
    cur_feed_supplier_name              AS feed_supplier_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_add $$
CREATE PROCEDURE pig_farm_add(
    in_user_id              INT,

    in_name                 VARCHAR(50),
    
    in_country_id           INT, 
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5)
    
)  

BEGIN

/** 
 * Will add pig farm entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_ACCOUNT_EXCEED_MAX_FARMS        INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_account_farm_01_id                  INT             DEFAULT 0;
DECLARE cur_account_farm_02_id                  INT             DEFAULT 0;
DECLARE cur_account_farm_03_id                  INT             DEFAULT 0;
DECLARE cur_account_farm_04_id                  INT             DEFAULT 0;
DECLARE cur_account_farm_05_id                  INT             DEFAULT 0;

DECLARE is_added_to_account                     INT             DEFAULT 0;

DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_flag                       INT             DEFAULT 0;
DECLARE cur_pig_farm_name                       VARCHAR(50)     DEFAULT '';



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PIG_FARM,
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


/* Check account*/
SELECT 
    farm_01_id,
    farm_02_id,
    farm_03_id,
    farm_04_id,
    farm_05_id
INTO
    cur_account_farm_01_id,
    cur_account_farm_02_id,
    cur_account_farm_03_id,
    cur_account_farm_04_id,
    cur_account_farm_05_id
    
FROM account
WHERE id = cur_user_account_id;


IF  cur_account_farm_01_id > 0 AND 
    cur_account_farm_02_id > 0 AND 
    cur_account_farm_03_id > 0 AND 
    cur_account_farm_04_id > 0 AND 
    cur_account_farm_05_id > 0 THEN 
    
    
    SET res_num     = RES_NUM_ACCOUNT_EXCEED_MAX_FARMS;
    SET res_code    = "RES_NUM_ACCOUNT_EXCEED_MAX_FARMS";
    
    LEAVE process_user;
END IF;


/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_farm_id
FROM    pig_farm
WHERE   account_id = cur_user_account_id AND UPPER(name)  = UPPER(in_name)
LIMIT   1;

IF cur_pig_farm_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO pig_farm(
    account_id,
    flag,
    name,
    
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    latitude,
    longitude,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    1,    
    in_name,
    
    in_country_id,
    in_address_level_1_id,
    in_address_level_2_id,
    in_address_level_3_id,
    in_latitude,
    in_longitude,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_farm_id;



IF is_added_to_account = 0 AND cur_account_farm_01_id = 0 THEN
    UPDATE account SET 
        farm_01_id = cur_pig_farm_id
    WHERE id = cur_user_account_id;
    
    SET is_added_to_account = 1;
END IF;

IF is_added_to_account = 0 AND  cur_account_farm_02_id = 0 THEN
    UPDATE account SET 
        farm_02_id = cur_pig_farm_id
    WHERE id = cur_user_account_id;

    SET is_added_to_account = 1;
END IF;

IF is_added_to_account = 0 AND  cur_account_farm_03_id = 0 THEN
    UPDATE account SET 
        farm_03_id = cur_pig_farm_id
    WHERE id = cur_user_account_id;

    SET is_added_to_account = 1;
END IF;

IF is_added_to_account = 0 AND  cur_account_farm_04_id = 0 THEN
    UPDATE account SET 
        farm_04_id = cur_pig_farm_id
    WHERE id = cur_user_account_id;

    SET is_added_to_account = 1;
END IF;

IF is_added_to_account = 0 AND  cur_account_farm_05_id = 0 THEN
    UPDATE account SET 
        farm_05_id = cur_pig_farm_id
    WHERE id = cur_user_account_id;

    SET is_added_to_account = 1;
END IF;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_flag,
    cur_pig_farm_name
FROM pig_farm
WHERE id = cur_pig_farm_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_id                     AS pig_farm_id,
    cur_pig_farm_flag                   AS pig_farm_flag,
    cur_pig_farm_name                   AS pig_farm_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_update $$
CREATE PROCEDURE pig_farm_update(
    in_user_id              INT,
    in_pig_farm_id          INT,

    in_name                 VARCHAR(50),
    
    in_country_id           INT, 
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    in_latitude             DECIMAL(10,5),
    in_longitude            DECIMAL(10,5)
    
)  

BEGIN

/** 
 * Will update pig farm entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_farm_account_id                     INT             DEFAULT 0;


DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_flag                       INT             DEFAULT 0;
DECLARE cur_pig_farm_name                       VARCHAR(50)     DEFAULT '';



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_farm_account_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_FARM,
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



UPDATE pig_farm SET
    name                = in_name,
    
    country_id          = in_country_id,
    address_level_1_id  = in_address_level_1_id,
    address_level_2_id  = in_address_level_2_id,
    address_level_3_id  = in_address_level_3_id,
    latitude            = in_latitude,
    longitude           = in_longitude,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_pig_farm_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_flag,
    cur_pig_farm_name
FROM pig_farm
WHERE id = in_pig_farm_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_id                     AS pig_farm_id,
    cur_pig_farm_flag                   AS pig_farm_flag,
    cur_pig_farm_name                   AS pig_farm_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_staff_add $$
CREATE PROCEDURE pig_farm_staff_add(
    in_user_id                  INT,

    in_pig_farm_id              INT,
    in_staff_user_id            INT,
    in_name                     VARCHAR(50)

)  

BEGIN

/** 
 * Will add pig_farm_staff entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF          INT             DEFAULT 10;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_staff_id                   INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_flag                 INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_name                 VARCHAR(50)     DEFAULT '';



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PIG_FARM_STAFF,
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
INTO    cur_pig_farm_staff_id
FROM    pig_farm_staff
WHERE   account_id = cur_user_account_id    AND
        pig_farm_id = in_pig_farm_id        AND
        UPPER(name)  = UPPER(in_name)
LIMIT   1;

IF cur_pig_farm_staff_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO pig_farm_staff(
    account_id,
    pig_farm_id,
    user_id,
    name,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_pig_farm_id,
    in_staff_user_id,
    in_name,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_farm_staff_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_staff_flag,
    cur_pig_farm_staff_name
FROM pig_farm_staff
WHERE id = cur_pig_farm_staff_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_farm_staff_id               AS pig_farm_id,
    cur_pig_farm_staff_flag             AS pig_farm_flag,
    cur_pig_farm_staff_name             AS pig_farm_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_staff_delete $$
CREATE PROCEDURE pig_farm_staff_delete(
    in_user_id                  INT,
    
    in_pig_farm_staff_id         INT
)  

BEGIN

/** 
 * Will delete pig_farm_staff entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF           INT            DEFAULT 6;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";

/* pig_farm_staff.flag bits*/
DECLARE FLAG_BIT_PIG_FARM_STAFF_IS_DELETED      INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_staff_account_id           INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_flag                 INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_name                 VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_farm_staff_account_id
FROM    pig_farm_staff
WHERE   id = in_pig_farm_staff_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_staff_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_FARM_STAFF,
    FLAG_BIT_OPERATION_DELETE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



UPDATE pig_farm_staff SET
    flag                = flag | FLAG_BIT_PIG_FARM_STAFF_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_pig_farm_staff_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_staff_flag,
    cur_pig_farm_staff_name
FROM pig_farm_staff
WHERE id = in_pig_farm_staff_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_farm_staff_id                AS pig_farm_staff_id,
    cur_pig_farm_staff_flag             AS pig_farm_staff_flag,
    cur_pig_farm_staff_name             AS pig_farm_staff_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_staff_update $$
CREATE PROCEDURE pig_farm_staff_update(
    in_user_id                  INT,
    
    in_pig_farm_staff_id        INT,
    in_staff_user_id            INT,
    
    in_name                     VARCHAR(50)
    
)

BEGIN

/** 
 * Will update pig_farm_staff entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF          INT             DEFAULT 6;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_staff_id                   INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_account_id           INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_flag                 INT             DEFAULT 0;
DECLARE cur_pig_farm_staff_name                 VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_farm_staff_account_id
FROM    pig_farm_staff
WHERE   id = in_pig_farm_staff_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_staff_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_FARM_STAFF,
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


/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_farm_staff_id
FROM    pig_farm_staff
WHERE   id                  != in_pig_farm_staff_id  AND
        account_id          = cur_user_account_id   AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_pig_farm_staff_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



UPDATE pig_farm_staff SET
    name                = in_name,
    
    user_id             = in_staff_user_id,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_farm_staff_id;

END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_farm_staff_flag,
    cur_pig_farm_staff_name
FROM pig_farm_staff
WHERE id = in_pig_farm_staff_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_farm_staff_id                AS pig_farm_staff_id,
    cur_pig_farm_staff_flag             AS pig_farm_staff_flag,
    cur_pig_farm_staff_name             AS pig_farm_staff_name;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_add $$
CREATE PROCEDURE pig_prod_add(
    in_user_id              INT,
   
    in_sow_id               INT,    /* Cannot be updated*/
    in_boar_id              INT,    /* Cannot be updated*/
    in_semen_source_id      INT,    /* Cannot be updated*/
    
    in_semen_cost           DECIMAL(6,2),
    in_insemination_cost    DECIMAL(6,2),
    in_insem_cost_comments  VARCHAR(200),
    
    in_insem_staff_id       INT,
    in_date_insemination    VARCHAR(10)  /* in YYYY-MM-DD format*/
)  

BEGIN

/** 
 * Will create pig_production entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 17, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE INSEMINATION_TYPE_BOAR                  VARCHAR(2)      DEFAULT 'B';
DECLARE INSEMINATION_TYPE_ARTIFICIAL_EXTERNAL   VARCHAR(4)      DEFAULT 'AI_X';
DECLARE INSEMINATION_TYPE_ARTIFICIAL_INTERNAL   VARCHAR(4)      DEFAULT 'AI_N';


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;

DECLARE SOW_STATUS_ID_GESTATING                 INT             DEFAULT 2;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GROWING              INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_farm_sow_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_last_prod_id               INT             DEFAULT 0;
DECLARE cur_sow_boar_last_prod_status_id        INT             DEFAULT 0;


DECLARE cur_semen_source_boar_id                INT             DEFAULT 0;
DECLARE cur_semen_source_semen_supplier_id      INT             DEFAULT 0;

DECLARE cur_insemination_type                   VARCHAR(4)      DEFAULT NULL;


DECLARE cur_pig_farm_last_prod_id               INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_id                      INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.account_id,
        a.pig_farm_id,
        a.farm_sow_id,
        a.last_prod_id,
        b.prod_status_id
INTO    cur_sow_boar_account_id,
        cur_sow_boar_pig_farm_id,
        cur_sow_boar_farm_sow_id,
        cur_sow_boar_last_prod_id,
        cur_sow_boar_last_prod_status_id
FROM    sow_boar a
LEFT OUTER JOIN pig_production b ON a.last_prod_id = b.id
WHERE   a.id = in_sow_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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
INTO    cur_pig_prod_id
FROM    pig_production
WHERE   pig_farm_id         = cur_sow_boar_pig_farm_id AND
        sow_id              = in_sow_id     AND 
        date_insemination   = in_date_insemination 
LIMIT   1;


IF cur_pig_prod_id > 0 THEN
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* Set previous pig_production of this sow to not pregnant, if status is gestating*/
IF cur_sow_boar_last_prod_status_id = PRODUCTION_STATUS_ID_GESTATING THEN 
    UPDATE pig_production SET 
        prod_status_id = PRODUCTION_STATUS_ID_NOT_PREGNANT
    WHERE id = cur_sow_boar_last_prod_id;
END IF;


SELECT  last_prod_id
INTO    cur_pig_farm_last_prod_id
FROM    pig_farm
WHERE   id = cur_sow_boar_pig_farm_id;

SET cur_pig_farm_last_prod_id = cur_pig_farm_last_prod_id + 1;

IF in_boar_id IS NOT NULL THEN 
    INSERT INTO pig_production (
        account_id,
        pig_farm_id,
        farm_prod_id,
        
        sow_id,
        insemination_type,
        boar_id,
        semen_source_id,
        
        semen_cost,
        insemination_cost,
        insem_cost_comments,
        
        date_insemination,
        date_expected_birth,
        
        prod_status_id,
        insem_staff_id
    ) VALUES (
        cur_user_account_id,
        cur_sow_boar_pig_farm_id,
        cur_pig_farm_last_prod_id,
        
        in_sow_id,
        INSEMINATION_TYPE_BOAR,
        in_boar_id,
        NULL,
        
        NULL,
        in_insemination_cost,
        in_insem_cost_comments,
        
        in_date_insemination,
        DATE_ADD(in_date_insemination, INTERVAL 115 DAY),

        PRODUCTION_STATUS_ID_GESTATING,
        in_insem_staff_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;

ELSE
    /* artificial insemination */
    
    /* Check if semen is coming from external supplier*/
    SELECT  boar_id,
            semen_suplier_id
    
    INTO    cur_semen_source_boar_id,
            cur_semen_source_semen_supplier_id
    FROM semen_source 
    WHERE id = in_semen_source_id;
    
    IF cur_semen_source_semen_supplier_id > 0 THEN 
        SET cur_insemination_type = INSEMINATION_TYPE_ARTIFICIAL_EXTERNAL;
        
    ELSE
        IF cur_semen_source_boar_id > 0 THEN 
            SET cur_insemination_type = INSEMINATION_TYPE_ARTIFICIAL_INTERNAL;
        END IF;
        
    END IF;
    
    
    INSERT INTO pig_production (
        account_id,
        pig_farm_id,
        farm_prod_id,
        
        sow_id,
        insemination_type,
        boar_id,
        semen_source_id,
        
        semen_cost,
        insemination_cost,
        insem_cost_comments,
        
        date_insemination,
        date_expected_birth,
        
        prod_status_id,
        insem_staff_id
    ) VALUES (
        cur_user_account_id,
        cur_sow_boar_pig_farm_id,
        cur_pig_farm_last_prod_id,
        
        in_sow_id,
        cur_insemination_type,
        NULL,
        in_semen_source_id,
        
        in_semen_cost,
        in_insemination_cost,
        in_insem_cost_comments,
        
        in_date_insemination,
        DATE_ADD(in_date_insemination, INTERVAL 115 DAY),

        PRODUCTION_STATUS_ID_GESTATING,
        in_insem_staff_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;
    
    
    INSERT INTO pig_prod_ai(
        pig_farm_id,
        pig_prod_id,
        semen_source_id,
        insem_staff_id,
        date_insemination,
        
        added_by_user_id
    ) VALUES(
        cur_sow_boar_pig_farm_id,
        cur_pig_prod_id,
        in_semen_source_id,
        in_insem_staff_id,
        in_date_insemination,
        
        in_user_id
    );
    
    SELECT LAST_INSERT_ID() INTO cur_pig_prod_ai_id;
    
END IF; 
    

/* Increment pig_farm.last_prod_id*/
UPDATE pig_farm SET 
    last_prod_id    = cur_pig_farm_last_prod_id
WHERE id = cur_sow_boar_pig_farm_id;


/* Update sow status*/
UPDATE sow_boar SET
    last_prod_id    = cur_pig_prod_id,
    sow_status_id   = SOW_STATUS_ID_GESTATING
WHERE id = in_sow_id;


/* Create pig_prod_pig_ops entry*/
CALL pig_prod_pig_ops_add(
    in_user_id, 
    
    cur_sow_boar_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    cur_pig_prod_id, 
    in_date_insemination);


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_id                     AS pig_prod_id,
    cur_pig_prod_ai_id                  AS pig_prod_ai_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_close $$
CREATE PROCEDURE pig_prod_close(
    in_user_id              INT,
    
    in_pig_prod_id          INT
)

BEGIN

/** 
 * Will update pig_production entry.
 * @author Jack Wong
 * @since September 5, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;

DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_pig_prod_date_actual_birth          DATE;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        prod_status_id
INTO    cur_pig_prod_account_id,
        cur_pig_prod_status_id
FROM    pig_production
WHERE   id = in_pig_prod_id
LIMIT   1;


/* Operation pig_production.close will be treated as delete operation
even if the actual row is not deleted; If the production_status is set close, 
all new changes to the pig production will not be allowed.

*/

CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
    FLAG_BIT_OPERATION_DELETE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;

IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


UPDATE pig_production SET
    prod_status_id      = PRODUCTION_STATUS_ID_CLOSED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_id;

END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_fattening_add $$
CREATE PROCEDURE pig_prod_fattening_add(
    in_user_id              INT,
    in_pig_farm_id          INT,
    
    in_num_pigs             INT,
    
    in_date_weaning         VARCHAR(10) /* in YYYY-MM-DD format*/
)  

BEGIN

/** 
 * Will create pig_production fattening entry, piglets brought externally.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* pig_production.flag bits*/
DECLARE FLAG_BIT_PIGLETS_ARE_EXTERNAL           INT             DEFAULT 2;



DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;

DECLARE SOW_STATUS_ID_GESTATING                 INT             DEFAULT 2;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS            INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_GROWING              INT             DEFAULT 4;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;


DECLARE cur_pig_farm_last_prod_id               INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_id                      INT             DEFAULT 0;


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
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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
INTO    cur_pig_prod_id
FROM    pig_production
WHERE   pig_farm_id         = in_pig_farm_id    AND
        date_weaning        = in_date_weaning   AND
        (flag & FLAG_BIT_PIGLETS_ARE_EXTERNAL) > 0
LIMIT   1;


IF cur_pig_prod_id > 0 THEN
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


SELECT  last_prod_id
INTO    cur_pig_farm_last_prod_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;

SET cur_pig_farm_last_prod_id = cur_pig_farm_last_prod_id + 1;


INSERT INTO pig_production (
    account_id,
    pig_farm_id,
    farm_prod_id,
    flag,
    prod_status_id,
    
    num_pigs_current,
    date_weaning
    
) VALUES (
    cur_user_account_id,
    cur_sow_boar_pig_farm_id,
    cur_pig_farm_last_prod_id,
    FLAG_BIT_PIGLETS_ARE_EXTERNAL,
    PRODUCTION_STATUS_ID_GROWING,
    
    in_num_pigs,
    in_date_weaning
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;


/* Increment pig_farm.last_prod_id*/
UPDATE pig_farm SET 
    last_prod_id    = cur_pig_farm_last_prod_id
WHERE id = cur_sow_boar_pig_farm_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_id                     AS pig_prod_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_birth $$
CREATE PROCEDURE pig_prod_update_birth(
    in_user_id                  INT,
    
    in_pig_prod_id              INT,
    
    in_date_actual_birth        VARCHAR(10),  /* in YYYY-MM-DD format*/
    in_num_pigs_dead_at_birth   INT,
    in_num_pigs_live_m          INT,
    in_num_pigs_live_f          INT,
    
    in_birth_staff_id           INT
    
)

BEGIN

/** 
 * Will update pig_production at piglets birth entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_UPDATE_BIRTH_NOT_ALLOWED        INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE SOW_STATUS_ID_LACTATING                 INT             DEFAULT 3;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GROWING              INT             DEFAULT 4;


/* account_pig_ops.flag bits*/
DECLARE FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED     INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;

DECLARE cur_count_account_pig_ops               INT             DEFAULT 0;
DECLARE cur_count_pig_prod_pig_ops              INT             DEFAULT 0;

DECLARE date_temp                               DATE            DEFAULT NULL;
DECLARE detected_actual_date_birth_change       INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        prod_status_id,
        sow_id,
        date_actual_birth
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_status_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_date_actual_birth
        
FROM    pig_production
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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

IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_GESTATING,
                                    PRODUCTION_STATUS_ID_LACTATING) THEN 
    SET res_num     = RES_NUM_UPDATE_BIRTH_NOT_ALLOWED;
    SET res_code    = "RES_NUM_UPDATE_BIRTH_NOT_ALLOWED";
    SET res_desc    = "Production status not GESTATING or LACTATING.";
END IF;


/*
It is possible to change the date_actual_birth, but there is a series of operations
to be done to the affected business objects. So That is why need to check if the 
date_actual_birth has been modified.

*/

IF cur_pig_prod_date_actual_birth IS NULL THEN 
    SET detected_actual_date_birth_change = 1;

ELSE
    SET date_temp = STR_TO_DATE(in_date_actual_birth, '%Y-%m-%d');
    
    IF date_temp != cur_pig_prod_date_actual_birth THEN 
        SET detected_actual_date_birth_change = 1;
    END IF;

END IF;


UPDATE pig_production SET 
    date_actual_birth           = in_date_actual_birth,
    num_days_actual             = DATEDIFF(in_date_actual_birth, date_insemination),
    prod_status_id              = PRODUCTION_STATUS_ID_LACTATING,
    
    num_pigs_dead_at_birth      = in_num_pigs_dead_at_birth,
    num_pigs_live_m             = in_num_pigs_live_m,
    num_pigs_live_f             = in_num_pigs_live_f,
    
    num_pigs_current            = in_num_pigs_live_m + in_num_pigs_live_f,
    
    birth_staff_id              = in_birth_staff_id,
    
    last_update_user_id         = in_user_id,
    dt_last_update              = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_id;


UPDATE sow_boar SET 
    sow_status_id   = SOW_STATUS_ID_LACTATING
WHERE id = cur_pig_prod_sow_id;


/* Count if there are pig operations to be done for lactating sow set by account.*/
SELECT  COUNT(*)
INTO    cur_count_account_pig_ops
FROM    account_pig_ops
WHERE   account_id = in_account_id      AND 
        operation_type = PIG_OPERATION_TYPE_LACTATING_SOW AND 
        (flag & FLAG_BIT_ACCOUNT_PIG_OPS_IS_DELETED) = 0;


IF cur_count_account_pig_ops > 0 THEN 
    SELECT  COUNT(*)
    INTO    cur_count_pig_prod_pig_ops
    FROM    pig_prod_pig_ops
    WHERE   pig_prod_id = in_pig_prod_id AND 
            operation_type = PIG_OPERATION_TYPE_LACTATING_SOW;

    IF cur_count_pig_prod_pig_ops = 0 THEN 
        /* Create pig_prod_pig_ops entry*/
        CALL pig_prod_pig_ops_add(
            in_user_id,
            
            cur_pig_prod_account_id, 
            PIG_OPERATION_TYPE_LACTATING_SOW,
            in_pig_prod_id,
            in_date_actual_birth
        );
        
    ELSE
        IF detected_actual_date_birth_change > 0 THEN
            UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
                a.date_target = DATE_ADD(in_date_actual_birth, INTERVAL b.num_days_since DAY)
            WHERE   a.pig_prod_id = in_pig_prod_id AND 
                    a.operation_type = PIG_OPERATION_TYPE_LACTATING_SOW AND
                    a.account_pig_ops_id = b.id;
        END IF;

    END IF;

END IF;


SELECT  COUNT(*)
INTO    cur_count_pig_prod_pig_ops
FROM    pig_prod_pig_ops
WHERE   pig_prod_id = in_pig_prod_id AND 
        operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS;

IF cur_count_pig_prod_pig_ops = 0 THEN 
    /* Create pig_prod_pig_ops entry*/
    CALL pig_prod_pig_ops_add(
        in_user_id,
        
        cur_pig_prod_account_id, 
        PIG_OPERATION_TYPE_LACTATING_PIGLETS,
        in_pig_prod_id,
        in_date_actual_birth
    );

ELSE
    IF detected_actual_date_birth_change > 0 THEN
        UPDATE pig_prod_pig_ops a, account_pig_ops b SET 
            a.date_target = DATE_ADD(in_date_actual_birth, INTERVAL b.num_days_since DAY)
        WHERE   a.pig_prod_id = in_pig_prod_id AND 
                a.operation_type = PIG_OPERATION_TYPE_LACTATING_PIGLETS AND
                a.account_pig_ops_id = b.id;
    END IF;
END IF;

END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_feed_type $$
CREATE PROCEDURE pig_prod_update_feed_type(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_feed_type_id         INT,
    in_date                 VARCHAR(10)
)  

BEGIN

/** 
 * Will update weaning data for pig_production entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 27, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_CANNOT_UPDATE_FEED_TYPE INT            DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;



DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        prod_status_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id
        
FROM    pig_production 
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;



IF cur_pig_prod_status_id < PRODUCTION_STATUS_ID_LACTATING THEN 
    SET res_num     = RES_NUM_PIG_PROD_CANNOT_UPDATE_FEED_TYPE;
    SET res_code    = "RES_NUM_PIG_PROD_CANNOT_UPDATE_FEED_TYPE";
    SET res_desc    = "Production status is not yet LACTATING.";
    
    LEAVE process_user;
END IF;


IF in_feed_type_id = FEED_TYPE_ID_BOOSTER THEN 
    UPDATE pig_production SET
        date_booster                = in_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id = in_pig_prod_id;
END IF; 

IF in_feed_type_id = FEED_TYPE_ID_PRESTARTER THEN 
    UPDATE pig_production SET
        date_prestarter             = in_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id = in_pig_prod_id;
END IF; 

IF in_feed_type_id = FEED_TYPE_ID_STARTER THEN 
    UPDATE pig_production SET
        date_starter                = in_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id = in_pig_prod_id;
END IF; 

IF in_feed_type_id = FEED_TYPE_ID_GROWER THEN 
    UPDATE pig_production SET
        date_grower                 = in_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id = in_pig_prod_id;
END IF; 

IF in_feed_type_id = FEED_TYPE_ID_FINISHER THEN 
    UPDATE pig_production SET
        date_finisher               = in_date,
        last_update_user_id         = in_user_id,
        dt_last_update              = CURRENT_TIMESTAMP
        
    WHERE id = in_pig_prod_id;
END IF; 


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_prod_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_insem $$
CREATE PROCEDURE pig_prod_update_insem(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    
    in_semen_cost           DECIMAL(6,2),
    in_insemination_cost    DECIMAL(6,2),
    in_insem_cost_comments  VARCHAR(200),
    
    in_insem_staff_id       INT,
    in_date_insemination    VARCHAR(10)  /* in YYYY-MM-DD format*/

)

BEGIN

/** 
 * Will update pig_production entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_STATUS_NOT_GESTATING   INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA INT             DEFAULT 21;
DECLARE RES_NUM_PIG_PROD_PIGLETS_ARE_EXTERNAL   INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* pig_production.flag bits*/
DECLARE FLAG_BIT_PIGLETS_ARE_EXTERNAL           INT             DEFAULT 2;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;

DECLARE cur_pig_prod_date_actual_birth          DATE;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        prod_status_id,
        flag
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_status_id,
        cur_pig_prod_flag
FROM    pig_production
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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


IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
    SET res_num     = RES_NUM_PIG_PROD_STATUS_NOT_GESTATING;
    SET res_code    = "RES_NUM_PIG_PROD_STATUS_NOT_GESTATING";
    
    LEAVE process_user;
END IF;


IF cur_pig_prod_flag & FLAG_BIT_PIGLETS_ARE_EXTERNAL THEN 
    SET res_num     = RES_NUM_PIG_PROD_PIGLETS_ARE_EXTERNAL;
    SET res_code    = "RES_NUM_PIG_PROD_PIGLETS_ARE_EXTERNAL";
    SET res_desc    = "Cannot update insemination data if piglets are external.";
    
    LEAVE process_user;
END IF;


SELECT  date_actual_birth
INTO    cur_pig_prod_date_actual_birth
FROM    pig_production
WHERE   id = in_pig_prod_id;


IF cur_pig_prod_date_actual_birth IS NOT NULL THEN 

    SET res_num     = RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA;
    SET res_code    = "RES_NUM_CANNOT_UPDATE_INSEMINATION_DATA";
    SET res_desc    = "Cannot update insemination data after birth.";
    
    LEAVE process_user;

END IF;


UPDATE pig_production SET
    semen_cost          = in_semen_cost,
    insemination_cost   = in_insemination_cost,
    insem_cost_comments = in_insem_cost_comments,
    
    date_insemination   = in_date_insemination,
    date_expected_birth = DATE_ADD(in_date_insemination, INTERVAL 115 DAY),
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_id;

END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_pig_count $$
CREATE PROCEDURE pig_prod_update_pig_count(
    in_user_id              INT,
    in_pig_prod_id          INT,

    in_num_pigs             INT,
    in_date_notes           VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update current pigs count data for pig_production entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 27, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_PIG_PROD_CANNOT_UPDATE_PIG_COUNT INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 19;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  
        account_id,
        pig_farm_id,
        status_id

INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id

FROM    pig_production 
WHERE   id = in_pig_prod_id
LIMIT   1;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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


IF  cur_pig_prod_status_id NOT IN ( PRODUCTION_STATUS_ID_LACTATING,
                                    PRODUCTION_STATUS_ID_WEANING,
                                    PRODUCTION_STATUS_ID_GROWING) THEN 
    
    SET res_num     = RES_NUM_PIG_PROD_CANNOT_UPDATE_PIG_COUNT;
    SET res_code    = "RES_NUM_PIG_PROD_CANNOT_UPDATE_PIG_COUNT";
    SET res_desc    = "Production status not LACTATING, WEANING OR GROWING";
    
    LEAVE process_user;
END IF;


UPDATE pig_production SET
    num_pigs_current            = in_num_pigs,

    last_update_user_id         = in_user_id,
    dt_last_update              = CURRENT_TIMESTAMP
WHERE id = in_pig_prod_id;


IF in_notes IS NULL THEN 
    SET in_notes = "Updated pig count";
END IF;


INSERT INTO pig_prod_notes (
    account_id,
    pig_farm_id,
    pig_prod_id,
    
    notes,
    date_notes,
    added_by_user_id
    
) VALUES (
    cur_pig_prod_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    
    in_notes,
    in_date_notes,
    in_user_id
);


END process_user;


SELECT 

    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_prod_id;

    

END $$

DELIMITER ;DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_status $$
CREATE PROCEDURE pig_prod_update_status(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_pig_prod_status_id   INT
)

BEGIN

/** 
 * Will update pig_production entry.
 * 
 * Will manually update pig_production.prod_status_id
 *
 * Allowed status_ids: TERMINATED, NOT_PREGNANT, CLOSED
 *
 *
 * @author Jack Wong
 * @since September 12, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_INVALID_PIG_PROD_STATUS         INT             DEFAULT 20;
DECLARE RES_NUM_MANUAL_STATUS_UPDATE_NOT_ALLOWED INT            DEFAULT 21;
DECLARE RES_NUM_PIG_PROD_STATUS_NOT_GESTATING   INT             DEFAULT 22;

DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* pig_production.flag bits*/
DECLARE FLAG_BIT_PIGLETS_ARE_EXTERNAL           INT             DEFAULT 2;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;

DECLARE cur_pig_prod_date_actual_birth          DATE;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        prod_status_id,
        flag
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_status_id,
        cur_pig_prod_flag
FROM    pig_production
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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


IF  in_pig_prod_status_id <= 0 OR 
    in_pig_prod_status_id > PRODUCTION_STATUS_ID_CLOSED THEN
    
    SET res_num     = RES_NUM_INVALID_PIG_PROD_STATUS;
    SET res_code    = "RES_NUM_INVALID_PIG_PROD_STATUS";
    
    LEAVE process_user;
END IF;


IF in_pig_prod_status_id NOT IN (PRODUCTION_STATUS_ID_TERMINATED, 
                                PRODUCTION_STATUS_ID_NOT_PREGNANT, 
                                PRODUCTION_STATUS_ID_CLOSED) THEN
    
    SET res_num     = RES_NUM_MANUAL_STATUS_UPDATE_NOT_ALLOWED;
    SET res_code    = "RES_NUM_MANUAL_STATUS_UPDATE_NOT_ALLOWED";
    
    LEAVE process_user;
END IF;

IF in_pig_prod_status_id IN (PRODUCTION_STATUS_ID_TERMINATED, 
                            PRODUCTION_STATUS_ID_NOT_PREGNANT) THEN 
    IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
        SET res_num     = RES_NUM_PIG_PROD_STATUS_NOT_GESTATING;
        SET res_code    = "RES_NUM_PIG_PROD_STATUS_NOT_GESTATING";
        
        LEAVE process_user;
    END IF;
END IF;


UPDATE pig_production SET
    prod_status_id              = in_pig_prod_status_id,
    
    last_update_user_id         = in_user_id,
    dt_last_update              = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_id;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_production_id;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_update_weaning $$
CREATE PROCEDURE pig_prod_update_weaning(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_date_weaning         VARCHAR(10),
    
    in_num_pigs_female      INT,
    in_num_pigs_male        INT,
    
    in_total_weight         INT
)  

BEGIN

/** 
 * Will update weaning data for pig_production entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 27, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_STATUS_NOT_LACTATING   INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;



DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        prod_status_id,
        flag
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        cur_pig_prod_flag
        
FROM    pig_production 
WHERE   id = in_pig_prod_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_LACTATING THEN 
    SET res_num     = RES_NUM_PIG_PROD_STATUS_NOT_LACTATING;
    SET res_code    = "RES_NUM_PIG_PROD_STATUS_NOT_LACTATING";
END IF;


UPDATE pig_production SET
    date_weaning                = in_date_weaning,
    prod_status_id              = PRODUCTION_STATUS_ID_WEANING,

    num_pigs_weaning_m          = in_num_pigs_male,
    num_pigs_weaning_f          = in_num_pigs_female,

    num_pigs_current            = in_num_pigs_male + in_num_pigs_female,
    
    total_pigs_weight_weaning   = in_total_weight,
    
    last_update_user_id         = in_user_id,
    dt_last_update              = CURRENT_TIMESTAMP
    
WHERE id = in_pig_prod_id;





END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_prod_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_notes_add $$
CREATE PROCEDURE pig_prod_notes_add(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_prod_group_id        INT,
    
    in_date_notes           VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will create pig_prod_notes entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    pig_production 
    WHERE   id = in_pig_prod_id
    LIMIT   1;

ELSE
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id
            
    FROM    production_group 
    WHERE   id = in_prod_group_id
    LIMIT   1;
END IF;

CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


INSERT INTO pig_prod_notes (
    account_id,
    pig_farm_id,
    pig_prod_id,
    prod_group_id,
    
    notes,
    date_notes,
    added_by_user_id
    
) VALUES (
    cur_pig_prod_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    in_prod_group_id,
    
    in_notes,
    in_date_notes,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_notes_id               AS pig_prod_notes_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_notes_delete $$
CREATE PROCEDURE pig_prod_notes_delete(
    in_user_id                  INT,
    
    in_pig_prod_notes_id        INT
)  

BEGIN

/** 
 * Will delete pig_prod_notes entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


/* pig_prod_notes.flag bits*/
DECLARE FLAG_BIT_PIG_PROD_NOTES_IS_DELETED    	INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_group_id                   INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_account_id           INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  pig_prod_id,
        pig_prod_group_id

INTO    cur_pig_prod_id,
        cur_pig_prod_group_id

FROM    pig_prod_notes 
WHERE   id = in_pig_prod_notes_id;



IF cur_pig_prod_id > 0 THEN 

    SELECT  
            account_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_status_id
            
    FROM    pig_production
    WHERE   id = in_pig_prod_notes_id
    LIMIT   1;

ELSE

    SELECT  
            account_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_status_id
            
    FROM    production_group
    WHERE   id = cur_pig_prod_group_id
    LIMIT   1;

END IF;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
    FLAG_BIT_OPERATION_DELETE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


UPDATE pig_prod_notes SET
    flag                = flag | FLAG_BIT_PIG_PROD_NOTES_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_pig_prod_notes_id;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_notes_id                AS pig_prod_notes_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_notes_update $$
CREATE PROCEDURE pig_prod_notes_update(
    in_user_id              INT,
   
    in_pig_prod_notes_id    INT,
    in_date_notes           VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_notes entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_group_id                   INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  pig_prod_id,
        pig_prod_group_id

INTO    cur_pig_prod_id,
        cur_pig_prod_group_id

FROM    pig_prod_notes 
WHERE   id = in_pig_prod_notes_id;
 

IF cur_pig_prod_id > 0 THEN 

    SELECT  
            account_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_status_id
            
    FROM    pig_production
    WHERE   id = in_pig_prod_notes_id
    LIMIT   1;

ELSE

    SELECT  
            account_id,
            prod_status_id
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_status_id
            
    FROM    production_group
    WHERE   id = cur_pig_prod_group_id
    LIMIT   1;

END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_NOTES,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


UPDATE pig_prod_notes SET
    date_notes          = in_date_notes,
    notes               = in_notes,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_pig_prod_notes_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_notes_id                AS pig_prod_notes_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_dead_add $$
CREATE PROCEDURE pig_prod_pig_dead_add(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_pig_prod_group_id    INT,
    
    in_date_dead            VARCHAR(10),
    in_dead_type_id         INT,
    in_num_pigs_dead        INT,
    in_comments             VARCHAR(160)
)  

BEGIN

/** 
 * Will create pig_prod_pig_dead entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 27, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD    INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;




DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_id                      INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_num_pigs_current           INT             DEFAULT 0;
DECLARE cur_pig_prod_date_weaning               DATE            DEFAULT NULL;

DECLARE cur_dead_at_stage                       INT             DEFAULT 0;

DECLARE cur_pig_prod_pig_dead_id                INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id,
            
            date_weaning,
            num_pigs_current
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id,
            
            cur_pig_prod_date_weaning,
            cur_pig_prod_num_pigs_current
            
    FROM    pig_production 
    WHERE   id = in_pig_prod_id
    LIMIT   1;

ELSE
    SELECT  
            account_id,
            pig_farm_id,
            prod_status_id,
            
            date_weaning,
            num_pigs_current
    INTO    
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            cur_pig_prod_status_id,
            
            cur_pig_prod_date_weaning,
            cur_pig_prod_num_pigs_current
            
    FROM    production_group 
    WHERE   id = in_pig_prod_group_id
    LIMIT   1;


END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


IF  cur_pig_prod_status_id < PRODUCTION_STATUS_ID_LACTATING THEN 
    
    SET res_num     = RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD;
    SET res_code    = "RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD";
    SET res_desc    = "No pigs yet";
    
    LEAVE process_user;
END IF;


IF cur_pig_prod_date_weaning IS NULL THEN 
    SET cur_dead_at_stage = DEAD_AT_STAGE_LACTATING;
ELSE
    SET cur_dead_at_stage = DEAD_AT_STAGE_GROWING;
END IF;




INSERT INTO pig_prod_pig_dead (
    account_id,
    pig_farm_id,
    pig_prod_id,
    
    date_dead,
    dead_type_id,
    dead_at_stage,
    num_pigs_dead,
    comments,
    
    added_by_user_id
    
) VALUES (
    cur_user_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    
    in_date_dead,
    in_dead_type_id,
    cur_dead_at_stage,
    in_num_pigs_dead,
    in_comments,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_pig_dead_id;


IF in_pig_prod_id > 0 THEN 
    IF cur_pig_prod_num_pigs_current >= in_num_pigs_dead THEN 
        UPDATE pig_production SET
            num_pigs_current = num_pigs_current - in_num_pigs_dead
        WHERE id = in_pig_prod_id;
    END IF;

ELSE
    IF cur_pig_prod_num_pigs_current >= in_num_pigs_dead THEN 
        UPDATE production_group SET
            num_pigs_current = num_pigs_current - in_num_pigs_dead
        WHERE id = in_pig_prod_group_id;
    END IF;

END IF;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_pig_dead_id            AS pig_prod_pig_dead_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_dead_update $$
CREATE PROCEDURE pig_prod_pig_dead_update(
    in_user_id                  INT,
    
    in_pig_prod_pig_dead_id     INT,
    
    in_date_dead                VARCHAR(10),
    in_dead_type_id             INT,

    in_comments                 VARCHAR(160)
    
)

BEGIN

/** 
 * Will update pig_prod_pig_dead entry.
 * @author Jack Wong
 * @since August 27, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD    INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;





DECLARE cur_pig_prod_pig_dead_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        a.account_id,
        b.prod_status_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_status_id
FROM    pig_prod_pig_dead a 
LEFT OUTER JOIN pig_production b ON a.account_id = b.id
WHERE   a.id = in_pig_prod_pig_dead_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


UPDATE pig_prod_pig_dead SET
    date_dead           = in_date_dead,
    dead_type_id        = in_dead_type_id,

    comments            = in_comments,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_prod_pig_dead_id;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_pig_dead_id             AS pig_prod_pig_dead_id;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_ops_add $$
CREATE PROCEDURE pig_prod_pig_ops_add(
    in_user_id              INT,
    
    in_account_id           INT,
    in_operation_type       INT,
    in_pig_prod_id          INT,
    in_date_reference       VARCHAR(10)
)  

BEGIN

/** 
 * A sub procedure to create pig_prod_pig_ops entries.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 30, 2025
 *
 */
 
DECLARE cur_account_pig_ops_id                  INT             DEFAULT 0;
DECLARE cur_account_pig_ops_num_days            INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_ops CURSOR FOR
    SELECT  id,
            num_days_since
    FROM    account_pig_ops
    WHERE   account_id = in_account_id      AND 
            operation_type = in_operation_type AND 
            (flag & 1) = 0
    ORDER BY num_days_since ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


    
SET l_last_row_fetched=0;
OPEN c_account_pig_ops;   
    

loop_here: LOOP
    FETCH c_account_pig_ops INTO 
        cur_account_pig_ops_id,
        cur_account_pig_ops_num_days;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    INSERT INTO pig_prod_pig_ops(
        pig_prod_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        in_pig_prod_id,
        cur_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(in_date_reference, INTERVAL cur_account_pig_ops_num_days DAY)
    );
    

END LOOP loop_here;
 
CLOSE c_account_pig_ops;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_ops_update $$
CREATE PROCEDURE pig_prod_pig_ops_update(
    in_user_id                  INT,
   
    in_pig_prod_pig_ops_id      INT,
    in_staff_id                 INT,
    in_date                     VARCHAR(10),
    in_notes                    VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_pig_ops entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 28, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_BE_UDPATED               INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GROWING              INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_ops_operation_type     INT             DEFAULT 0;

DECLARE cur_prod_pig_ops_id                     INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        b.account_id,
        a.pig_prod_id,
        a.operation_type,
        b.prod_status_id
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_id,
        cur_pig_prod_pig_ops_operation_type,
        cur_pig_prod_status_id
        
FROM    pig_prod_pig_ops a
LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id
WHERE   a.id = in_pig_prod_pig_ops_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;



IF cur_pig_prod_pig_ops_operation_type = PIG_OPERATION_TYPE_GESTATING THEN 
    IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_GESTATING THEN 
        SET res_num     = RES_NUM_CANNOT_BE_UDPATED;
        SET res_code    = "RES_NUM_CANNOT_BE_UDPATED";
        
        LEAVE process_user;
    END IF;
END IF;


UPDATE pig_prod_pig_ops SET
    date_actual         = in_date,
    notes               = in_notes,
    staff_id            = in_staff_id,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_pig_prod_pig_ops_id;


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_pig_ops_id              AS pig_prod_pig_ops_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_race_line_add $$
CREATE PROCEDURE pig_race_line_add(
    in_user_id              INT,

    in_pig_race_id          INT,
    
    in_name                 VARCHAR(50),
    in_description          VARCHAR(160)
)  

BEGIN

/** 
 * Will add pig_race_line entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_race_line_id                    INT             DEFAULT 0;
DECLARE cur_pig_race_line_flag                  INT             DEFAULT 0;
DECLARE cur_pig_race_line_name                  VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PIG_RACE_LINE,
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
INTO    cur_pig_race_line_id
FROM    pig_race_line
WHERE   account_id          = cur_user_account_id   AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_pig_race_line_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO pig_race_line(
    account_id,
    pig_race_id,
    
    name,
    description,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_pig_race_id,
    
    in_name,
    in_description,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_race_line_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_race_line_flag,
    cur_pig_race_line_name
FROM pig_race_line
WHERE id = cur_pig_race_line_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_race_line_id                AS pig_race_line_id,
    cur_pig_race_line_flag              AS pig_race_line_flag,
    cur_pig_race_line_name              AS pig_race_line_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_race_line_delete $$
CREATE PROCEDURE pig_race_line_delete(
    in_user_id                  INT,
    
    in_pig_race_line_id         INT
)  

BEGIN

/** 
 * Will delete pig_race_line entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";

/* pig_race_line.flag bits*/
DECLARE FLAG_BIT_PIG_RACE_LINE_IS_DELETED       INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_race_line_account_id            INT             DEFAULT 0;
DECLARE cur_pig_race_line_flag                  INT             DEFAULT 0;
DECLARE cur_pig_race_line_name                  VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_race_line_account_id
FROM    pig_race_line
WHERE   id = in_pig_race_line_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_race_line_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_RACE_LINE,
    FLAG_BIT_OPERATION_DELETE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



UPDATE pig_race_line SET
    flag                = flag | FLAG_BIT_PIG_RACE_LINE_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_pig_race_line_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_race_line_flag,
    cur_pig_race_line_name
FROM pig_race_line
WHERE id = in_pig_race_line_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_race_line_id                 AS pig_race_line_id,
    cur_pig_race_line_flag              AS pig_race_line_flag,
    cur_pig_race_line_name              AS pig_race_line_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS pig_race_line_update $$
CREATE PROCEDURE pig_race_line_update(
    in_user_id                  INT,
    
    in_pig_race_line_id         INT,
    in_pig_race_id              INT,
    
    in_name                     VARCHAR(50),
    in_description              VARCHAR(160)
    
)

BEGIN

/** 
 * Will update pig_race_line entry.
 * @author Jack Wong
 * @since August 23, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE AUDIT_ACTION_ADD                        VARCHAR(3)      DEFAULT "ADD";
DECLARE AUDIT_ACTION_UPDATE                     VARCHAR(3)      DEFAULT "UPD";
DECLARE AUDIT_ACTION_DELETE                     VARCHAR(3)      DEFAULT "DEL";


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_race_line_id                    INT             DEFAULT 0;
DECLARE cur_pig_race_line_account_id            INT             DEFAULT 0;
DECLARE cur_pig_race_line_flag                  INT             DEFAULT 0;
DECLARE cur_pig_race_line_name                  VARCHAR(50)     DEFAULT NULL;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_race_line_account_id
FROM    pig_race_line
WHERE   id = in_pig_race_line_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_race_line_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_RACE_LINE,
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


/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_race_line_id
FROM    pig_race_line
WHERE   id                  != in_pig_race_line_id  AND
        account_id          = cur_user_account_id   AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_pig_race_line_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



UPDATE pig_race_line SET
    pig_race_id         = in_pig_race_id,
    
    name                = in_name,
    description         = in_description,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_pig_race_line_id;

END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_race_line_flag,
    cur_pig_race_line_name
FROM pig_race_line
WHERE id = in_pig_race_line_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_race_line_id                 AS pig_race_line_id,
    cur_pig_race_line_flag              AS pig_race_line_flag,
    cur_pig_race_line_name              AS pig_race_line_name;
    


END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS production_group_create $$
CREATE PROCEDURE production_group_create(
    in_user_id              INT,

    in_pig_prod_id          INT,
    
    in_date_added           INT
)  

BEGIN

/** 
 * Will add production_group entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PRODUCTION_GROUP        INT             DEFAULT 29;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;
DECLARE PRODUCTION_STATUS_ID_CULLED             INT             DEFAULT 10;



DECLARE PRODUCTION_GRP_STATUS_ID_GROWING        INT             DEFAULT 1;
DECLARE PRODUCTION_GRP_STATUS_ID_HARVESTED      INT             DEFAULT 2;
DECLARE PRODUCTION_GRP_STATUS_ID_CLOSED         INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_farm_last_production_group_id   INT             DEFAULT 0;

DECLARE cur_production_group_id                 INT             DEFAULT 0;
DECLARE cur_production_group_flag               INT             DEFAULT 0;
DECLARE cur_production_group_name               VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PRODUCTION_GROUP,
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
SELECT  production_group_id
INTO    cur_production_group_id
FROM    pig_production
WHERE   id = in_pig_prod_id
LIMIT   1;


/* A pig_production entry can only be associated with one production_group*/
IF cur_production_group_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* Get the farm information of the in_pig_prod_id.*/
SELECT  a.pig_farm_id,
        b.last_production_group_id
INTO    cur_pig_prod_pig_farm_id,
        cur_pig_farm_last_production_group_id
FROM    pig_production a 
LEFT OUTER JOIN pig_farm b ON a.pig_farm_id = b.id
WHERE   a.id = in_pig_prod_id;



INSERT INTO production_group(
    account_id,
    pig_farm_id,
    farm_production_group_id,
    
    starting_pig_prod_id,
    added_by_user_id
) VALUES (
    cur_user_account_id,
    cur_pig_prod_pig_farm_id,
    cur_pig_farm_last_production_group_id,
    
    in_pig_prod_id,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_production_group_id;


UPDATE pig_production SET
    prod_status_id          = PRODUCTION_STATUS_ID_COMBINED,
    production_group_id     = cur_production_group_id,
    production_group_date   = in_date_added
WHERE id = in_pig_prod_id;

END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_production_group_id             AS production_group_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS production_harvest_add $$
CREATE PROCEDURE production_harvest_add(
    in_user_id              INT,
    in_pig_prod_id          INT,
    in_production_group_id  INT,
    in_acc_pig_buyer_id     INT,
    
    in_date_harvest         VARCHAR(10),
    
    in_num_pigs_harvest     INT,
    in_live_weight          INT,
    in_slaugther_weight     INT,
    
    in_sales                DECIMAL(8,1),
    in_harvest_cost         DECIMAL(5,1),
    in_cost_comments        VARCHAR(160)
)  

BEGIN

/** 
 * Will add pig_prod_harvest entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 4, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_HARVEST_ENTRY_NOT_ALLOWED       INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;
DECLARE cur_num_pigs_harvest                    INT             DEFAULT 0;
DECLARE cur_num_dead_pigs                       INT             DEFAULT 0;
DECLARE cur_num_pigs_current                    INT             DEFAULT 0;

DECLARE cur_pig_prod_harvest_id                 INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production 
    WHERE id = in_pig_prod_id;

ELSE
    SELECT 
        account_id,
        prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM production_group 
    WHERE id = in_pig_prod_group_id;

END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_HARVEST,
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
IF in_pig_prod_id > 0 THEN 
    SELECT  id
    INTO    cur_pig_prod_harvest_id
    FROM    pig_prod_harvest
    WHERE   pig_prod_id         = in_pig_prod_id    AND
            date_harvest        = in_date_harvest
    LIMIT   1;
    
ELSE
    SELECT  id
    INTO    cur_pig_prod_harvest_id
    FROM    pig_prod_harvest
    WHERE   pig_prod_group_id   = in_pig_prod_group_id    AND
            date_harvest        = in_date_harvest
    LIMIT   1;
    
END IF;

IF cur_pig_prod_harvest_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


IF in_pig_prod_id > 0 THEN 
    IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_WEANING, 
                                        PRODUCTION_STATUS_ID_GROWING) THEN
        SET res_num     = RES_NUM_HARVEST_ENTRY_NOT_ALLOWED;
        SET res_code    = "RES_NUM_HARVEST_ENTRY_NOT_ALLOWED";
        SET res_desc    = "Production status not WEANING or GROWING.";
    
        LEAVE process_user;
    
    END IF;
END IF;


INSERT INTO production_harvest(
    account_id,

    pig_prod_id,
    production_group_id,
    acc_pig_buyer_id,
    
    date_harvest,
    
    num_pigs_harvest,
    
    live_weight,
    slaugther_weight,
    
    sales,
    harvest_cost,
    cost_comments,

    added_by_user_id
    
) VALUES (
    cur_pig_prod_account_id,

    in_pig_prod_id,
    in_production_group_id,
    in_acc_pig_buyer_id,
    
    in_date_harvest,
    
    in_num_pigs,
    
    in_live_weight,
    in_slaugther_weight,
    
    in_sales,
    in_harvest_cost,
    in_cost_comments,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_harvest_id;


IF in_pig_prod_id > 0 THEN 
    SELECT  num_pigs_weaning_m + num_pigs_weaning_f
    INTO    cur_num_pigs_weaning
    FROM    pig_production 
    WHERE   id = in_pig_prod_id;
    
    
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    production_harvest
    WHERE   pig_prod_id = in_pig_prod_id;
    
    
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   pig_prod_id = in_pig_prod_id AND dead_at_stage = DEAD_AT_STAGE_GROWING;
    
    
    SET cur_num_pigs_current = cur_num_pigs_weaning - cur_num_pigs_harvest - cur_num_dead_pigs;
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    IF cur_num_pigs_current > 0 THEN 
        UPDATE  pig_production SET
            num_pigs_current = cur_num_pigs_current
        WHERE id = in_pig_prod_id;
    ELSE
        
        UPDATE  pig_production SET
            num_pigs_current = 0,
            pig_prod_status_id = PRODUCTION_STATUS_ID_HARVESTED
        WHERE id = in_pig_prod_id;
    END IF;

ELSE
    /*TODO for production_group*/
    
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    pig_prod_harvest
    WHERE   pig_prod_group_id = in_pig_prod_group_id;
    
    
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   pig_prod_group_id = in_pig_prod_group_id AND dead_at_stage = DEAD_AT_STAGE_GROWING;
    
END IF;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_harvest_id             AS pig_prod_harvest_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS production_harvest_update $$
CREATE PROCEDURE production_harvest_update(
    in_user_id              INT,
    
    in_production_harvest_id INT,
    
    in_date_harvest         VARCHAR(10),
    
    in_num_pigs_harvest     INT,
    in_live_weight          INT,
    in_slaugther_weight     INT,
    
    in_sales                DECIMAL(8,1),
    in_harvest_cost         DECIMAL(5,1),
    in_cost_comments        VARCHAR(160)
)  

BEGIN

/** 
 * Will update pig_prod_harvest entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 18, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;

DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;


DECLARE PRODUCTION_GRP_STATUS_ID_GROWING        INT             DEFAULT 1;
DECLARE PRODUCTION_GRP_STATUS_ID_HARVESTED      INT             DEFAULT 2;
DECLARE PRODUCTION_GRP_STATUS_ID_CLOSED         INT             DEFAULT 3;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_production_harvest_account_id       INT             DEFAULT 0;
DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_production_group_id                 INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;
DECLARE cur_num_pigs_harvest                    INT             DEFAULT 0;
DECLARE cur_num_dead_pigs                       INT             DEFAULT 0;
DECLARE cur_num_pigs_current                    INT             DEFAULT 0;

DECLARE cur_pig_prod_harvest_id                 INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT 
    account_id,
    pig_prod_id,
    production_group_id
INTO
    cur_production_harvest_account_id,
    cur_pig_prod_id,
    cur_production_group_id

FROM production_harvest 
WHERE id = in_production_harvest_id;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_production_harvest_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_HARVEST,
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


IF cur_pig_prod_id > 0 THEN 
    SELECT  prod_status_id
    INTO    cur_pig_prod_status_id
    FROM    pig_production
    WHERE   id = cur_pig_prod_id;
    
    IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
        SET res_num     = RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED;
        SET res_code    = "RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED";
        
        LEAVE process_user;
    END IF;
    
END IF;

IF cur_production_group_id > 0 THEN
    SELECT  prod_status_id
    INTO    cur_pig_prod_status_id
    FROM    production_status
    WHERE   id = cur_production_group_id;
    
    IF cur_pig_prod_status_id = PRODUCTION_GRP_STATUS_ID_CLOSED THEN 
        SET res_num     = RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED;
        SET res_code    = "RES_NUM_PRODUCTION_ENTRY_ALREADY_CLOSED";
        
        LEAVE process_user;
    END IF;

END IF;


UPDATE pig_prod_harvest SET
    date_harvest        = in_date_harvest,
    
    num_pigs_harvest    = in_num_pigs_harvest,
    
    live_weight         = in_live_weight,
    slaugther_weight    = in_slaugther_weight,
    
    sales               = in_sales,
    harvest_cost        = in_harvest_cost,
    cost_comments       = in_cost_comments,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_production_harvest_id;


IF cur_pig_prod_id > 0 THEN 
    SELECT  num_pigs_weaning_m + num_pigs_weaning_f
    INTO    cur_num_pigs_weaning
    FROM    pig_production 
    WHERE   id = cur_pig_prod_id;
    
    
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    production_harvest
    WHERE   pig_prod_id = cur_pig_prod_id;
    
    
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   pig_prod_id = cur_pig_prod_id AND dead_at_stage = DEAD_AT_STAGE_GROWING;
    
    
    SET cur_num_pigs_current = cur_num_pigs_weaning - cur_num_pigs_harvest - cur_num_dead_pigs;
    
    IF cur_num_pigs_current < 0 THEN
        /* Something is wrong*/
        SET cur_num_pigs_current = 0;
    END IF;
    

    IF cur_num_pigs_current > 0 THEN 
        UPDATE  pig_production SET
            num_pigs_current = cur_num_pigs_current
        WHERE id = cur_pig_prod_id;
    ELSE
        
        UPDATE  pig_production SET
            num_pigs_current = 0,
            pig_prod_status_id = PRODUCTION_STATUS_ID_HARVESTED
        WHERE id = cur_pig_prod_id;
    END IF;

ELSE
    /*TODO for production_group*/
    
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    pig_prod_harvest
    WHERE   pig_prod_group_id = in_pig_prod_group_id;
    
    
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   pig_prod_group_id = in_pig_prod_group_id AND dead_at_stage = DEAD_AT_STAGE_GROWING;
    
END IF;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_harvest_id             AS pig_prod_harvest_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS semen_source_add $$
CREATE PROCEDURE semen_source_add(
    in_user_id              INT,

    in_pig_farm_id          INT,
    
    in_boar_id              INT,
    
    in_semen_supplier_id    INT,
    in_pig_race_line_id     INT,    
    
    in_name                 VARCHAR(50),
    in_description          VARCHAR(160)
)  

BEGIN

/** 
 * Will add semen_source entry. This is a record for artificial insemination 
 * semen sources.
 *
 * Notes:
 * 1.) If the semen is coming from a boar in the farm (semen is extracted),
 *      in_boar_id should be filled up.
 *
 * 2.) If the semen is bought from a supplier, in_semen_supplier_id and 
 *      in_pig_race_line_id must be filled in.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


/* semen_source.flag bits*/
DECLARE FLAG_BIT_SEMEN_SOURCE_IS_DELETED        INT             DEFAULT 1;

DECLARE BUSINESS_OBJ_ID_SEMEN_SOURCE            INT             DEFAULT 20;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;

DECLARE cur_semen_source_id                     INT             DEFAULT 0;
DECLARE cur_semen_source_flag                   INT             DEFAULT 0;
DECLARE cur_semen_source_name                   VARCHAR(50)     DEFAULT '';



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_farm_account_id
FROM    pig_farm
WHERE   id = in_pig_farm_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id,
    
    BUSINESS_OBJ_ID_SEMEN_SOURCE,
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
IF in_boar_id > 0 THEN 
    SELECT  id
    INTO    cur_semen_source_id
    FROM    semen_source
    WHERE   account_id  = cur_user_account_id   AND 
            boar_id     = in_boar_id
    LIMIT   1;
    
ELSE
    SELECT  id
    INTO    cur_semen_source_id
    FROM    semen_source
    WHERE   account_id  = cur_user_account_id   AND 
            UPPER(name) = UPPER(in_name)
    LIMIT   1;

END IF;

IF cur_semen_source_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO semen_source(
    account_id,
    pig_farm_id,
    boar_id,
    
    semen_supplier_id,
    pig_race_line_id,
    
    added_by_user_id,
    
    name,
    description
    
) VALUES (
    cur_user_account_id,
    in_pig_farm_id,
    in_boar_id,
    
    in_semen_supplier_id,
    in_pig_race_line_id,
    
    in_user_id,
    
    in_name,
    in_description
);

SELECT LAST_INSERT_ID() INTO cur_semen_source_id;


/* Insert INTO account_selection*/
SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_pig_farm_account_id AND 
        semen_supplier_id = in_semen_supplier_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        semen_supplier_id
    ) VALUES (
        cur_pig_farm_account_id,
        in_semen_supplier_id
    );
END IF;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_source_flag,
    cur_semen_source_name
FROM semen_source
WHERE id = cur_semen_source_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_semen_source_id                 AS semen_source_id,
    cur_semen_source_flag               AS semen_source_flag,
    cur_semen_source_name               AS semen_source_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS semen_source_delete $$
CREATE PROCEDURE semen_source_delete(
    in_user_id              INT,
    
    in_semen_source_id      INT
)  

BEGIN

/** 
 * Will delete semen_source entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 18, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


/* semen_source.flag bits*/
DECLARE FLAG_BIT_SEMEN_SOURCE_IS_DELETED        INT             DEFAULT 1;

DECLARE BUSINESS_OBJ_ID_SEMEN_SOURCE            INT             DEFAULT 20;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_semen_source_id                     INT             DEFAULT 0;
DECLARE cur_semen_source_flag                   INT             DEFAULT 0;
DECLARE cur_semen_source_account_id             INT             DEFAULT 0;
DECLARE cur_semen_source_name                   VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_semen_source_account_id
FROM    semen_source
WHERE   id = in_semen_source_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_semen_source_account_id,/* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SEMEN_SOURCE,
    FLAG_BIT_OPERATION_DELETE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


UPDATE semen_source SET
    flag                = flag | FLAG_BIT_SEMEN_SOURCE_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_semen_source_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_source_flag,
    cur_semen_source_name
FROM semen_source
WHERE id = in_semen_source_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_semen_source_id                  AS semen_source_id,
    cur_semen_source_flag               AS semen_source_flag,
    cur_semen_source_name               AS semen_source_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS semen_source_update $$
CREATE PROCEDURE semen_source_update(
    in_user_id              INT,
    
    in_semen_source_id      INT,
    
    in_pig_farm_id          INT,
    in_boar_id              INT,
    
    in_semen_supplier_id    INT,
    in_pig_race_line_id     INT,
    
    
    in_name                 VARCHAR(50),
    in_description          VARCHAR(160)
    
)  

BEGIN

/** 
 * Will update semen_source entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 18, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_SEMEN_SOURCE            INT             DEFAULT 20;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_semen_source_id                     INT             DEFAULT 0;
DECLARE cur_semen_source_flag                   INT             DEFAULT 0;
DECLARE cur_semen_source_account_id             INT             DEFAULT 0;
DECLARE cur_semen_source_name                   VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_semen_source_account_id
FROM    semen_source
WHERE   id = in_semen_source_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_semen_source_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SEMEN_SOURCE,
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



/* Check for duplicate entry */
IF in_boar_id > 0 THEN 
    SELECT  id
    INTO    cur_semen_source_id
    FROM    semen_source
    WHERE   id          != in_semen_source_id   AND
            account_id  = cur_user_account_id   AND 
            boar_id     = in_boar_id
    LIMIT   1;
    
ELSE
    SELECT  id
    INTO    cur_semen_source_id
    FROM    semen_source
    WHERE   id          != in_semen_source_id   AND
            account_id  = cur_user_account_id   AND 
            UPPER(name) = UPPER(in_name)
    LIMIT   1;

END IF;

IF cur_semen_source_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


UPDATE semen_source SET
    pig_farm_id         = in_pig_farm_id,
    boar_id             = in_boar_id,
    
    semen_supplier_id   = in_semen_supplier_id,
    pig_race_line_id    = in_pig_race_line_id,
    
    name                = in_name,
    description         = in_description,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_semen_source_id;

END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_source_flag,
    cur_semen_source_name
FROM semen_source
WHERE id = in_semen_source_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_semen_source_id                  AS semen_source_id,
    cur_semen_source_flag               AS semen_source_flag,
    cur_semen_source_name               AS semen_source_name;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS semen_supplier_add $$
CREATE PROCEDURE semen_supplier_add(
    in_user_id              INT,

    in_country_id           INT,
    in_address_level_1_id   INT,
    in_address_level_2_id   INT,
    in_address_level_3_id   INT,
    
    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will add semen_supplier entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_SEMEN_SUPPLIER          INT             DEFAULT 13;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* semen_supplier.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_IS_DELETED      INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_semen_supplier_id                   INT             DEFAULT 0;
DECLARE cur_semen_supplier_flag                 INT             DEFAULT 0;
DECLARE cur_semen_supplier_name                 VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_SEMEN_SUPPLIER,
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
IF in_address_level_3_id IS NULL THEN  
    SELECT  id
    INTO    cur_semen_supplier_id
    FROM    semen_supplier
    WHERE   country_id          = in_country_id   AND
            address_level_1_id  = in_address_level_1_id   AND
            address_level_2_id  = in_address_level_2_id   AND
            UPPER(name)         = UPPER(in_name)
    LIMIT   1;
ELSE
    SELECT  id
    INTO    cur_semen_supplier_id
    FROM    semen_supplier
    WHERE   country_id          = in_country_id   AND
            address_level_1_id  = in_address_level_1_id   AND
            address_level_2_id  = in_address_level_2_id   AND
            address_level_3_id  = in_address_level_3_id   AND
            UPPER(name)         = UPPER(in_name)
    LIMIT   1;
END IF;

IF cur_semen_supplier_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO semen_supplier(
    country_id,
    address_level_1_id,
    address_level_2_id,
    address_level_3_id,
    
    name,
    contact_number,
    whatsapp,
    messenger,
    added_by_user_id
    
) VALUES (
   in_country_id,
   in_address_level_1_id,
   in_address_level_2_id,
   in_address_level_3_id,
   
   in_name,
   in_contact_number,
   in_whatsapp,
   in_messenger,
   
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_semen_supplier_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_supplier_flag,
    cur_semen_supplier_name
FROM semen_supplier
WHERE id = cur_semen_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_semen_supplier_id               AS semen_supplier_id,
    cur_semen_supplier_flag             AS semen_supplier_flag,
    cur_semen_supplier_name             AS semen_supplier_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS semen_supplier_update $$
CREATE PROCEDURE semen_supplier_update(
    in_user_id              INT,
    
    in_semen_supplier_id    INT, 

    in_name                 VARCHAR(50),
    in_contact_number       VARCHAR(20),
    in_whatsapp             VARCHAR(20),
    in_messenger            VARCHAR(50)
)  

BEGIN

/** 
 * Will update semen_supplier entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;

DECLARE RES_NUM_NOT_ALLOWED_TO_UPDATE           INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_SEMEN_SUPPLIER          INT             DEFAULT 13;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* semen_supplier.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_IS_DELETED      INT             DEFAULT 1;


/* user.flag bits*/
DECLARE FLAG_BIT_SYSTEM_SUPER_USER              INT             DEFAULT 131072;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_flag                           INT             DEFAULT 0;


DECLARE cur_added_by_user_id                    INT             DEFAULT 0;
DECLARE cur_user_orig_account_id                INT             DEFAULT 0;


DECLARE cur_semen_supplier_id                   INT             DEFAULT 0;
DECLARE cur_semen_supplier_flag                 INT             DEFAULT 0;
DECLARE cur_semen_supplier_name                 VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_SEMEN_SUPPLIER,
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


/* Get the account_id of the user who originally entered this entry. */
SELECT  added_by_user_id
INTO    cur_added_by_user_id
FROM    semen_supplier
WHERE   id = in_semen_supplier_id;

SELECT  account_id
INTO    cur_user_orig_account_id
FROM    user
WHERE   id = cur_added_by_user_id;


/* Get user flag*/
SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id = in_user_id;


/* Only users of the account who added this entry can update.
Or a SYSTEM_SUPER_USER.
*/
IF cur_user_orig_account_id != cur_user_account_id THEN 
    IF cur_user_flag & FLAG_BIT_SYSTEM_SUPER_USER = 0 THEN 
        SET res_num     = RES_NUM_NOT_ALLOWED_TO_UPDATE;
        SET res_code    = "RES_NUM_NOT_ALLOWED_TO_UPDATE";
        
        LEAVE process_user;
    END IF;
END IF;



UPDATE semen_supplier SET    
    name                = in_name,
    contact_number      = in_contact_number,
    whatsapp            = in_whatsapp,
    messenger           = in_messenger,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id = in_semen_supplier_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_supplier_flag,
    cur_semen_supplier_name
FROM semen_supplier
WHERE id = in_semen_supplier_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_semen_supplier_id               AS semen_supplier_id,
    cur_semen_supplier_flag             AS semen_supplier_flag,
    cur_semen_supplier_name             AS semen_supplier_name;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_add $$
CREATE PROCEDURE sow_boar_add(
    in_user_id              INT,
    
    in_pig_farm_id          INT,
    in_farm_birth_prod_id   INT,
    in_line_id              INT,
    in_sow_status_id        INT,
    
    in_sex                  CHAR(1),
    in_is_external          INT,
    
    in_number               VARCHAR(10),
    in_name                 VARCHAR(20),
    in_date_of_birth        VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will add sow_boar entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* sow_boar.flag bits*/
DECLARE FLAG_BIT_SOW_BOAR_IS_DISPOSED           INT             DEFAULT 1;
DECLARE FLAG_BIT_SOW_BOAR_IS_EXTERNAL           INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_last_sow_id                INT             DEFAULT 0;
DECLARE cur_pig_farm_last_boar_id               INT             DEFAULT 0;


DECLARE cur_sow_boar_id                         INT             DEFAULT 0;
DECLARE cur_sow_boar_flag                       INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        last_sow_id,
        last_boar_id
INTO    
        cur_pig_farm_account_id,
        cur_pig_farm_last_sow_id,
        cur_pig_farm_last_boar_id
FROM    pig_farm
WHERE   id = in_pig_farm_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SOW_BOAR,
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



/* Check for duplicate entry. */ 
IF in_number IS NOT NULL THEN 
    /* If sow_boar.number is given, will be check as one of unique keys. */

    SELECT  id
    INTO    cur_sow_boar_id
    FROM    sow_boar
    WHERE   account_id  = cur_user_account_id   AND
            pig_farm_id = in_pig_farm_id        AND
            sex         = in_sex                AND
            number      = in_number;

ELSE
    /* If sow_boar.name is given, will be check as one of unique keys. */
    
    SELECT  id
    INTO    cur_sow_boar_id
    FROM    sow_boar
    WHERE   account_id  = cur_user_account_id   AND
            pig_farm_id = in_pig_farm_id        AND
            sex         = in_sex                AND
            name        = in_name;

END IF;


IF cur_sow_boar_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


IF in_sex = 'F' THEN 
    SET cur_pig_farm_last_sow_id = cur_pig_farm_last_sow_id + 1;
    
    IF in_is_external > 0 THEN 
        SET cur_sow_boar_flag = FLAG_BIT_SOW_BOAR_IS_EXTERNAL;
    END IF;
    
    INSERT INTO sow_boar(
        account_id,
        pig_farm_id,
        farm_sow_id,
        
        farm_birth_prod_id,
        line_id,
        sow_status_id,
        flag,
        
        sex,
        
        number,
        name,
        date_of_birth,
        notes,
        
        added_by_user_id
    ) VALUES (
        cur_user_account_id,
        in_pig_farm_id,
        cur_pig_farm_last_sow_id,
        
        in_farm_birth_prod_id,
        in_line_id,
        in_sow_status_id,
        cur_sow_boar_flag,
        
        in_sex,
        
        in_number,
        in_name,
        in_date_of_birth,
        in_notes,
        
        in_user_id
    );


ELSE
    SET cur_pig_farm_last_boar_id = cur_pig_farm_last_boar_id + 1;
    
    INSERT INTO sow_boar(
        account_id,
        pig_farm_id,
        farm_boar_id,
        
        farm_birth_prod_id,
        line_id,
        sow_status_id,
        flag,
        
        sex,
        
        number,
        name,
        date_of_birth,
        notes,
        
        added_by_user_id
    ) VALUES (
        cur_user_account_id,
        in_pig_farm_id,
        cur_pig_farm_last_boar_id,
        
        in_farm_birth_prod_id,
        in_line_id,
        NULL,
        cur_sow_boar_flag,
        
        in_sex,
        
        in_number,
        in_name,
        in_date_of_birth,
        in_notes,
        
        in_user_id
    );
    
    
END IF;


SELECT LAST_INSERT_ID() INTO cur_sow_boar_id;

UPDATE pig_farm SET 
    last_sow_id     = cur_pig_farm_last_sow_id,
    last_boar_id    = cur_pig_farm_last_boar_id
WHERE id = in_pig_farm_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_sow_boar_id                     AS sow_boar_id,
    cur_pig_farm_last_sow_id            AS farm_sow_id,
    cur_pig_farm_last_boar_id           AS farm_boar_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_dispose $$
CREATE PROCEDURE sow_boar_dispose(
    in_user_id              INT,
    
    in_sow_boar_id          INT,
    in_dispose_status_id    INT,
    
    in_date_dispose         VARCHAR(10),
    in_dispose_notes        VARCHAR(160)
)  

BEGIN

/** 
 * Will dispose sow_boar entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 17, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE FLAG_BIT_SOW_BOAR_IS_DISPOSED           INT             DEFAULT 1;
DECLARE FLAG_BIT_SOW_BOAR_IS_EXTERNAL           INT             DEFAULT 2;


DECLARE SOW_STATUS_ID_CULLED                    INT             DEFAULT 5;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_sow_boar_account_id
FROM    sow_boar
WHERE   id = in_sow_boar_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SOW_BOAR,
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


UPDATE sow_boar SET
    date_dispose        = in_date_dispose,
    dispose_notes       = in_dispose_notes,
    sow_status_id       = in_dispose_status_id,
    flag                = flag | FLAG_BIT_SOW_BOAR_IS_DISPOSED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE 
    id = in_sow_boar_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_sow_boar_id                      AS sow_boar_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_update $$
CREATE PROCEDURE sow_boar_update(
    in_user_id              INT,
    
    in_sow_boar_id          INT,
    in_farm_birth_prod_id   INT,
    in_line_id              INT,
    in_sow_status_id        INT,
    in_is_external          INT,
    
    in_number               VARCHAR(10),
    in_name                 VARCHAR(20),
    in_date_of_birth        VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update sow_boar entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 16, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* sow_boar.flag bits*/
DECLARE FLAG_BIT_SOW_BOAR_IS_DISPOSED           INT             DEFAULT 1;
DECLARE FLAG_BIT_SOW_BOAR_IS_EXTERNAL           INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_sow_boar_id                         INT             DEFAULT 0;
DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_flag                       INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        flag
        
INTO    cur_sow_boar_account_id,
        cur_sow_boar_flag
        
FROM    sow_boar
WHERE   id = in_sow_boar_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SOW_BOAR,
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


/* clear flag bif first*/
SET cur_sow_boar_flag = cur_sow_boar_flag & ~FLAG_BIT_SOW_BOAR_IS_EXTERNAL;
IF in_is_external > 0 THEN
    /* then update*/
    SET cur_sow_boar_flag = cur_sow_boar_flag | FLAG_BIT_SOW_BOAR_IS_EXTERNAL;
END IF;


UPDATE sow_boar SET
    farm_birth_prod_id  = in_farm_birth_prod_id,
    line_id             = in_line_id,
    sow_status_id       = in_sow_status_id,
    flag                = cur_sow_boar_flag,
    
    number              = in_number,
    name                = in_name,
    date_of_birth       = in_date_of_birth,
    notes               = in_notes,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE 
    id = in_sow_boar_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_sow_boar_id                      AS sow_boar_id;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_balance_add $$
CREATE PROCEDURE sow_boar_balance_add(
    in_user_id              INT,
    in_pig_farm_id          INT,
    
    in_date_balance         VARCHAR(10),
    
    in_num_gestating        DECIMAL(5,1),
    in_num_finisher         DECIMAL(5,1)
)  

BEGIN

/** 
 * Will sow_boar_balance entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 7, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR_BALANCE       	INT             DEFAULT 28;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE FEED_TYPE_ID_GESTATING                  INT             DEFAULT 1;
DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;


DECLARE SOW_STATUS_ID_LACTATING                 INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_sows_total                          INT             DEFAULT 0;
DECLARE cur_boars_total                         INT             DEFAULT 0;
DECLARE cur_sows_lactating                      INT             DEFAULT 0;
DECLARE cur_sows_gestating                      INT             DEFAULT 0;



DECLARE cur_sow_boar_balance_id                INT             DEFAULT 0;


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
    
    BUSINESS_OBJ_ID_SOW_BOAR_BALANCE,
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
INTO    cur_sow_boar_balance_id
FROM    sow_boar_balance
WHERE   pig_farm_id         = in_pig_farm_id    AND
        date_balance        = in_date_balance
LIMIT   1;
    


IF cur_sow_boar_balance_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/*
sow_boar.flag bits
DECLARE FLAG_BIT_SOW_BOAR_IS_DISPOSED           INT             DEFAULT 1;
DECLARE FLAG_BIT_SOW_BOAR_IS_EXTERNAL           INT             DEFAULT 2;

*/

/* Snap shot sows and boars*/
SELECT  COUNT(*)
INTO    cur_sows_total 
FROM    sow_boar 
WHERE   pig_farm_id = in_pig_farm_id AND sex = 'F' AND (flag & 3) = 0;

SELECT  COUNT(*)
INTO    cur_boars_total 
FROM    sow_boar 
WHERE   pig_farm_id = in_pig_farm_id AND sex = 'M' AND (flag & 3) = 0;


SELECT  COUNT(*)
INTO    cur_sows_lactating 
FROM    sow_boar 
WHERE   pig_farm_id = in_pig_farm_id AND sex = 'F' AND (flag & 3) = 0 AND 
        sow_status_id = SOW_STATUS_ID_LACTATING;

SET cur_sows_gestating  = cur_sows_total - cur_sows_lactating;


INSERT INTO sow_boar_balance(
    pig_farm_id,
    
    date_balance,
    
    num_sows,
    num_boars,
    num_sows_lactating,
    num_sows_gestating,
    
    num_gestating,   
    num_finisher,

    added_by_user_id
) VALUES (
    in_pig_farm_id,
    
    in_date_balance,
    
    cur_sows_total,
    cur_boars_total,
    cur_sows_lactating,
    cur_sows_gestating,
    
    in_num_gestating,
    in_num_finisher,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_sow_boar_balance_id;



UPDATE pig_farm SET
    last_sow_boar_balance_id = cur_sow_boar_balance_id
WHERE id = in_pig_farm_id;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_sow_boar_balance_id             AS sow_boar_balance_id;

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_register $$
CREATE PROCEDURE user_register(
    in_name_last            VARCHAR(50),
    in_name_first           VARCHAR(50),
    
    in_email                VARCHAR(50)
)  

BEGIN

/** 
 * Will create user entry. This is usually used when a user registers from
 * a mobile app or web application. All parameter input cannot be null or empty.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 8, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 1;

DECLARE cur_user_id                             INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  id
INTO    cur_user_id
FROM    user
WHERE   UPPER(email)        = UPPER(in_email)
LIMIT   1;


process_user : BEGIN

IF cur_user_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;

END IF;


INSERT INTO user(
    name_last,
    name_first,
    email
) VALUES (
    in_name_last,
    in_name_first,
    in_email
);

SELECT LAST_INSERT_ID() INTO cur_user_id;

END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_user_id                         AS user_id,
    0                                   AS user_flag;
    

END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS user_verify_mfa_email $$
CREATE PROCEDURE user_verify_mfa_email(
    in_user_id                  INT,
    in_auth_code                INT
)

BEGIN

/** 
 * Will verify multi factor auth entry for user email.
 * @author Jack Wong
 * @since January 4, 2024
 *
 */


DECLARE RES_NUM_VERIFIED                        INT             DEFAULT 0;
DECLARE RES_NUM_EMAIL_ALREADY_VERIFIED          INT             DEFAULT 1;
DECLARE RES_NUM_MFA_INVALID_CODE                INT             DEFAULT 2;
DECLARE RES_NUM_MFA_EXPIRED                     INT             DEFAULT 3;


/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;




DECLARE cur_unix_timestamp                      BIGINT          DEFAULT 0;

DECLARE cur_mfa_id                              INT             DEFAULT 0;
DECLARE cur_mfa_auth_code                       INT             DEFAULT 0;
DECLARE cur_mfa_ts_expiry                       BIGINT          DEFAULT 0;

DECLARE cur_user_flag                           INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET cur_unix_timestamp      = UNIX_TIMESTAMP();

SELECT      
        flag,
        last_mfa_id_email_verify 
INTO    
        cur_user_flag,
        cur_mfa_id
FROM    user  
WHERE   id = in_user_id;


process_user : BEGIN

IF cur_user_flag & FLAG_BIT_USER_EMAIL_VERIFIED > 0 THEN 
    SET res_num     = RES_NUM_EMAIL_ALREADY_VERIFIED;
    SET res_code    = "RES_NUM_EMAIL_ALREADY_VERIFIED";
    
    LEAVE process_user;
END IF;

IF cur_mfa_id > 0 THEN 
    SELECT 
        auth_code,
        ts_expiry
    INTO 
        cur_mfa_auth_code,
        cur_mfa_ts_expiry
    FROM app_mfa
    WHERE id = cur_mfa_id;
            
    IF cur_mfa_auth_code = in_auth_code THEN 
        IF cur_unix_timestamp > cur_mfa_ts_expiry THEN 
            SET res_num      = RES_NUM_MFA_EXPIRED;
            SET res_code     = 'RES_NUM_MFA_EXPIRED';
        ELSE
            SET res_num      = RES_NUM_VERIFIED;
            SET res_code     = 'RES_NUM_VERIFIED';
            
            /* Update MFA*/
            UPDATE app_mfa SET
                dt_verified         = CURRENT_TIMESTAMP
            WHERE id = cur_mfa_id;
            
            /* Update user*/
            UPDATE user SET
                flag   = flag | FLAG_BIT_USER_EMAIL_VERIFIED | FLAG_BIT_USER_IS_ACTIVE
            WHERE id = in_user_id;
            
        END IF;
    ELSE
        SET res_num      = RES_NUM_MFA_INVALID_CODE;
        SET res_code     = 'RES_NUM_MFA_INVALID_CODE';
    END IF;
    
    
END IF;

END process_user;


SELECT  flag
INTO    cur_user_flag
FROM    user
WHERE   id = in_user_id;
    

SELECT  
    res_num                     AS result_num,
    res_code                    AS result_code,
    res_desc                    AS result_desc,
    
    in_user_id                  AS user_id,
    cur_user_flag               AS user_flag;

END $$

DELIMITER ;
