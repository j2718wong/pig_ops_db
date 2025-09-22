DELIMITER $$

DROP PROCEDURE IF EXISTS production_calculate_current_pigs $$
CREATE PROCEDURE production_calculate_current_pigs(
    in_pig_prod_id          INT,
    in_production_group_id  INT,
    
    OUT num_pigs            INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 19, 2025
 *
 */
 
 
DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;
DECLARE cur_num_pigs_added                      INT             DEFAULT 0;
DECLARE cur_num_pigs_harvest                    INT             DEFAULT 0;
DECLARE cur_num_dead_pigs                       INT             DEFAULT 0;
DECLARE cur_num_pigs_current                    INT             DEFAULT 0;



IF in_pig_prod_id > 0 THEN 
    /* This can be NULL if the pigs are brought externally*/
    SELECT  num_pigs_weaning_m + num_pigs_weaning_f
    INTO    cur_num_pigs_weaning
    FROM    pig_production 
    WHERE   id = in_pig_prod_id;
    
    
    /* This can be NULL.*/
    SELECT  SUM(num_pigs_added)
    INTO    cur_num_pigs_added
    FROM    pig_prod_pig_add
    WHERE   pig_prod_id = in_pig_prod_id;
    
    
    /* This can be NULL*/
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    production_harvest
    WHERE   pig_prod_id = in_pig_prod_id;
    
    
    /* This can be NULL.*/
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   pig_prod_id = in_pig_prod_id AND dead_at_stage = DEAD_AT_STAGE_GROWING;

ELSE
    /*  Get of all weaning pigs in the group*/
    /* This can be NULL if the pigs are brought externally*/
    SELECT  SUM(b.num_pigs_weaning_m + b.num_pigs_weaning_f)
    INTO    cur_num_pigs_weaning
    FROM    production_group_pig_prod a 
    LEFT OUTER JOIN pig_production b ON a.pig_prod_id = b.id 
    WHERE a.production_group_id = in_production_group_id;


    /* This can be NULL*/
    SELECT  SUM(num_pigs_added)
    INTO    cur_num_pigs_added
    FROM    pig_prod_pig_add 
    WHERE   production_group_id = in_production_group_id;


    /* This can be NULL*/
    SELECT  SUM(num_pigs_harvest)
    INTO    cur_num_pigs_harvest
    FROM    production_harvest
    WHERE   production_group_id = in_production_group_id;


    /* This can be NULL.*/
    SELECT  SUM(num_pigs_dead)
    INTO    cur_num_dead_pigs
    FROM    pig_prod_pig_dead
    WHERE   production_group_id = in_production_group_id AND dead_at_stage = DEAD_AT_STAGE_GROWING;

END IF;
    

IF cur_num_pigs_weaning > 0 THEN 
    SET cur_num_pigs_current = cur_num_pigs_weaning;
END IF;

IF cur_num_pigs_added > 0 THEN 
    SET cur_num_pigs_current = cur_num_pigs_current + cur_num_pigs_added;
END IF;

IF cur_num_pigs_harvest > 0 THEN 
    SET cur_num_pigs_current = cur_num_pigs_current - cur_num_pigs_harvest;
END IF;
 
IF cur_num_dead_pigs > 0 THEN 
    SET cur_num_pigs_current = cur_num_pigs_current - cur_num_dead_pigs;
END IF;

SET num_pigs  = cur_num_pigs_current;

END $$

DELIMITER ;
