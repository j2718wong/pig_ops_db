DELIMITER $$

DROP PROCEDURE IF EXISTS production_group_pig_prod_add $$
CREATE PROCEDURE production_group_pig_prod_add(
    in_user_id              INT,

    in_production_group_id  INT,
    in_pig_prod_id          INT,
    
    in_date_added           INT
)  

BEGIN

/** 
 * Will add (combine) pig_production to existing production_group entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


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



DECLARE PRODUCTION_GRP_STATUS_ID_GROWING        INT             DEFAULT 1;
DECLARE PRODUCTION_GRP_STATUS_ID_HARVESTED      INT             DEFAULT 2;
DECLARE PRODUCTION_GRP_STATUS_ID_CLOSED         INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_production_group_account_id         INT             DEFAULT 0;


DECLARE cur_pig_prod_production_group_id        INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_num_pigs_current                    INT             DEFAULT 0;



DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";

SELECT  account_id
INTO    cur_production_group_account_id
FROM    production_group
WHERE   id = in_production_group_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_production_group_account_id, /* compare user.account_id to this account_id*/
    
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



SELECT  a.production_group_id,
        a.prod_status_id

INTO    cur_pig_prod_production_group_id,
        cur_pig_prod_status_id
        
FROM    pig_production a 
WHERE   a.id = in_pig_prod_id;


/* A pig_production entry can only be associated with one production_group*/
IF cur_pig_prod_production_group_id > 0 THEN 
    SET res_num     = RES_NUM_CANNOT_BE_ADDED_TO_GROUP;
    SET res_code    = "RES_NUM_CANNOT_BE_ADDED_TO_GROUP";
    SET res_desc    = "Production already added to group.";
    
    LEAVE process_user;
END IF;



INSERT INTO production_group_pig_prod (
    production_group_id,
    pig_prod_id,
    date_added_to_group,
    added_by_user_id
)
VALUES (
    in_production_group_id,
    in_pig_prod_id,
    in_date_added,
    in_user_id
);


UPDATE pig_production SET
    prod_status_id          = PRODUCTION_STATUS_ID_COMBINED,
    production_group_id     = in_production_group_id
WHERE id = in_pig_prod_id;

END process_user;


/* Compute current total pigs in the production_group*/
CALL production_calculate_current_pigs(0, in_production_group_id, cur_num_pigs_current);
    

UPDATE production_group SET 
    num_pigs_current = cur_num_pigs_current
WHERE id = in_production_group_id;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_production_group_id              AS production_group_id;

END $$

DELIMITER ;
