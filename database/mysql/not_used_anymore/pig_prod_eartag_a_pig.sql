DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_eartag_a_pig $$
CREATE PROCEDURE pig_prod_eartag_a_pig(
    in_user_id              INT,
   
    in_pig_prod_id          INT,
    in_sex                  CHAR(1),
    
    in_number               VARCHAR(10),
    in_date_eartag          VARCHAR(10)
    
)  

BEGIN

/** 
 * Will eartag a pig in production. Will assume that the eartagged pig will
 * be either be made into a Gilt or a Boar.
 * 
 * Notes: 
 * 1.) This is not the same action as eartagging an already recorded sow or 
 * newly bought gilts and putting eartags on them. This is eartagging a pig 
 * that has a pig_prod_id so that the sow_boar.birth_pig_prod_id and other 
 * birth details can be populated.
 * 
 * 2.) Eartagged pigs are listed as gilts if female and boar if male.
 * If female it should automatically create scheduled gilt ops.  
 *
 * 3.) The eartagged pigs are not treated as pig_harvest and the pig_count
 * in the production stays the same.       
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since January 19, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_PIG_PROD_STATUS_CANNOT_EARTAG   INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;



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


DECLARE SOW_STATUS_ID_WEANING                   INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_flag                       INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;


DECLARE cur_pig_farm_last_sow_id                INT             DEFAULT 0;
DECLARE cur_pig_farm_last_boar_id               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        pig_farm_id,
        prod_status_id,
        flag,
        
        sow_id,
        boar_id,
        date_actual_birth
INTO    
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        cur_pig_prod_flag
        cur_pig_prod_date_actual_birth
        
FROM    pig_production 
WHERE   id = in_pig_prod_id
LIMIT   1;


SELECT  
        last_sow_id,
        last_boar_id
INTO    
        cur_pig_farm_last_sow_id,
        cur_pig_farm_last_boar_id
FROM    pig_farm
WHERE   id = cur_pig_prod_pig_farm_id
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



IF cur_pig_prod_status_id NOT IN(   PRODUCTION_STATUS_ID_LACTATING,
                                    PRODUCTION_STATUS_ID_WEANING,
                                    PRODUCTION_STATUS_ID_GROWING) THEN 
    SET res_num     = RES_NUM_PIG_PROD_STATUS_CANNOT_EARTAG;
    SET res_code    = "RES_NUM_PIG_PROD_STATUS_CANNOT_EARTAG";
END IF;



/** INSERT sow_boar entry*/

IF in_sex = 'F' THEN 
    SET cur_pig_farm_last_sow_id = cur_pig_farm_last_sow_id + 1;
    
    
    INSERT INTO sow_boar(
        account_id,
        pig_farm_id,
        farm_sow_id,
        
        sow_status_id,
        
        parent_sow_id,
        parent_boar_id,
        
        sex,
        
        number,
        date_of_birth,
        
        added_by_user_id
    ) VALUES (
        cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_farm_last_sow_id,
        
        in_sow_status_id,
        
        in_parent_sow_id,
        in_parent_boar_id,
        
        in_sex,
        
        in_number,
        in_date_of_birth,
        
        in_user_id
    );


ELSE
    SET cur_pig_farm_last_boar_id = cur_pig_farm_last_boar_id + 1;
    
    INSERT INTO sow_boar(
        account_id,
        pig_farm_id,
        farm_boar_id,
        
        line_id,
        sow_status_id,
        is_external,
        is_production_ready,
        
        sex,
        
        number,
        name,
        date_of_birth,
        
        added_by_user_id
    ) VALUES (
        cur_user_account_id,
        in_pig_farm_id,
        cur_pig_farm_last_boar_id,        

        in_line_id,
        NULL,
        in_is_external,
        in_is_production_ready,
        
        in_sex,
        
        in_number,
        in_name,
        in_date_of_birth,
        
        in_user_id
    );
    
    
END IF;

SELECT LAST_INSERT_ID() INTO cur_sow_boar_id;



UPDATE pig_farm SET 
    last_sow_id     = cur_pig_farm_last_sow_id,
    last_boar_id    = cur_pig_farm_last_boar_id
WHERE id = cur_pig_prod_pig_farm_id;





END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_prod_id;
    

END $$

DELIMITER ;
