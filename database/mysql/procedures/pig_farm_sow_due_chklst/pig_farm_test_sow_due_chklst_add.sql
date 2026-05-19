DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_test_sow_due_chklst_add $$
CREATE PROCEDURE pig_farm_test_sow_due_chklst_add(
    in_pig_farm_id          INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 19, 2026
 *
 */


DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_sow_due_chklst_id          INT             DEFAULT 0;
DECLARE cur_pig_farm_new_chklst_id              INT             DEFAULT 0;


SELECT  account_id,
        last_sow_due_chklst_id
        
INTO    cur_pig_farm_account_id,
        cur_pig_farm_sow_due_chklst_id

FROM    pig_farm
WHERE   id = in_pig_farm_id;



/** Create pig_farm_sow_due_chklst entry. */
INSERT INTO pig_farm_sow_due_chklst(
    pig_farm_id,
    date_start_show
    -- date_start_end will be NULL initially
) VALUES (
    in_pig_farm_id,
    CURRENT_DATE
);

SELECT LAST_INSERT_ID() INTO cur_pig_farm_new_chklst_id;


/** Update pig_farm. */
UPDATE pig_farm SET 
    last_sow_due_chklst_id = cur_pig_farm_new_chklst_id
WHERE id = in_pig_farm_id;


/** Create pf_sow_due_chklst_item entries*/
INSERT INTO pf_sow_due_chklst_item(
    pf_sow_due_chklst_id,
    acc_sow_due_chklst_id
)

SELECT
    cur_pig_farm_new_chklst_id, 
    id
FROM account_sow_due_chklst
WHERE account_id = cur_pig_farm_account_id
ORDER BY name;



END $$



DELIMITER ;
