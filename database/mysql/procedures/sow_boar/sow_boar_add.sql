DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_add $$
CREATE PROCEDURE sow_boar_add(
    in_user_id              INT,
    
    in_pig_farm_id          INT,
    in_farm_birth_prod_id   INT,
    in_line_id              INT,
    in_sow_status_id        INT,
    
    in_sex                  CHAR(1),
    
    in_number               VARCHAR(10),
    in_name                 VARCHAR(20),
    in_date_of_birth        VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will add sow_boar entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 15, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 17;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_last_sow_id                INT             DEFAULT 0;
DECLARE cur_pig_farm_last_boar_id               INT             DEFAULT 0;


DECLARE cur_sow_boar_id                          INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  
        account_id,
        last_sow_id,
        last_boar_id
INTO    
        cur_pig_farm_account_id,
        cur_pig_farm_last_sow_id,
        cur_pig_farm_last_boar_id
FROM    pig_farm
WHERE   id = in_pig_farm_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SOW_BOAR,
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



/* Check for duplicate entry. */ 
IF in_number IS NOT NULL THEN 
    /* If sow_boar.number is given, will be check as one of unique keys. */

    SELECT  id
    INTO    cur_sow_boar_id
    FROM    sow_boar
    WHERE   account_id  = cur_user_account_id   AND
            pig_farm_id = in_pig_farm_id        AND
            sex         = in_sex                AND
            number      = in_number;

ELSE
    /* If sow_boar.name is given, will be check as one of unique keys. */
    
    SELECT  id
    INTO    cur_sow_boar_id
    FROM    sow_boar
    WHERE   account_id  = cur_user_account_id   AND
            pig_farm_id = in_pig_farm_id        AND
            sex         = in_sex                AND
            name        = in_name;

END IF;


IF cur_sow_boar_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


IF in_sex = 'F' THEN 
    SET cur_pig_farm_last_sow_id = cur_pig_farm_last_sow_id + 1;
ELSE
    SET cur_pig_farm_last_boar_id = cur_pig_farm_last_boar_id + 1;
END IF;

INSERT INTO sow_boar(
    account_id,
    pig_farm_id,
    farm_sow_id,
    farm_boar_id,
    
    farm_birth_prod_id,
    line_id,
    sow_status_id,
    
    sex,
    
    number,
    name,
    date_of_birth,
    notes,
    
    added_by_user_id
) VALUES (
    cur_user_account_id,
    in_pig_farm_id,
    cur_pig_farm_last_sow_id,
    cur_pig_farm_last_boar_id,
    
    in_farm_birth_prod_id,
    in_line_id,
    in_sow_status_id,
    
    in_sex,
    
    in_number,
    in_name,
    in_date_of_birth,
    in_notes,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_sow_boar_id;

UPDATE pig_farm SET 
    last_sow_id     = cur_pig_farm_last_sow_id,
    last_boar_id    = cur_pig_farm_last_boar_id
WHERE id = in_pig_farm_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_sow_boar_id                     AS sow_boar_id,
    cur_pig_farm_last_sow_id            AS farm_sow_id,
    cur_pig_farm_last_boar_id           AS farm_boar_id;
    

END $$

DELIMITER ;
