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


/* These are the tables that are editable by users and need access restrictions; */

/* This is read from a02_business_object table. 

Business object with ids between 1 to 32 will have the access flags to be saved 
in user_group.flag_business_obj_1ect_1;

Business object with ids between 33 to 64 will have the access flags to be saved 
in user_group.flag_business_obj_1ect_1;




*/
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

DECLARE BUSINESS_OBJ_ID_PIG_DEAD_TYPE           INT             DEFAULT 28;
DECLARE BUSINESS_OBJ_ID_RESERVED_1              INT             DEFAULT 29;

DECLARE BUSINESS_OBJ_ID_SOW_BOAR_BALANCE        INT             DEFAULT 30;
DECLARE BUSINESS_OBJ_ID_RESERVED_2              INT             DEFAULT 31;
DECLARE BUSINESS_OBJ_ID_PIG_PEN                 INT             DEFAULT 32;

DECLARE BUSINESS_OBJ_ID_PRODUCTION_GROUP        INT             DEFAULT 33;




/* Admin users can access all business objects, 2^32 -1 or 0xFFFF FFFF*/
DECLARE FLAG_BUSINESS_OBJ_ADMIN                 BIGINT          DEFAULT 4294967295;
DECLARE FLAG_BUSINESS_OBJ_MANAGEMENT_1          BIGINT          DEFAULT 0;
DECLARE FLAG_BUSINESS_OBJ_OPERATIONS_1          BIGINT          DEFAULT 0;

DECLARE FLAG_BUSINESS_OBJ_MANAGEMENT_2          BIGINT          DEFAULT 0;
DECLARE FLAG_BUSINESS_OBJ_OPERATIONS_2          BIGINT          DEFAULT 0;




DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE OPERATION_ADD_UPDATE_DELETE             INT             DEFAULT 7;
DECLARE OPERATION_ADD_UPDATE_ONLY               INT             DEFAULT 3;




SELECT SUM(a.flag_val)
INTO FLAG_BUSINESS_OBJ_MANAGEMENT_1
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
INTO FLAG_BUSINESS_OBJ_MANAGEMENT_2
FROM (
    SELECT  POWER(2, bit_num) AS flag_val
    FROM    a02_business_object
    WHERE   id IN ( BUSINESS_OBJ_ID_PRODUCTION_GROUP
                    
                )
    ) a;


IF FLAG_BUSINESS_OBJ_MANAGEMENT_2 IS NULL THEN 
    SET FLAG_BUSINESS_OBJ_MANAGEMENT_2 = 0;
END IF;


    
    
SELECT SUM(a.flag_val)
INTO FLAG_BUSINESS_OBJ_OPERATIONS_1
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


SELECT SUM(a.flag_val)
INTO FLAG_BUSINESS_OBJ_OPERATIONS_2
FROM (
    SELECT  POWER(2, bit_num) AS flag_val
    FROM    a02_business_object
    WHERE   id IN ( BUSINESS_OBJ_ID_PRODUCTION_GROUP
                )
    ) a;

IF FLAG_BUSINESS_OBJ_OPERATIONS_2 IS NULL THEN 
    SET FLAG_BUSINESS_OBJ_OPERATIONS_2 = 0;
END IF;




/* Create account default user_groups. Each account will have a fix 
number of user groups*/
INSERT INTO user_group(
    account_id,
    group_num,
    flag_business_obj_1,
    flag_business_obj_2,
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
    flag_business_obj_1,
    flag_business_obj_2,
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
    FLAG_BUSINESS_OBJ_MANAGEMENT_1,
    FLAG_BUSINESS_OBJ_MANAGEMENT_2,
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
    flag_business_obj_1,
    flag_business_obj_2,
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
    FLAG_BUSINESS_OBJ_OPERATIONS_1,
    FLAG_BUSINESS_OBJ_OPERATIONS_2,
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
