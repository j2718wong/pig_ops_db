DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_add_update_weaning_sows $$
CREATE PROCEDURE account_pig_ops_add_update_weaning_sows(
    in_account_id           INT,
    in_operation_type       INT,
    
    in_account_pig_ops_id   INT,
    in_num_days_since       INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 8, 2026
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

    INSERT INTO pig_prod_pig_ops(
        sow_boar_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        cur_sow_id,
        in_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(cur_sow_date_wean, INTERVAL num_days_to_add DAY)
    );
    

END LOOP loop_here;
 
CLOSE c_account_sows;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
