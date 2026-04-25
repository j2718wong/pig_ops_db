DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_head_count_per_farm $$
CREATE PROCEDURE sow_boar_head_count_per_farm(
    in_pig_farm_id              INT,
    
    OUT count_sow               INT,
    OUT count_boar              INT,
    OUT count_gilt              INT
)  

BEGIN

/** 
 * Will count sow/boar/git per farm.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since April 21, 2026
 *
 */
SET count_sow       = 0;
SET count_boar      = 0;
SET count_gilt      = 0;


SELECT  COUNT(*)
INTO    count_sow 
FROM    sow_boar
WHERE   pig_farm_id = in_pig_farm_id AND
        sex = 'F' AND is_disposed = 0 AND is_production_ready > 0;


SELECT  COUNT(*)
INTO    count_boar 
FROM    sow_boar
WHERE   pig_farm_id = in_pig_farm_id AND
        sex = 'M' AND is_disposed = 0;


SELECT  COUNT(*)
INTO    count_gilt 
FROM    sow_boar
WHERE   pig_farm_id = in_pig_farm_id AND
        sex = 'F' AND is_disposed = 0 AND is_production_ready = 0;





END $$

DELIMITER ;
