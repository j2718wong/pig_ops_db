DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_sow_due_chklst_loop $$
CREATE PROCEDURE pig_farm_sow_due_chklst_loop()  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 20, 2026
 *
 */



DECLARE cur_pig_farm_id                         INT             DEFAULT 0;



DECLARE l_last_row_fetched TINYINT;
DECLARE c_pig_farm CURSOR FOR
    SELECT  id
    FROM    pig_farm
    WHERE   last_sow_id > 0;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 

    
SET l_last_row_fetched=0;
OPEN c_pig_farm;   
    

loop_here: LOOP
    FETCH c_pig_farm INTO 
        cur_pig_farm_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    
    CALL pig_farm_sow_due_chklst_add(cur_pig_farm_id);

END LOOP loop_here;
 
CLOSE c_pig_farm;
SET l_last_row_fetched=0;   



END $$

DELIMITER ;
