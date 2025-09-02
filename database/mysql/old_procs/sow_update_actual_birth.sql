DELIMITER $$

DROP PROCEDURE IF EXISTS sow_update_actual_birth_date $$
CREATE PROCEDURE sow_update_actual_birth_date(
    in_insemination_id          INT,
    
    in_date_actual_birth        VARCHAR(10),  /* in YYYY-MM-DD format*/
    in_num_piglets_dead         INT,
    in_num_piglets_live_male    INT,
    in_num_piglets_live_female  INT
)  

BEGIN

/** 
 * Will update sow actual birth date.
 * 
 * @author Jack Wong (neoaspilet11@gmail.com, zhaoshan99@gmail.com) 
 * @since January 5, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;

DECLARE COMING_ACT_ID_AFTER_BIRTH               INT             DEFAULT 8;
DECLARE COMING_ACT_ID_SOW_PROCESSING            INT             DEFAULT 9;
DECLARE COMING_ACT_ID_PIGLET_PROCESSING         INT             DEFAULT 10;
DECLARE COMING_ACT_ID_PIGLET_VITAMINS           INT             DEFAULT 11;
DECLARE COMING_ACT_ID_PIGLET_IRON_2             INT             DEFAULT 12;
DECLARE COMING_ACT_ID_WEANING                   INT             DEFAULT 13;


DECLARE INS_STATUS_ID_LACTATING                 INT             DEFAULT 4;

DECLARE NUM_DAYS_PIGLET_PROCESSING              INT             DEFAULT 3;
DECLARE NUM_DAYS_PIGLET_VITAMINS                INT             DEFAULT 7;
DECLARE NUM_DAYS_PIGLET_IRON_2                  INT             DEFAULT 14;
DECLARE NUM_DAYS_WEANING                        INT             DEFAULT 45;




DECLARE cur_sow_coming_act_id                   INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(180)    DEFAULT '';


SET res_num         = RES_NUM_SUCCESS;


UPDATE pig_production SET 
    date_actual_birth       = in_date_actual_birth,
    num_days_actual         = DATEDIFF(in_date_actual_birth, date_insemination),
    status_id               = INS_STATUS_ID_LACTATING,
    num_piglets_dead_at_birth = in_num_piglets_dead,
    num_piglets_live_male   = in_num_piglets_live_male,
    num_piglets_live_female = in_num_piglets_live_female
WHERE id = in_insemination_id;


UPDATE sow_coming_activity SET 
    date = DATE_ADD(in_date_actual_birth, INTERVAL 1 DAY),
    description = CONCAT("birth: ", in_date_actual_birth, "; + ", 1, 
        " days; 3.0 kg per day lactating")
WHERE insemination_id = in_insemination_id AND coming_activity_id = COMING_ACT_ID_AFTER_BIRTH;


UPDATE sow_coming_activity SET 
    date = DATE_ADD(in_date_actual_birth, INTERVAL 1 DAY),
    description = CONCAT("birth: ", in_date_actual_birth, "; + ", 1, 
        " days; 3.0 kg per day lactating")
WHERE insemination_id = in_insemination_id AND coming_activity_id = COMING_ACT_ID_SOW_PROCESSING;



UPDATE sow_coming_activity SET 
    date = DATE_ADD(in_date_actual_birth, INTERVAL NUM_DAYS_PIGLET_PROCESSING DAY),
    description = CONCAT("birth: ", in_date_actual_birth, "; + ", 
        NUM_DAYS_PIGLET_PROCESSING, " days; baktin kapon, pangil, ikog, bakuna, iron")
WHERE insemination_id = in_insemination_id AND coming_activity_id = COMING_ACT_ID_PIGLET_PROCESSING;


UPDATE sow_coming_activity SET 
    date = DATE_ADD(in_date_actual_birth, INTERVAL NUM_DAYS_PIGLET_VITAMINS DAY),
    description = CONCAT("birth: ", in_date_actual_birth, "; + ", 
        NUM_DAYS_PIGLET_VITAMINS, " days; inject baktin vitamins after 7 days")
WHERE insemination_id = in_insemination_id AND coming_activity_id = COMING_ACT_ID_PIGLET_VITAMINS;


UPDATE sow_coming_activity SET 
    date = DATE_ADD(in_date_actual_birth, INTERVAL NUM_DAYS_PIGLET_IRON_2 DAY),
    description = CONCAT("birth: ", in_date_actual_birth, "; + ", 
        NUM_DAYS_PIGLET_IRON_2, " days; inject baktin iron, after 14 days")
WHERE insemination_id = in_insemination_id AND coming_activity_id = COMING_ACT_ID_PIGLET_IRON_2;



UPDATE sow_coming_activity SET 
    date = DATE_ADD(in_date_actual_birth, INTERVAL NUM_DAYS_WEANING DAY),
    description = CONCAT("birth: ", in_date_actual_birth, "; + ", 
        NUM_DAYS_WEANING, " days")
WHERE insemination_id = in_insemination_id AND coming_activity_id = COMING_ACT_ID_WEANING;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code;
    

END $$

DELIMITER ;
