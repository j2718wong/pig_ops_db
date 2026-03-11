DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_delete_update_weaning_sows $$
CREATE PROCEDURE account_pig_ops_delete_update_weaning_sows(
    in_account_id           INT,
    
    in_account_pig_ops_id   INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since November 4, 2025
 *
 */

DECLARE SOW_STATUS_WEANING                      INT             DEFAULT 4;


/* pig_prod_pig_ops.flag bits*/
DECLARE FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED    INT             DEFAULT 1;


DECLARE cur_sow_id                              INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_weaning_sows CURSOR FOR
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


    
SET l_last_row_fetched=0;
OPEN c_account_weaning_sows;   
    

loop_here: LOOP
    FETCH c_account_weaning_sows INTO 
        cur_sow_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        flag = flag | FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED
    WHERE sow_boar_id = cur_sow_id AND account_pig_ops_id = in_account_pig_ops_id;
    

END LOOP loop_here;
 
CLOSE c_account_weaning_sows;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
