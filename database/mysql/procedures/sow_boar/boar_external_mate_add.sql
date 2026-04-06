DELIMITER $$

DROP PROCEDURE IF EXISTS boar_external_mate_add $$
CREATE PROCEDURE boar_external_mate_add(
    in_user_id              INT,
    
    in_boar_id              INT,
    in_boar_customer_id     INT,    /* This is mapped to account_pig_buyer*/
    
    in_customer_sow_name    VARCHAR(50),
    
    in_date_mate            VARCHAR(10),
    in_date_expected_birth  VARCHAR(10),
    in_date_expected_payment VARCHAR(10),
    
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


DECLARE BUSINESS_OBJ_ID_SOW_BOAR                INT             DEFAULT 19;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;



DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;


DECLARE cur_sow_boar_mate_id                    INT             DEFAULT 0;


DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;


DECLARE cur_boar_customer_name                  VARCHAR(50)     DEFAULT '';

DECLARE s_temp                                  VARCHAR(255)    DEFAULT '';

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        pig_farm_id
        
INTO    
        cur_sow_boar_account_id,
        cur_sow_boar_pig_farm_id
FROM    sow_boar
WHERE   id = in_boar_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
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


SELECT  id
INTO    cur_sow_boar_mate_id
FROM    sow_boar_mate
WHERE   sow_boar_id         = in_boar_id            AND
        boar_customer_id    = in_boar_customer_id   AND
        date_mate           = in_date_mate
        
LIMIT 1;
        


IF cur_sow_boar_mate_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



    
    
INSERT INTO sow_boar_mate(
    pig_farm_id,
    sow_boar_id,
    boar_customer_id,
    customer_sow_name,
    
    date_mate,
    date_expected_birth,
    date_expected_payment,
    
    added_by_user_id
) VALUES (
    cur_sow_boar_pig_farm_id,
    in_boar_id,
    in_boar_customer_id,
    in_customer_sow_name,
    
    in_date_mate,
    in_date_expected_birth,
    in_date_expected_payment,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_sow_boar_mate_id;


UPDATE sow_boar SET 
    mate_count      = mate_count + 1,
    date_last_mate  = in_date_mate
WHERE id = in_boar_id;


SELECT  name
INTO    cur_boar_customer_name
FROM    account_pig_buyer
WHERE   id = in_boar_customer_id; 

SET s_temp = CONCAT('SYS: External Mate; boar_customer: ', cur_boar_customer_name);
IF in_notes IS NOT NULL THEN
    SET s_temp = CONCAT(s_temp, in_notes);
END IF;

SET s_temp = SUBSTRING(s_temp, 1, 160);


INSERT INTO pig_prod_notes (
    sow_boar_id,
    
    notes,
    date_notes,
    added_by_user_id
    
) VALUES (
    in_boar_id,
    
    s_temp,
    in_date_mate,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;

UPDATE sow_boar_mate SET
    notes_id = cur_pig_prod_notes_id
WHERE id = cur_sow_boar_mate_id;




UPDATE sow_boar SET 
    data_ver_num_sow_boar   = data_ver_num_sow_boar + 1
WHERE id = in_boar_id;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_sow_boar_mate_id                AS sow_boar_mate_id;
    

END $$

DELIMITER ;
