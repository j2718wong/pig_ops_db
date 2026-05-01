DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_fattening_add $$
CREATE PROCEDURE pig_prod_fattening_add(
    in_user_id              INT,
    in_pig_farm_id          INT,
    
    in_num_pigs             INT,
    
    in_date_birth           VARCHAR(10), /* in YYYY-MM-DD format*/
    in_date_weaning         VARCHAR(10), /* in YYYY-MM-DD format*/
    
    in_notes                VARCHAR(160)
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
DECLARE FLAG_BIT_PIG_PROD_IS_DELETED            INT             DEFAULT 1;

DECLARE FLAG_BIT_IS_A_GROUP                     INT             DEFAULT 2;
DECLARE FLAG_BIT_PIGLETS_ARE_EXTERNAL           INT             DEFAULT 4;




DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;

DECLARE SOW_STATUS_ID_GESTATING                 INT             DEFAULT 2;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;


DECLARE cur_pig_farm_last_pig_production_id     INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


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


IF in_date_weaning IS NULL THEN 
    SET in_date_weaning = CURRENT_DATE;
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


SELECT  last_pig_production_id
INTO    cur_pig_farm_last_pig_production_id
FROM    pig_farm
WHERE   id = in_pig_farm_id;

SET cur_pig_farm_last_pig_production_id = cur_pig_farm_last_pig_production_id + 1;



INSERT INTO pig_production (
    account_id,
    pig_farm_id,
    farm_prod_id,
    
    flag,
    prod_status_id,
    
    date_actual_birth,
    date_weaning,
    
    num_pigs_current,
    
    
    added_by_user_id
    
) VALUES (
    cur_pig_farm_account_id,
    in_pig_farm_id,
    cur_pig_farm_last_pig_production_id,
    
    FLAG_BIT_PIGLETS_ARE_EXTERNAL,
    PRODUCTION_STATUS_ID_GROWING,
    
    in_date_birth,
    in_date_weaning,
    
    in_num_pigs,
    
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;



/* Add comments*/
IF in_notes IS NOT NULL THEN 
    INSERT INTO pig_prod_notes (
        account_id,
        pig_farm_id,
        
        pig_prod_id,
        
        notes,
        date_notes,
        added_by_user_id
        
    ) VALUES (
        cur_pig_farm_account_id,
        in_pig_farm_id,
    
        cur_pig_prod_id,
        
        in_notes,
        in_date_weaning,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    /* pig_production.insem_notes_id*/
    UPDATE pig_production SET
        insem_notes_id = cur_pig_prod_notes_id
    WHERE id = cur_pig_prod_id;

END IF;




/* Since the number of pigs at weaning is indeterminate as these are 
external pigs, this will be treated as pigs added to production entry. 
Note: The pig_production.num_pigs_current is a computed number

num_pigs_current = number_of_weaning_pigs + SUM(added_external_pigs) -
    SUM(pigs_dead_at_growing_stage) - SUM(pigs_already_harvested)

Need to insert to pig_prod_pig_add table.*/

INSERT INTO pig_prod_pig_add (
    account_id,
    pig_farm_id,
    pig_prod_id,
    
    date_added,
    num_pigs_added,
    added_by_user_id
) VALUES (
    cur_pig_farm_account_id,
    in_pig_farm_id,
    cur_pig_prod_id,
    
    in_date_weaning,
    in_num_pigs,
    in_user_id
);




/* Increment pig_farm.last_prod_id*/
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
