DELIMITER $$

DROP PROCEDURE IF EXISTS boar_external_mate_update $$
CREATE PROCEDURE boar_external_mate_update(
    in_user_id              INT,
    in_sow_boar_mate_id     INT,
    
    in_boar_customer_id     INT,    /* This is mapped to account_pig_buyer*/
    
    in_customer_sow_name    VARCHAR(50),
    
    in_date_mate            VARCHAR(10),
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will update sow_boar_mate.
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
DECLARE cur_sow_boar_mate_notes_id              INT             DEFAULT 0;


DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  b.account_id,
        a.notes_id
        
INTO    cur_sow_boar_account_id,
        cur_sow_boar_mate_notes_id
        
FROM    sow_boar_mate a
LEFt OUTER JOIN  sow_boar b ON a.sow_boar_id = b.id
WHERE   a.id = in_sow_boar_mate_id
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



    
    
UPDATE sow_boar_mate SET
    boar_customer_id    = in_boar_customer_id,
    customer_sow_name   = in_customer_sow_name,
    
    date_mate           = in_date_mate,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_sow_boar_mate_id;

IF in_notes IS NOT NULL THEN
    IF cur_sow_boar_mate_notes_id IS  NULL THEN 

        INSERT INTO pig_prod_notes (
            sow_boar_id,
            
            notes,
            date_notes,
            added_by_user_id
            
        ) VALUES (
            in_boar_id,
            
            in_notes,
            in_date_mate,
            in_user_id
        );

        SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
        
        UPDATE sow_boar_mate SET
            notes_id = cur_pig_prod_notes_id
        WHERE id = in_sow_boar_mate_id;
        
    ELSE
        UPDATE pig_prod_notes SET
            notes = in_notes
        WHERE id = cur_sow_boar_mate_notes_id;
    END IF;

END IF;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc;
    

END $$

DELIMITER ;
