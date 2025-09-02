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


DECLARE RES_NUM_USER_GROUP_HAS_NO_ACCESS        INT             DEFAULT 9;
 

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



/* This is read from a02_business_object table. */
DECLARE BUSINESS_OBJ_ID_USER                    INT             DEFAULT 1;
DECLARE BUSINESS_OBJ_ID_ACCOUNT                 INT             DEFAULT 2;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_REQUEST         INT             DEFAULT 3;
DECLARE BUSINESS_OBJ_ID_USER_GROUP              INT             DEFAULT 4;

DECLARE BUSINESS_OBJ_ID_ACCOUNT_TRANSLATION     INT             DEFAULT 5;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_BILLING         INT             DEFAULT 6;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_RESERVE         INT             DEFAULT 7;
DECLARE BUSINESS_OBJ_ID_ACCOUNT_PIG_OPS         INT             DEFAULT 8;


DECLARE BUSINESS_OBJ_ID_PIG_FARM                INT             DEFAULT 9;
DECLARE BUSINESS_OBJ_ID_PIG_FARM_STAFF          INT             DEFAULT 10;
DECLARE BUSINESS_OBJ_ID_PIG_RACE                INT             DEFAULT 11;
DECLARE BUSINESS_OBJ_ID_PIG_RACE_LINE           INT             DEFAULT 12;


DECLARE BUSINESS_OBJ_ID_SEMEN_SUPPLIER          INT             DEFAULT 13;
DECLARE BUSINESS_OBJ_ID_FEED_SUPPLIER           INT             DEFAULT 14;
DECLARE BUSINESS_OBJ_ID_FEED_BRAND              INT             DEFAULT 15;
DECLARE BUSINESS_OBJ_ID_FEED_TYPE               INT             DEFAULT 16;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 17;
DECLARE BUSINESS_OBJ_ID_SEMEN_SOURCE            INT             DEFAULT 18;
DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 19;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_AI             INT             DEFAULT 20;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_FEED_BUY       INT             DEFAULT 21;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_FEED_BAL       INT             DEFAULT 22;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS        INT             DEFAULT 23;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD       INT             DEFAULT 24;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_NOTES          INT             DEFAULT 25;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_HARVEST        INT             DEFAULT 26;

DECLARE BUSINESS_OBJ_ID_PIG_PROD_RESERVED_1     INT             DEFAULT 27;
DECLARE BUSINESS_OBJ_ID_PIG_PROD_RESERVED_2     INT             DEFAULT 28;

DECLARE BUSINESS_OBJ_ID_PRODUCTION_GROUP        INT             DEFAULT 29;


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;




DECLARE cur_user_flag                           INT             DEFAULT 0;

DECLARE cur_biz_obj_flag_bit_num                INT             DEFAULT 0;

DECLARE cur_user_grp_flag_business_obj          INT             DEFAULT 0;
        
DECLARE cur_user_grp_flag_priv_user             INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_account          INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_request      INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_user_group       INT             DEFAULT 0;


DECLARE cur_user_grp_flag_priv_acc_translation  INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_billing      INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_reserve     	INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_acc_pig_ops      INT             DEFAULT 0;


DECLARE cur_user_grp_flag_priv_pig_farm         INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_farm_staff   INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_race         INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_race_line    INT             DEFAULT 0;




DECLARE cur_user_grp_flag_priv_semen_supplier   INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_feed_supplier    INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_feed_brand       INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_feed_type        INT             DEFAULT 0;



DECLARE cur_user_grp_flag_priv_sow_boar         INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_semen_source     INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_production   INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_ai      INT             DEFAULT 0;

DECLARE cur_user_grp_flag_priv_pig_prod_feed_buy INT            DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_feed_bal INT            DEFAULT 0;

DECLARE cur_user_grp_flag_priv_pig_prod_pig_ops INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_pig_dead INT            DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_harvest INT             DEFAULT 0;
DECLARE cur_user_grp_flag_priv_pig_prod_notes   INT             DEFAULT 0;


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
    b.flag_priv_acc_reserve,
    b.flag_priv_acc_pig_ops,
    
    b.flag_priv_pig_farm,
    b.flag_priv_pig_farm_staff,
    b.flag_priv_pig_race,
    b.flag_priv_pig_race_line,
    
    b.flag_priv_semen_supplier,
    b.flag_priv_feed_supplier,
    b.flag_priv_feed_brand,
    b.flag_priv_feed_type,
    
    b.flag_priv_sow_boar,
    b.flag_priv_semen_source,
    b.flag_priv_pig_production,
    b.flag_priv_pig_prod_ai,
    
    b.flag_priv_pig_prod_feed_buy,
    b.flag_priv_pig_prod_feed_bal,
    
    b.flag_priv_pig_prod_pig_ops,
    b.flag_priv_pig_prod_pig_dead,
    b.flag_priv_pig_prod_harvest,
    b.flag_priv_pig_prod_notes

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
    cur_user_grp_flag_priv_acc_reserve,
    cur_user_grp_flag_priv_acc_pig_ops,
    
    cur_user_grp_flag_priv_pig_farm,
    cur_user_grp_flag_priv_pig_farm_staff,
    cur_user_grp_flag_priv_pig_race,
    cur_user_grp_flag_priv_pig_race_line,
    
    
    cur_user_grp_flag_priv_semen_supplier,
    cur_user_grp_flag_priv_feed_supplier,
    cur_user_grp_flag_priv_feed_brand,
    cur_user_grp_flag_priv_feed_type,
    
    cur_user_grp_flag_priv_sow_boar,
    cur_user_grp_flag_priv_semen_source,
    cur_user_grp_flag_priv_pig_production,
    cur_user_grp_flag_priv_pig_prod_ai,
    
    cur_user_grp_flag_priv_pig_prod_feed_buy,
    cur_user_grp_flag_priv_pig_prod_feed_bal,
    
    cur_user_grp_flag_priv_pig_prod_pig_ops,
    cur_user_grp_flag_priv_pig_prod_pig_dead,
    cur_user_grp_flag_priv_pig_prod_harvest,
    cur_user_grp_flag_priv_pig_prod_notes
    
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
        

WHEN BUSINESS_OBJ_ID_SOW_BOAR THEN
    SET cur_group_flag = cur_user_grp_flag_priv_sow_boar;
        
WHEN BUSINESS_OBJ_ID_SEMEN_SOURCE THEN
    SET cur_group_flag = cur_user_grp_flag_priv_semen_source;
    
WHEN BUSINESS_OBJ_ID_PIG_PRODUCTION THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_production;
              
WHEN BUSINESS_OBJ_ID_PIG_PROD_AI THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_ai;

          
WHEN BUSINESS_OBJ_ID_PIG_PROD_FEED_BUY THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_feed_buy;
        
WHEN BUSINESS_OBJ_ID_PIG_PROD_FEED_BAL THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_feed_bal;
           
    
WHEN BUSINESS_OBJ_ID_PIG_PROD_PIG_OPS THEN
    SET cur_group_flag = cur_user_grp_flag_priv_prod_gestating_ops;
        
    
    
WHEN BUSINESS_OBJ_ID_PIG_PROD_PIG_DEAD THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_pig_dead;
        
WHEN BUSINESS_OBJ_ID_PROD_PIG_HARVEST THEN
    SET cur_group_flag = flag_priv_pig_prod_harvest;
    

WHEN BUSINESS_OBJ_ID_PIG_PROD_NOTES THEN
    SET cur_group_flag = cur_user_grp_flag_priv_pig_prod_notes;


END CASE;


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





END process_user;





END $$

DELIMITER ;
