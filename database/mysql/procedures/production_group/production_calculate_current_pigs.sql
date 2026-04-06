DELIMITER $$

DROP PROCEDURE IF EXISTS production_calculate_current_pigs $$
CREATE PROCEDURE production_calculate_current_pigs(
    in_pig_prod_id          INT,
    in_production_group_id  INT, /* Not used anymore; since production_group is saved in pig_production*/
    
    OUT num_pigs            INT
)  

BEGIN

/** 
 * Will count number of pigs left in pig_production or production_group.
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 19, 2025
 *
 */

DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;

DECLARE DEAD_AT_STAGE_LACTATING                 INT             DEFAULT 1;
DECLARE DEAD_AT_STAGE_GROWING                   INT             DEFAULT 2;

DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;

DECLARE cur_num_pigs_at_birth                   INT             DEFAULT 0;
DECLARE cur_num_pigs_weaning                    INT             DEFAULT 0;
DECLARE cur_num_pigs_added                      INT             DEFAULT 0;
DECLARE cur_num_pigs_harvest                    INT             DEFAULT 0;
DECLARE cur_num_dead_pigs                       INT             DEFAULT 0;
DECLARE cur_num_pigs_current                    INT             DEFAULT 0;



IF in_pig_prod_id > 0 THEN 
    SELECT  prod_status_id
    INTO    cur_pig_prod_status_id
    FROM    pig_production
    WHERE   id = in_pig_prod_id;
    
    IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_LACTATING THEN 
        SELECT  num_pigs_live_m + num_pigs_live_f
        INTO    cur_num_pigs_at_birth
        FROM    pig_production 
        WHERE   id = in_pig_prod_id;

    ELSE
    
        /* This can be NULL if the pigs are brought externally*/
        SELECT  num_pigs_weaning_m + num_pigs_weaning_f
        INTO    cur_num_pigs_weaning
        FROM    pig_production 
        WHERE   id = in_pig_prod_id;
        
        IF cur_num_pigs_weaning IS NULL THEN 
            SELECT  num_pigs_weaning
            INTO    cur_num_pigs_weaning
            FROM    pig_production 
            WHERE   id = in_pig_prod_id;
        END IF;
        
    END IF;
    
    
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
    WHERE   pig_prod_id = in_pig_prod_id;

END IF;
    

IF cur_num_pigs_at_birth > 0 THEN 
    SET cur_num_pigs_current = cur_num_pigs_at_birth;
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
