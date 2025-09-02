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


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 19;



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


IF cur_pig_prod_status_id != PRODUCTION_STATUS_ID_LACTATING THEN 
    SET res_num     = RES_NUM_PIG_PROD_STATUS_NOT_LACTATING ;
    SET res_code    = "RES_NUM_PIG_PROD_STATUS_NOT_LACTATING";
END IF;


UPDATE pig_production SET
    date_weaning                = in_date_weaning,
    prod_status_id              = PRODUCTION_STATUS_ID_WEANING,

    num_pigs_weaning_m          = in_num_pigs_male,
    num_pigs_weaning_f          = in_num_pigs_female,

    num_pigs_current_m          = in_num_pigs_male, 
    num_pigs_current_f          = in_num_pigs_female,
    
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
