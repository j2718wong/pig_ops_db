DELIMITER $$

DROP PROCEDURE IF EXISTS semen_source_update $$
CREATE PROCEDURE semen_source_update(
    in_user_id              INT,
    
    in_semen_source_id      INT,
    
    in_pig_farm_id          INT,
    in_boar_id              INT,
    
    in_semen_supplier_id    INT,
    in_pig_race_line_id     INT,
    
    
    in_name                 VARCHAR(50),
    in_description          VARCHAR(160)
    
)  

BEGIN

/** 
 * Will update semen_source entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 18, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_SEMEN_SOURCE            INT             DEFAULT 18;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_semen_source_id                     INT             DEFAULT 0;
DECLARE cur_semen_source_flag                   INT             DEFAULT 0;
DECLARE cur_semen_source_account_id             INT             DEFAULT 0;
DECLARE cur_semen_source_name                   VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_semen_source_account_id
FROM    semen_source
WHERE   id = in_semen_source_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_semen_source_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SEMEN_SOURCE,
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



/* Check for duplicate entry */
IF in_boar_id > 0 THEN 
    SELECT  id
    INTO    cur_semen_source_id
    FROM    semen_source
    WHERE   id          != in_semen_source_id   AND
            account_id  = cur_user_account_id   AND 
            boar_id     = in_boar_id
    LIMIT   1;
    
ELSE
    SELECT  id
    INTO    cur_semen_source_id
    FROM    semen_source
    WHERE   id          != in_semen_source_id   AND
            account_id  = cur_user_account_id   AND 
            UPPER(name) = UPPER(in_name)
    LIMIT   1;

END IF;

IF cur_semen_source_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


UPDATE semen_source SET
    pig_farm_id         = in_pig_farm_id,
    boar_id             = in_boar_id,
    
    semen_supplier_id   = in_semen_supplier_id,
    pig_race_line_id    = in_pig_race_line_id,
    
    name                = in_name,
    description         = in_description,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
    
WHERE id =  in_semen_source_id;

END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_source_flag,
    cur_semen_source_name
FROM semen_source
WHERE id = in_semen_source_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_semen_source_id                  AS semen_source_id,
    cur_semen_source_flag               AS semen_source_flag,
    cur_semen_source_name               AS semen_source_name;
    

END $$

DELIMITER ;
