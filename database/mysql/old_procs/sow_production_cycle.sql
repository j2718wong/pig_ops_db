DELIMITER $$

DROP PROCEDURE IF EXISTS sow_production_cycle $$
CREATE PROCEDURE sow_production_cycle()  

BEGIN

/** 
 * Will update artificial_insemination.semen_desc.
 * 
 * @author Jack Wong (neoaspilet11@gmail.com, zhaoshan99@gmail.com) 
 * @since April 26, 2025
 *
 */
 
DECLARE cur_sow_id                              INT             DEFAULT 0;
DECLARE cur_sow_number                     		INT             DEFAULT 0;
DECLARE cur_last_prod_id						INT             DEFAULT 0;

DECLARE cur_prod_status_id						INT             DEFAULT 0;
DECLARE cur_prod_date_expected					DATE;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_sow CURSOR FOR
    SELECT  id,
            sow_number,
			last_prod_id
    FROM    sow 
	WHERE 	date_culled IS NOT NULL; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 
 
    
SET l_last_row_fetched=0;
OPEN c_sow;   
    

loop_here: LOOP
    FETCH   c_sow 
    INTO    cur_sow_id,
            cur_sow_number,
			cur_last_prod_id;

	IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

	SELECT 	status_id,
			date_expected_birth
			
	INTO 	cur_prod_status_id,
			cur_prod_date_expected
	
	FROM 	pig_production
	WHERE 	id = cur_last_prod_id;
	
	
	

END LOOP loop_here;
 
CLOSE c_sow;
SET l_last_row_fetched=0;   

SELECT 1 AS result_code;

    

END $$

DELIMITER ;
