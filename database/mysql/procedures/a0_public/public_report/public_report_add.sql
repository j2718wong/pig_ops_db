DELIMITER $$

DROP PROCEDURE IF EXISTS public_report_add $$
CREATE PROCEDURE public_report_add(
    in_user_id              INT,

    in_supplier_id          INT,
    in_report_type          INT,
    
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will add public_report entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;




DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_report_id                           INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    0, /* public business object*/
    0,
    
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

/* Allow duplicates as there are no keys to duplicate check*/


INSERT INTO public_report(
    supplier_id,
    report_type_id,
    
    notes,
    added_by_user_id
    
) VALUES (
    in_supplier_id,
    in_report_type_id,
    
    in_notes,
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_report_id;



END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_report_id                       AS report_id;

END $$

DELIMITER ;
