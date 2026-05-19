DELIMITER $$

DROP PROCEDURE IF EXISTS account_sow_due_chklst_update_loop $$
CREATE PROCEDURE account_sow_due_chklst_update_loop(
    in_account_id           INT,
    in_account_chklst_id    INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 20, 2026
 *
 */



DECLARE cur_pig_farm_id                         INT             DEFAULT 0;
DECLARE cur_pig_farm_chklst_id                  INT             DEFAULT 0;



DECLARE l_last_row_fetched TINYINT;
DECLARE c_pig_farm CURSOR FOR
    SELECT  id,
            last_sow_due_chklst_id
    FROM    pig_farm
    WHERE   account_id = in_account_id AND last_sow_due_chklst_id > 0;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 

    
SET l_last_row_fetched=0;
OPEN c_pig_farm;   
    

loop_here: LOOP
    FETCH c_pig_farm INTO 
        cur_pig_farm_id,
        cur_pig_farm_chklst_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;



    UPDATE pig_farm_sow_due_chklst SET 
        data_ver_num_chklst = data_ver_num_chklst + 1
    WHERE id = cur_pig_farm_chklst_id;
    
    
    UPDATE pig_farm SET 
        data_ver_num_sd_chklst = data_ver_num_sd_chklst + 1
    WHERE id = cur_pig_farm_id;

END LOOP loop_here;
 
CLOSE c_pig_farm;
SET l_last_row_fetched=0;   



END $$

DELIMITER ;
