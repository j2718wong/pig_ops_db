DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_mate_populate $$
CREATE PROCEDURE sow_boar_mate_populate()  

BEGIN

/** 
 * A sub procedure to create pig_prod_pig_ops entries.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 30, 2025
 *
 */

DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_boar_id                    INT             DEFAULT 0;
DECLARE cur_pig_prod_date_insemination          DATE;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_pig_prod CURSOR FOR
    SELECT  id,
            sow_id,
            boar_id,
            date_insemination
    FROM    pig_production
    WHERE   boar_id IS NOT NULL; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 

    
SET l_last_row_fetched=0;
OPEN c_pig_prod;   
    

loop_here: LOOP
    FETCH c_pig_prod INTO 
        cur_pig_prod_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_boar_id,
        cur_pig_prod_date_insemination;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    INSERT INTO sow_boar_mate(
        pig_prod_id,
        sow_boar_id,
        mate_sow_boar_id,
        date_mate
    ) VALUES(
        cur_pig_prod_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_boar_id,
        cur_pig_prod_date_insemination
    ),
    
    (
        cur_pig_prod_id,
        cur_pig_prod_boar_id,
        cur_pig_prod_sow_id,
        cur_pig_prod_date_insemination
    );
   

END LOOP loop_here;
 
CLOSE c_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
