DELIMITER $$

DROP PROCEDURE IF EXISTS pf_sow_due_chklst_item_update $$
CREATE PROCEDURE pf_sow_due_chklst_item_update(
    in_user_id              INT,
    in_chklst_item_id       INT,
    in_is_checked           INT
)  

BEGIN

/** 
 * Will update pf_sow_due_chklst_item.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 19, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE cur_pf_sow_due_chklst_id                INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  pf_sow_due_chklst_id
INTO    cur_pf_sow_due_chklst_id
FROM    pf_sow_due_chklst_item
WHERE   id = in_chklst_item_id;


IF in_is_checked > 0 THEN  
    UPDATE pf_sow_due_chklst_item SET
        date_checked        = CURRENT_TIMESTAMP,
        checked_user_id     = in_user_id
    WHERE id = in_chklst_item_id;
ELSE
    UPDATE pf_sow_due_chklst_item SET
        date_checked        = NULL,
        checked_user_id     = NULL
    WHERE id = in_chklst_item_id;

END IF;


UPDATE pig_farm_sow_due_chklst SET 
    data_ver_num_chklst = data_ver_num_chklst + 1
WHERE id = cur_pf_sow_due_chklst_id;



SELECT 
    res_num                     AS result_number,
    res_code                    AS result_code,
    res_desc                    AS result_desc,

    in_chklst_item_id           AS  chklst_item_id;

END $$



DELIMITER ;
