DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_add $$
CREATE PROCEDURE pig_prod_add(
    in_user_id              INT,
   
    in_sow_id               INT,    /* Cannot be updated*/
    in_boar_id              INT,    /* Cannot be updated*/
    in_semen_source_id      INT,    /* Cannot be updated*/
    
    in_semen_cost           DECIMAL(6,2),
    in_insemination_cost    DECIMAL(6,2),
    in_insem_cost_comments  VARCHAR(200),
    
    in_insem_staff_id       INT,
    in_date_insemination    VARCHAR(10)  /* in YYYY-MM-DD format*/
)  

BEGIN

/** 
 * Will create pig_production entriy.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 17, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE INSEMINATION_TYPE_BOAR                  VARCHAR(2)      DEFAULT 'B';
DECLARE INSEMINATION_TYPE_ARTIFICIAL            VARCHAR(2)      DEFAULT 'AI';


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 10;

DECLARE SOW_STATUS_ID_GESTATING                 INT             DEFAULT 2;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING            INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_GROWING              INT             DEFAULT 3;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_farm_sow_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_last_prod_id               INT             DEFAULT 0;
DECLARE cur_sow_boar_last_prod_status_id        INT             DEFAULT 0;


DECLARE cur_pig_farm_last_prod_id               INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_id                      INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.account_id,
        a.pig_farm_id,
        a.farm_sow_id,
        a.last_prod_id,
        b.prod_status_id
INTO    cur_sow_boar_account_id,
        cur_sow_boar_pig_farm_id,
        cur_sow_boar_farm_sow_id,
        cur_sow_boar_last_prod_id,
        cur_sow_boar_last_prod_status_id
FROM    sow_boar a
LEFT OUTER JOIN pig_production b ON a.last_prod_id = b.id
WHERE   a.id = in_sow_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
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
WHERE   sow_id              = in_sow_id     AND 
        date_insemination   = in_date_insemination 
LIMIT   1;


IF cur_pig_prod_id > 0 THEN
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* Set previous pig_production of this sow to not pregnant, if status is gestating*/
IF cur_sow_boar_last_prod_status_id = PRODUCTION_STATUS_ID_GESTATING THEN 
    UPDATE pig_production SET 
        prod_status_id = PRODUCTION_STATUS_ID_NOT_PREGNANT
    WHERE id = cur_sow_boar_last_prod_id;
END IF;


SELECT  last_prod_id
INTO    cur_pig_farm_last_prod_id
FROM    pig_farm
WHERE   id = cur_sow_boar_pig_farm_id;

SET cur_pig_farm_last_prod_id = cur_pig_farm_last_prod_id + 1;

IF in_boar_id IS NOT NULL THEN 
    INSERT INTO pig_production (
        account_id,
        pig_farm_id,
        farm_prod_id,
        
        sow_id,
        insemination_type,
        semen_boar_id,
        semen_source_id,
        
        semen_cost,
        insemination_cost,
        insem_cost_comments,
        
        date_insemination,
        date_expected_birth,
        
        prod_status_id,
        insem_staff_id
    ) VALUES (
        cur_user_account_id,
        cur_sow_boar_pig_farm_id,
        cur_pig_farm_last_prod_id,
        
        in_sow_id,
        INSEMINATION_TYPE_BOAR,
        in_boar_id,
        NULL,
        
        NULL,
        in_insemination_cost,
        in_insem_cost_comments,
        
        in_date_insemination,
        DATE_ADD(in_date_insemination, INTERVAL 115 DAY),

        PRODUCTION_STATUS_ID_GESTATING,
        in_insem_staff_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;

ELSE
    /* artificial insemination */
    
    INSERT INTO pig_production (
        account_id,
        pig_farm_id,
        farm_prod_id,
        
        sow_id,
        insemination_type,
        semen_boar_id,
        semen_source_id,
        
        semen_cost,
        insemination_cost,
        insem_cost_comments,
        
        date_insemination,
        date_expected_birth,
        
        prod_status_id,
        insem_staff_id
    ) VALUES (
        cur_user_account_id,
        cur_sow_boar_pig_farm_id,
        cur_pig_farm_last_prod_id,
        
        in_sow_id,
        INSEMINATION_TYPE_ARTIFICIAL,
        NULL,
        in_semen_source_id,
        
        in_semen_cost,
        in_insemination_cost,
        in_insem_cost_comments,
        
        in_date_insemination,
        DATE_ADD(in_date_insemination, INTERVAL 115 DAY),

        PRODUCTION_STATUS_ID_GESTATING,
        in_insem_staff_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;
    
    
    INSERT INTO pig_prod_ai(
        pig_farm_id,
        pig_prod_id,
        semen_source_id,
        insem_staff_id,
        date_insemination,
        
        added_by_user_id
    ) VALUES(
        cur_sow_boar_pig_farm_id,
        cur_pig_prod_id,
        in_semen_source_id,
        in_insem_staff_id,
        in_date_insemination,
        
        in_user_id
    );
    
    SELECT LAST_INSERT_ID() INTO cur_pig_prod_ai_id;
    
END IF; 
    

/* Increment pig_farm.last_prod_id*/
UPDATE pig_farm SET 
    last_prod_id    = cur_pig_farm_last_prod_id
WHERE id = cur_sow_boar_pig_farm_id;


/* Update sow status*/
UPDATE sow_boar SET
    last_prod_id    = cur_pig_prod_id,
    sow_status_id   = SOW_STATUS_ID_GESTATING
WHERE id = in_sow_id;


/* Create pig_prod_pig_ops entry*/
CALL pig_prod_pig_ops_add(
    in_user_id, 
    
    cur_sow_boar_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    cur_pig_prod_id, 
    in_date_insemination);


END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_id                     AS pig_prod_id,
    cur_pig_prod_ai_id                  AS pig_prod_ai_id;
    

END $$

DELIMITER ;
