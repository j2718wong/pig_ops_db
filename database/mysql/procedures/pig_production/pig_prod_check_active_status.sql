DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_check_active_status $$
CREATE PROCEDURE pig_prod_check_active_status(
    in_prod_status_id           INT,
    

    OUT out_is_active           INT
    
)

BEGIN

/** 
 * Will check if pig_production.pig_prod_status is active.
 * @author Jack Wong
 * @since January 18, 2026
 *
 */
 

DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;

SET out_is_active = 0;

IF in_prod_status_id IN (   PRODUCTION_STATUS_ID_GESTATING,
                            PRODUCTION_STATUS_ID_LACTATING,
                            PRODUCTION_STATUS_ID_GROWING,
                            PRODUCTION_STATUS_ID_WEANING) THEN 
    
    SET out_is_active = 1;
    
END IF;

END $$

DELIMITER ;
