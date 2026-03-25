DELIMITER $$

DROP PROCEDURE IF EXISTS basic_user_check $$
CREATE PROCEDURE basic_user_check(
    in_user_id                  INT,
    in_user_must_have_account   INT,
    in_compare_to_account_id    INT,
    
    in_business_obj_id_to_access INT, /* 2026-03-25; this is ignored now; Dont delete; */
    in_business_obj_operation   INT,  /* 2026-03-25; this is ignored now; Dont delete; This must be a FLAG_BIT_OPERATION value*/
    
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



DECLARE cur_user_flag                           INT             DEFAULT 0;
DECLARE cur_user_is_system_super_user           INT             DEFAULT 0;


DECLARE cur_account_flag                        INT             DEFAULT 0;
DECLARE cur_account_status_id                   INT             DEFAULT 0;


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
    flag,
    account_id,
    user_group_id
    
INTO    
    cur_user_flag,
    out_user_account_id,
    out_user_group_id
FROM  user  
WHERE   id = in_user_id;



process_user : BEGIN

/* Check user*/
IF cur_user_flag & FLAG_BIT_USER_IS_ACTIVE = 0 THEN 
    SET res_num     = RES_NUM_USER_IS_INACTIVE;
    SET res_code    = "RES_NUM_USER_IS_INACTIVE";

    LEAVE process_user;    
END IF;


/**
2026-03-15; email verification check is disabled; since the system
allows now for users without email via access_code. 

Need to improve only if a user database operation needs an email. 

IF cur_user_flag & FLAG_BIT_USER_EMAIL_VERIFIED = 0 THEN 
    SET res_num     = RES_NUM_USER_NOT_EMAIL_VERIFIED;
    SET res_code    = "RES_NUM_USER_NOT_EMAIL_VERIFIED";

    LEAVE process_user;
END IF;
*/

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


    
END IF;



END process_user;





END $$

DELIMITER ;
