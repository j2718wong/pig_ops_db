DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_num_pigs_wean_populate $$
CREATE PROCEDURE sow_boar_num_pigs_wean_populate()  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 23, 2025
 *
 */


DECLARE cur_pig_prod_sow_id                     INT             DEFAULT 0;

DECLARE cur_count_births                        INT             DEFAULT 0;

DECLARE cur_num_pigs_weaning_m                  INT             DEFAULT 0;
DECLARE cur_num_pigs_weaning_f                  INT             DEFAULT 0;
DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;

DECLARE cur_num_pigs_live_m                     INT             DEFAULT 0;
DECLARE cur_num_pigs_live_f                     INT             DEFAULT 0;


DECLARE cur_num_pigs                            INT             DEFAULT 0;



DECLARE l_last_row_fetched TINYINT;
DECLARE c_pig_prod CURSOR FOR
    SELECT  sow_id
    FROM    pig_production
    GROUP BY  sow_id;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 

    
SET l_last_row_fetched=0;
OPEN c_pig_prod;   
    

loop_here: LOOP
    FETCH c_pig_prod INTO 
        cur_pig_prod_sow_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    /** Count number of births */
    SELECT  COUNT(*)
    INTO    cur_count_births
    FROM    pig_production
    WHERE   sow_id = cur_pig_prod_sow_id AND date_actual_birth IS NOT NULL;
    
    
    /** SUM the number pigs weaned for this sow. */

    SELECT  SUM(num_pigs_weaning_m),
            SUM(num_pigs_weaning_f),
            SUM(num_pigs_weaning)
            
    INTO    cur_num_pigs_weaning_m,    
            cur_num_pigs_weaning_f,
            cur_num_pigs_weaning
    FROM    pig_production
    WHERE   sow_id = cur_pig_prod_sow_id AND date_weaning IS NOT NULL;
    
    
    SELECT  SUM(num_pigs_live_m),
            SUM(num_pigs_live_f)
            
    INTO    cur_num_pigs_live_m,    
            cur_num_pigs_live_f
            
    FROM    pig_production
    WHERE   sow_id = cur_pig_prod_sow_id    AND 
            date_actual_birth IS NOT NULL   AND 
            date_weaning IS NULL;
    
    

    SET cur_num_pigs = 0;
    
    
    IF cur_num_pigs_weaning_m > 0 THEN 
        SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning_m;
    END IF;

    IF cur_num_pigs_weaning_f > 0 THEN 
        SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning_f;
    END IF;

    IF cur_num_pigs_weaning > 0 THEN 
        SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_weaning;
    END IF;
    
    IF cur_num_pigs_live_m > 0 THEN 
        SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_live_m;
    END IF;
    
    
    IF cur_num_pigs_live_f > 0 THEN 
        SET cur_num_pigs =  cur_num_pigs + cur_num_pigs_live_f;
    END IF;
    
    
    
    
    UPDATE sow_boar SET
        num_births = cur_count_births,
        num_pigs_wean = cur_num_pigs
    WHERE id = cur_pig_prod_sow_id;
   

END LOOP loop_here;
 
CLOSE c_pig_prod;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
