DELIMITER $$

DROP PROCEDURE IF EXISTS account_pig_ops_delete_update_prod_gestating $$
CREATE PROCEDURE account_pig_ops_delete_update_prod_gestating(
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

DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;


/* pig_prod_pig_ops.flag bits*/
DECLARE FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED    INT             DEFAULT 1;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_date_insemination          DATE            DEFAULT NULL;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_prod CURSOR FOR
    SELECT  id,
            date_insemination
    FROM    pig_production
    WHERE   account_id      = in_account_id AND 
            prod_status_id  = PRODUCTION_STATUS_ID_GESTATING
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


    
SET l_last_row_fetched=0;
OPEN c_account_pig_prod;   
    

loop_here: LOOP
    FETCH c_account_pig_prod INTO 
        cur_pig_prod_id,
        cur_pig_prod_date_insemination;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    UPDATE pig_prod_pig_ops SET
        flag = flag | FLAG_BIT_PIG_PROD_PIG_OPS_IS_DELETED
    WHERE pig_prod_id = cur_pig_prod_id AND account_pig_ops_id = in_account_pig_ops_id;
    

END LOOP loop_here;
 
CLOSE c_account_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
