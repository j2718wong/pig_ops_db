DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_dead_add $$
CREATE PROCEDURE pig_prod_pig_dead_add(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_date_dead            VARCHAR(10),
    in_dead_type_id         INT,
    in_sex                  VARCHAR(2),
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
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 10;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;




DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_id                      INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_num_pigs_current_m         INT             DEFAULT 0;
DECLARE cur_pig_prod_num_pigs_current_f         INT             DEFAULT 0;

DECLARE cur_pig_prod_pig_dead_id                INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        prod_status_id,
        
        num_pigs_current_m,
        num_pigs_current_f
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        
        cur_pig_prod_num_pigs_current_m,
        cur_pig_prod_num_pigs_current_f
        
FROM    pig_production 
WHERE   id = in_pig_prod_id
LIMIT   1;


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


IF  cur_pig_prod_status_id < PRODUCTION_STATUS_ID_LACTATING OR 
    cur_pig_prod_status_id = PRODUCTION_STATUS_ID_HARVESTED THEN 
    
    SET res_num     = RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD;
    SET res_code    = "RES_NUM_PIG_PROD_CANNOT_ADD_PIG_DEAD";
    SET res_desc    = "No pigs yet or already harvested";
    
    LEAVE process_user;
END IF;


INSERT INTO pig_prod_pig_dead (
    account_id,
    pig_farm_id,
    pig_prod_id,
    
    date_dead,
    dead_type_id,
    sex,
    comments,
    
    added_by_user_id
    
) VALUES (
    cur_user_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    
    in_date_dead,
    in_dead_type_id,
    in_sex,
    in_comments,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_pig_dead_id;

IF in_sex = 'F' THEN
    IF cur_pig_prod_num_pigs_current_f > 0 THEN 
        UPDATE pig_production SET
            num_pigs_current_f = num_pigs_current_f -1
        WHERE id = in_pig_prod_id;
    END IF;

ELSE 
    
    IF cur_pig_prod_num_pigs_current_m > 0 THEN 
        UPDATE pig_production SET
            num_pigs_current_m = num_pigs_current_m -1
        WHERE id = in_pig_prod_id;
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
