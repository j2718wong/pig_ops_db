DELIMITER $$

DROP PROCEDURE IF EXISTS account_sow_due_chklst_create $$
CREATE PROCEDURE account_sow_due_chklst_create(
    in_account_id               INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 19, 2026
 *
 */



INSERT INTO account_sow_due_chklst (
    account_id,
    name
) VALUES (
    in_account_id,
    "Check Heat Lamp"
),

(
    in_account_id,
    "Buy Oxytocin"
),

(
    in_account_id,
    "Buy Mistral powder"
),

(
    in_account_id,
    "Buy Iron for piglets"
);



END $$

DELIMITER ;
