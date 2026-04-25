DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_head_count_per_account $$
CREATE PROCEDURE sow_boar_head_count_per_account(
    in_account_id           INT
)  

BEGIN

/** 
 * Will count sow/boar/git per account.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since April 21, 2026
 *
 */


DECLARE l_last_row_fetched TINYINT;
DECLARE c_pig_farm CURSOR FOR
    SELECT  id
    FROM    pig_farm
    WHERE   account_id      = in_account_id 
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 

SET l_last_row_fetched=0;
OPEN c_pig_farm;   
    

loop_here: LOOP
    FETCH c_pig_farm INTO 
        cur_pig_farm_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    

END LOOP loop_here;
 
CLOSE c_pig_farm;
SET l_last_row_fetched=0;   


END $$

DELIMITER ;
