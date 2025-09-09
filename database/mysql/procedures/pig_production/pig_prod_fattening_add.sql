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
DECLARE PIG_OPERATION_TYPE_LACTATING            INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_GROWING              INT             DEFAULT 3;



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
    
    cur_pig_prod_id                     AS pig_prod_id,
    0                                   AS pig_prod_ai_id;
    

END $$

DELIMITER ;
