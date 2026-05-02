DELIMITER $$

DROP PROCEDURE IF EXISTS account_update_sow_boar_count $$
CREATE PROCEDURE account_update_sow_boar_count()  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 2, 2026
 *
 */


DECLARE cur_account_id                          INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;



DECLARE l_last_row_fetched TINYINT;
DECLARE c_account CURSOR FOR
    SELECT  id
    FROM    account;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 

    
SET l_last_row_fetched=0;
OPEN c_account;   
    

loop_here: LOOP
    FETCH c_account INTO 
        cur_account_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;


    SET     cur_count = 0;

    /** Count sow_boar */
    SELECT  COUNT(*)
    INTO    cur_count
    FROM    sow_boar
    WHERE   account_id = cur_account_id;
    
    
    UPDATE account SET
        count_sow_boar = cur_count
    WHERE id = cur_account_id;
   

END LOOP loop_here;
 
CLOSE c_account;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
