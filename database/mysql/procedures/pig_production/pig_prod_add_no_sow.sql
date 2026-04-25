DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_add_no_sow $$
CREATE PROCEDURE pig_prod_add_no_sow(
    in_user_id              INT,
    in_pig_farm_id          INT,
    
    in_num_pigs             INT,
    
    in_date_birth           VARCHAR(10),
    in_date_wean            VARCHAR(10),
    
    in_comments             VARCHAR(160)
)  

BEGIN

/** 
 * Will create pig_production entry without a sow; these are piglets bought 
 *   from outside.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since April 20, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


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


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_last_pig_production_id     INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_id                      INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;
DECLARE cur_flag_bit                            INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        last_pig_production_id

INTO    cur_pig_farm_account_id,
        cur_pig_farm_last_pig_production_id
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
/* TODO how to check duplicate
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
*/




SET cur_pig_farm_last_pig_production_id = cur_pig_farm_last_pig_production_id + 1;


INSERT INTO pig_production (
    account_id,
    pig_farm_id,
    farm_prod_id,
    
    num_pigs_weaning,
    num_pigs_current,
    
    prod_status_id,
    
    date_actual_birth,
    date_weaning

) VALUES (
    cur_user_account_id,
    in_pig_farm_id,
    cur_pig_farm_last_pig_production_id,
    
    in_num_pigs,
    in_num_pigs,
    
    PRODUCTION_STATUS_ID_GROWING,
    
    in_date_birth,
    in_date_wean 
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;

    
   

/* Add comments*/
IF in_comments IS NOT NULL THEN 
    INSERT INTO pig_prod_notes (
        account_id,
        pig_farm_id,
        
        pig_prod_id,
        sow_boar_id,
        
        notes,
        date_notes,
        added_by_user_id
        
    ) VALUES (
        cur_user_account_id,
        in_pig_farm_id,
    
        cur_pig_prod_id,
        NULL,
        
        in_comments,
        CURRENT_DATE,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    /* pig_production.insem_notes_id*/
    UPDATE pig_production SET
        insem_notes_id = cur_pig_prod_notes_id
    WHERE id = cur_pig_prod_id;

END IF;
    

/* Increment pig_farm.last_pig_production_id*/
UPDATE pig_farm SET 
    last_pig_production_id  = cur_pig_farm_last_pig_production_id,
    data_ver_num_pig_prod   = data_ver_num_pig_prod + 1    
WHERE id = in_pig_farm_id;



END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_id                     AS pig_prod_id;
    

END $$

DELIMITER ;
