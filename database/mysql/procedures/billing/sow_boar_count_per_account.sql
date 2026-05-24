DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_count_per_account $$
CREATE PROCEDURE sow_boar_count_per_account(
    in_account_id               INT,
    OUT out_num_pigs            INT,
    OUT out_sow_boar_count_id   INT 
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 2, 2026
 *
 */



DECLARE cur_count_sow                           INT             DEFAULT 0;
DECLARE cur_count_boar                          INT             DEFAULT 0;

DECLARE cur_sow_boar_head_count_id              INT             DEFAULT 0;


/* Count sow, gilt*/
SELECT  COUNT(*) 
INTO    cur_count_sow
FROM    sow_boar
WHERE   account_id = in_account_id  AND
        sex = 'F'                   AND
        is_disposed = 0;

SELECT  COUNT(*) 
INTO    cur_count_boar
FROM    sow_boar
WHERE   account_id = in_account_id  AND
        sex = 'M'                   AND
        is_disposed = 0;



INSERT INTO sow_boar_head_count (
    account_id,
    num_sow,
    num_boar,
    business_date
) VALUES(
    in_account_id,
    cur_count_sow,
    cur_count_boar,
    CURRENT_DATE
);
SELECT LAST_INSERT_ID() INTO cur_sow_boar_head_count_id;


UPDATE account SET
    last_sow_boar_count_id = cur_sow_boar_head_count_id
WHERE id = in_account_id;


/* Return number of sow/boar pigs counted*/
SET out_num_pigs = cur_count_sow + cur_count_boar;

SET out_sow_boar_count_id = cur_sow_boar_head_count_id;

END $$

DELIMITER ;
