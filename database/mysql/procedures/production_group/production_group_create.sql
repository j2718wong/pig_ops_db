DELIMITER $$

DROP PROCEDURE IF EXISTS production_group_create $$
CREATE PROCEDURE production_group_create(
    in_user_id              INT,

    in_pig_prod_id          INT, /*initial pig_production in the production_group*/
    
    in_date_added           INT
)  

BEGIN

/** 
 * Will add production_group entry. Note the procedure name is purposely 
 * not production_group_add  so that it will not confuse with 
 * production_group_pig_prod_add procedure. A production_group is formed
 * when a pig_production in converted to production_group and more pig_production
 * entries are added into the production_group.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_CANNOT_BE_ADDED_TO_GROUP        INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PRODUCTION_GROUP        INT             DEFAULT 34;

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
DECLARE PRODUCTION_STATUS_ID_CULLED             INT             DEFAULT 10;



DECLARE PRODUCTION_GROUP_STATUS_ID_GROWING      INT             DEFAULT 1;
DECLARE PRODUCTION_GROUP_STATUS_ID_HARVESTED    INT             DEFAULT 2;
DECLARE PRODUCTION_GROUP_STATUS_ID_CLOSED       INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_production_group_id        INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_farm_last_production_group_id   INT             DEFAULT 0;

DECLARE cur_production_group_id                 INT             DEFAULT 0;
DECLARE cur_production_group_flag               INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PRODUCTION_GROUP,
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



/* Get the farm information of the in_pig_prod_id.*/
SELECT  a.production_group_id,
        a.pig_farm_id,
        a.prod_status_id,
        b.last_production_group_id

INTO    cur_pig_prod_production_group_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_status_id,
        cur_pig_farm_last_production_group_id
FROM    pig_production a 
LEFT OUTER JOIN pig_farm b ON a.pig_farm_id = b.id
WHERE   a.id = in_pig_prod_id;


/* Check for duplicate entry */
/* A pig_production entry can only be associated with one production_group*/
IF cur_pig_prod_production_group_id > 0 THEN 
    SET res_num     = RES_NUM_CANNOT_BE_ADDED_TO_GROUP;
    SET res_code    = "RES_NUM_CANNOT_BE_ADDED_TO_GROUP";
    SET res_desc    = "Production already added to group.";
    
    LEAVE process_user;
END IF;


/* Check the status of the pig_production entry to be added into the group*/
IF cur_pig_prod_status_id NOT IN (  PRODUCTION_STATUS_ID_WEANING,
                                    PRODUCTION_STATUS_ID_GROWING) THEN 
    SET res_num     = RES_NUM_CANNOT_BE_ADDED_TO_GROUP;
    SET res_code    = "RES_NUM_CANNOT_BE_ADDED_TO_GROUP";
    SET res_desc    = "Production status not WEANING or GROWING.";
    
    LEAVE process_user;
END IF;


SET cur_pig_farm_last_production_group_id = cur_pig_farm_last_production_group_id + 1;


INSERT INTO production_group(
    account_id,
    pig_farm_id,
    farm_production_group_id,
    prod_group_status_id,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    cur_pig_prod_pig_farm_id,
    cur_pig_farm_last_production_group_id,
    PRODUCTION_GROUP_STATUS_ID_GROWING,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_production_group_id;


INSERT INTO production_group_pig_prod (
    production_group_id,
    pig_prod_id,
    date_added_to_group,
    added_by_user_id
)
VALUES (
    cur_production_group_id,
    in_pig_prod_id,
    in_date_added,
    in_user_id
);


UPDATE pig_production SET
    prod_status_id          = PRODUCTION_STATUS_ID_COMBINED,
    production_group_id     = cur_production_group_id
WHERE id = in_pig_prod_id;


UPDATE pig_farm SET
    last_production_group_id = cur_pig_farm_last_production_group_id
WHERE id = cur_pig_prod_pig_farm_id;


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_production_group_id             AS production_group_id;

END $$

DELIMITER ;
