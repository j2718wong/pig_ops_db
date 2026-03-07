DELIMITER $$

DROP PROCEDURE IF EXISTS user_request_join_account_approve $$
CREATE PROCEDURE user_request_join_account_approve(
    in_approving_user_id        INT,
    
    in_user_request_id          INT,
    in_user_group_num           INT,
    
    in_is_approved              INT,
    
    in_pig_farm_id              INT
    
)

BEGIN

/** 
 * Will approve user_request to join user to account; 
 * This is initiated by the account admin user.
 * @author Jack Wong
 * @since August 11, 2025
 *
 */
 
DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;




DECLARE RES_NUM_USER_REQUEST_ALREADY_APPROVED   INT             DEFAULT 20;



DECLARE BUSINESS_OBJ_ID_USER                    INT             DEFAULT 1;




DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;



DECLARE USER_REQUEST_STATUS_ID_PENDING          INT             DEFAULT 1;
DECLARE USER_REQUEST_STATUS_ID_APPROVED         INT             DEFAULT 2;
DECLARE USER_REQUEST_STATUS_ID_REJECTED         INT             DEFAULT 3;





DECLARE cur_user_req_status_id                   INT             DEFAULT 0;
DECLARE cur_user_req_account_id                  INT             DEFAULT 0;
DECLARE cur_user_req_requesting_user_id          INT             DEFAULT 0;
DECLARE cur_user_req_dt_approved                 DATETIME        DEFAULT NULL;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;

DECLARE cur_approving_user_email                VARCHAR(100)    DEFAULT NULL;
DECLARE cur_approving_user_name_last            VARCHAR(50)     DEFAULT NULL;
DECLARE cur_approving_user_name_first           VARCHAR(50)     DEFAULT NULL;




DECLARE cur_requesting_user_email               VARCHAR(100)     DEFAULT NULL;


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
        cur_user_req_status_id,
        cur_user_req_account_id,
        cur_user_req_requesting_user_id
        
FROM    user_request
WHERE   id = in_user_request_id;


CALL basic_user_check(
    in_approving_user_id, 
    1, 
    cur_user_req_account_id,
    
    BUSINESS_OBJ_ID_USER,
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


IF cur_user_req_status_id = USER_REQUEST_STATUS_ID_APPROVED THEN
    SET res_num     = RES_NUM_USER_REQUEST_ALREADY_APPROVED;
    SET res_code    = "RES_NUM_USER_REQUEST_ALREADY_APPROVED";

    LEAVE process_user;
END IF;

IF in_is_approved > 0 THEN
    SET cur_user_req_status_id = USER_REQUEST_STATUS_ID_APPROVED;
ELSE
    SET cur_user_req_status_id = USER_REQUEST_STATUS_ID_REJECTED;
END IF;
 
UPDATE user_request SET
    status_id           = cur_user_req_status_id,
    approved_by_user_id = in_approving_user_id,
    dt_approved         = CURRENT_TIMESTAMP
WHERE id = in_user_request_id;



IF in_is_approved > 0 THEN 
    SELECT  id
    INTO    cur_user_group_id
    FROM    user_group
    WHERE   account_id = cur_user_req_account_id AND 
            group_num = in_user_group_num;


    /* Update approved user. */
    UPDATE user SET
        account_id          = cur_user_req_account_id,
        user_group_id       = cur_user_group_id,
        user_req_join_acc_id= NULL
    WHERE id = cur_user_req_requesting_user_id;


    IF in_pig_farm_id > 0 THEN 
        SET cur_count = 0;

        SELECT  COUNT(*)
        INTO    cur_count
        FROM    user_pig_farm
        WHERE   pig_farm_id = in_pig_farm_id AND user_id = cur_user_req_requesting_user_id;
        
        
        IF cur_count = 0 THEN 

            INSERT INTO user_pig_farm(
                pig_farm_id,
                user_id,
                added_by_user_id
            ) VALUES (
                in_pig_farm_id,
                cur_user_req_requesting_user_id,
                in_approving_user_id
            );
        END IF;


        
    ELSE
        /* Add all account pig farms to cur_user_req_requesting_user_id */
        CALL user_request_add_farms_to_user(
            cur_user_req_account_id,
            cur_user_req_requesting_user_id,
            in_approving_user_id
        );
    END IF;
    

END IF;



SELECT  email 
INTO    cur_requesting_user_email
FROM user
WHERE   id = cur_user_req_requesting_user_id;


END process_user;


SELECT  
        a.status_id,

        c.email,
        c.name_last,
        c.name_first,
        a.dt_approved
INTO    
        cur_user_req_status_id,

        cur_approving_user_email,
        cur_approving_user_name_last,
        cur_approving_user_name_first,
        cur_user_req_dt_approved
        
FROM    user_request a 
LEFT OUTER JOIN user c ON a.approved_by_user_id = c.id
WHERE   a.id = in_user_request_id;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_user_request_id                  AS user_req_id,
    cur_user_req_status_id              AS user_req_status_id,
    
    cur_approving_user_email            AS approving_user_email, 
    cur_approving_user_name_last        AS approving_user_name_last,
    cur_approving_user_name_first       AS approving_user_name_first,
    cur_user_req_dt_approved            AS acc_req_dt_approved,
    
    cur_user_req_requesting_user_id     AS requesting_user_id,
    cur_requesting_user_email           AS requesting_user_email;


END $$

DELIMITER ;
