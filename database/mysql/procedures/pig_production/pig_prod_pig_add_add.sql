DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_add_add $$
CREATE PROCEDURE pig_prod_pig_add_add(
    in_user_id              INT,
    in_pig_prod_id          INT,
    
    in_num_pigs_added       INT,
    
    in_date_added           VARCHAR(10)
)  

BEGIN

/** 
 * Will add pigs to a production entry; These pigs are assumed coming from outside.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since April 25, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD_PIGS_TO_PROD         INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* pig_production.flag bits*/
DECLARE FLAG_BIT_PIGLETS_ARE_EXTERNAL           INT             DEFAULT 4;



DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_pig_add_id                 INT             DEFAULT 0; 

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_farm_id                    INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;



DECLARE cur_num_pigs_current                    INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        pig_farm_id,
        prod_status_id
        
INTO    cur_pig_prod_account_id,
        cur_pig_prod_farm_id,
        cur_pig_prod_status_id

FROM    pig_production
WHERE   id = in_pig_prod_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
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
INTO    cur_pig_prod_pig_add_id
FROM    pig_prod_pig_add

WHERE   pig_prod_id         = in_pig_prod_id  AND
        date_added          = in_date_added
LIMIT   1;


IF cur_pig_prod_pig_add_id > 0 THEN
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* Check valid prod_status_id*/
IF cur_pig_prod_status_id NOT IN (PRODUCTION_STATUS_ID_LACTATING,
                                  PRODUCTION_STATUS_ID_WEANING,  
                                  PRODUCTION_STATUS_ID_GROWING) THEN
    SET res_num     = RES_NUM_CANNOT_ADD_PIGS_TO_PROD;
    SET res_code    = "RES_NUM_CANNOT_ADD_PIGS_TO_PROD";
    
    LEAVE process_user;
END IF;


INSERT INTO pig_prod_pig_add (
    account_id,
    pig_farm_id,
    pig_prod_id,
    
    num_pigs_added,
    
    date_added,
    added_by_user_id
    
) VALUES (
    cur_pig_prod_account_id,
    cur_pig_prod_farm_id,
    in_pig_prod_id,
    
    in_num_pigs_added,
    
    in_date_added,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_pig_add_id;


/* Calculate current number of pigs.*/
CALL production_calculate_current_pigs(in_pig_prod_id, 0, cur_num_pigs_current);

IF cur_num_pigs_current < 0 THEN
    /* Something is wrong*/
    SET cur_num_pigs_current = 0;
    
    UPDATE  pig_production SET
        num_pigs_current = 0,
        prod_status_id = PRODUCTION_STATUS_ID_HARVESTED
    WHERE id = in_pig_prod_id;
END IF;


/* This only updates pig_production because of the change of number of pigs. */
UPDATE  pig_production SET
    num_pigs_current        = cur_num_pigs_current,
    data_ver_num_pig_prod   = data_ver_num_pig_prod + 1
WHERE id = in_pig_prod_id;





END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_pig_prod_id                      AS pig_prod_id;
    

END $$

DELIMITER ;
