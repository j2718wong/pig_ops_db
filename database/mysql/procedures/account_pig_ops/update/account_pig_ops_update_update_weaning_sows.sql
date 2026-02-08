DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_update_update_weaning_sows $$
CREATE PROCEDURE account_pig_ops_update_update_weaning_sows(
    in_account_id           INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE SOW_STATUS_WEANING                      INT             DEFAULT 4;

DECLARE cur_sow_id                              INT             DEFAULT 0;
DECLARE cur_sow_date_wean                       DATE            DEFAULT NULL;


DECLARE cur_account_flag_settings               INT             DEFAULT 0;


/* account.flag_setting bits*/
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_BIRTH         INT             DEFAULT 1;
DECLARE FLAG_BIT_DAY_1_ON_DATE_OF_INSEM         INT             DEFAULT 2;

DECLARE num_days_to_add                         INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_sows CURSOR FOR
    SELECT  a.id,
            b.date_weaning
    FROM    sow_boar a
    LEFT OUTER JOIN pig_production b ON a.last_pig_production_id = b.id
    WHERE   a.account_id      = in_account_id       AND 
            a.sex             = 'F'                 AND
            a.sow_status_id   = SOW_STATUS_WEANING  AND 
            b.date_weaning IS NOT NULL
            
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


/* See account_pig_ops.sql Notes for this num_days_to_add adjustment.*/

/* unless needed
SELECT  flag_settings
INTO    cur_account_flag_settings
FROM    account 
WHERE   id = in_account_id;
*/


SET num_days_to_add = in_num_days_since;
    
    
SET l_last_row_fetched=0;
OPEN c_account_sows;   
    

loop_here: LOOP
    FETCH c_account_sows INTO 
        cur_sow_id,
        cur_sow_date_wean;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        date_target = DATE_ADD(cur_sow_date_wean, INTERVAL num_days_to_add DAY)
    WHERE sow_boar_id = cur_sow_id AND account_pig_ops_id = in_account_pig_ops_id;


END LOOP loop_here;
 
CLOSE c_account_sows;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
