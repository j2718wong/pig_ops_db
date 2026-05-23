DELIMITER $$

DROP PROCEDURE IF EXISTS production_group_pig_prod_add $$
CREATE PROCEDURE production_group_pig_prod_add(
    in_user_id              INT,

    in_production_group_id  INT,
    in_pig_prod_id          INT,
    
    in_date_added           VARCHAR(10)
)  

BEGIN

/** 
 * Will add (combine) pig_production to existing production_group entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 23, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_ALREADY_IN_GROUP                INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_COMBINE_TO_GROUP         INT             DEFAULT 21;
DECLARE RES_NUM_INVALID_PRODUCTION_GROUP        INT             DEFAULT 22;
DECLARE RES_NUM_INVALID_PRODUCTION_GROUP_STATUS INT             DEFAULT 23;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;
DECLARE PRODUCTION_STATUS_ID_CULLED             INT             DEFAULT 10;



DECLARE FEED_TYPE_ID_GESTATING                  INT             DEFAULT 1;
DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;



/* pig_production.flag bits*/
/* Normally pig_production cannot be deleted. However if piglets are bought from
outside, and manually entered into the production list, the user can delete it.*/
DECLARE FLAG_BIT_PIG_PROD_IS_DELETED            INT             DEFAULT 1;

DECLARE FLAG_BIT_IS_A_GROUP                     INT             DEFAULT 2;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_farm_prod_id               INT             DEFAULT 0;

DECLARE cur_pig_prod_production_group_id        INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;
DECLARE cur_pig_prod_num_pigs_current           INT             DEFAULT 0; 


DECLARE cur_production_group_flag               INT             DEFAULT 0;
DECLARE cur_production_group_status_id          INT             DEFAULT 0;
DECLARE cur_production_group_farm_prod_id       INT             DEFAULT 0; 


DECLARE cur_count                               INT             DEFAULT 0; 
DECLARE cur_min_date_of_birth                   DATE            DEFAULT NULL;

DECLARE cur_num_pigs_current                    INT             DEFAULT 0; 


DECLARE sum_prod_num_b_gestating                INT             DEFAULT NULL;
DECLARE sum_prod_num_b_lactating                INT             DEFAULT NULL;    
DECLARE sum_prod_num_b_booster                  INT             DEFAULT NULL;      
DECLARE sum_prod_num_b_prestarter               INT             DEFAULT NULL;   
DECLARE sum_prod_num_b_starter                  INT             DEFAULT NULL;      
DECLARE sum_prod_num_b_grower                   INT             DEFAULT NULL;       
DECLARE sum_prod_num_b_finisher                 INT             DEFAULT NULL;
     
DECLARE sum_prod_num_b_kg_gestating             INT             DEFAULT NULL; 
DECLARE sum_prod_num_b_kg_lactating             INT             DEFAULT NULL; 
DECLARE sum_prod_num_b_kg_booster               INT             DEFAULT NULL;   
DECLARE sum_prod_num_b_kg_prestarter            INT             DEFAULT NULL;
DECLARE sum_prod_num_b_kg_starter               INT             DEFAULT NULL;   
DECLARE sum_prod_num_b_kg_grower                INT             DEFAULT NULL;    
DECLARE sum_prod_num_b_kg_finisher              INT             DEFAULT NULL;
     
DECLARE sum_prod_cost_gestating                 DECIMAL(10,2)   DEFAULT NULL;     
DECLARE sum_prod_cost_lactating                 DECIMAL(10,2)   DEFAULT NULL;        
DECLARE sum_prod_cost_booster                   DECIMAL(10,2)   DEFAULT NULL;       
DECLARE sum_prod_cost_prestarter                DECIMAL(10,2)   DEFAULT NULL;    
DECLARE sum_prod_cost_starter                   DECIMAL(10,2)   DEFAULT NULL;       
DECLARE sum_prod_cost_grower                    DECIMAL(10,2)   DEFAULT NULL;        
DECLARE sum_prod_cost_finisher                  DECIMAL(10,2)   DEFAULT NULL;
 

DECLARE cur_feed_quantity                       INT             DEFAULT 0;
DECLARE cur_feed_weight_kg                      DECIMAL(6,1)    DEFAULT NULL;
DECLARE cur_total_cost                          DECIMAL(8,2)    DEFAULT NULL;


DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT NULL;
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT NULL;

DECLARE s_temp                                  VARCHAR(180)    DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id,
        pig_farm_id,
        farm_prod_id,
        
        production_group_id,
        prod_status_id,
        date_actual_birth,
        num_pigs_current

INTO    cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        cur_pig_prod_farm_prod_id,
        
        cur_pig_prod_production_group_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_actual_birth,
        cur_pig_prod_num_pigs_current

FROM    pig_production

WHERE   id = in_pig_prod_id;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
    FLAG_BIT_OPERATION_ADD,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;



/* Check pig_prod if already in group*/
IF cur_pig_prod_production_group_id IS NOT NULL THEN 
    SET res_num     = RES_NUM_ALREADY_IN_GROUP;
    SET res_code    = "RES_NUM_ALREADY_IN_GROUP";
    
    LEAVE process_user;
END IF;


/* check pig_prod status*/
IF cur_pig_prod_status_id NOT IN (PRODUCTION_STATUS_ID_WEANING,
                                  PRODUCTION_STATUS_ID_GROWING) THEN 
    SET res_num     = RES_NUM_CANNOT_COMBINE_TO_GROUP;
    SET res_code    = "RES_NUM_CANNOT_COMBINE_TO_GROUP";
    
    LEAVE process_user;
                                  
END IF;


/* check production_group status*/
SELECT  flag,
        prod_status_id,
        farm_prod_id

INTO    cur_production_group_flag,
        cur_production_group_status_id,
        cur_production_group_farm_prod_id

FROM    pig_production
WHERE   id = in_production_group_id;


/* Check if in_production_group_id is really a group*/
IF cur_production_group_flag & FLAG_BIT_IS_A_GROUP = 0 THEN 
    SET res_num     = RES_NUM_INVALID_PRODUCTION_GROUP;
    SET res_code    = "RES_NUM_INVALID_PRODUCTION_GROUP";
    
    LEAVE process_user;
END IF;


IF cur_production_group_status_id != PRODUCTION_STATUS_ID_GROWING THEN
    SET res_num     = RES_NUM_INVALID_PRODUCTION_GROUP_STATUS;
    SET res_code    = "RES_NUM_INVALID_PRODUCTION_GROUP_STATUS";
    
    LEAVE process_user;
END IF;


/* Update pig_production*/
UPDATE pig_production SET 
    prod_status_id          = PRODUCTION_STATUS_ID_COMBINED,
    
    production_group_id     = in_production_group_id, 
    
    date_added_to_group     = in_date_added,
    added_to_group_by_id    = in_user_id,
    
    data_ver_num_pig_prod   = data_ver_num_pig_prod + 1,
    last_update_user_id     = in_user_id,  
    dt_last_update          = CURRENT_TIMESTAMP
WHERE id = in_pig_prod_id;


/* Update pig_farm*/
UPDATE pig_farm SET
    data_ver_num_pig_prod   = data_ver_num_pig_prod + 1
WHERE id = cur_pig_prod_pig_farm_id;


/* Create prod_notes to both pig_production and production group*/

SELECT  name_first,
        name_last

INTO    cur_user_name_first,
        cur_user_name_last

FROM    user
WHERE   id = in_user_id;

SET s_temp = CONCAT('SYS: combined to group by ', cur_user_name_first, ' ', cur_user_name_last);
SET s_temp = CONCAT(s_temp, '; Group PID = ', cur_production_group_farm_prod_id);

INSERT INTO pig_prod_notes(
    account_id,
    pig_farm_id,
    pig_prod_id,
    notes,
    
    added_by_user_id,
    date_notes
) VALUES(
    cur_pig_prod_account_id,
    cur_pig_prod_pig_farm_id,
    in_pig_prod_id,
    s_temp,
    
    in_user_id,
    in_date_added
);



SET s_temp = CONCAT('SYS: Added to group; added by ', cur_user_name_first, ' ', cur_user_name_last);
SET s_temp = CONCAT(s_temp, '; pig_prod PID = ', cur_pig_prod_farm_prod_id);

INSERT INTO pig_prod_notes(
    account_id,
    pig_farm_id,
    pig_prod_id,
    notes,
    
    added_by_user_id,
    date_notes
) VALUES(
    cur_pig_prod_account_id,
    cur_pig_prod_pig_farm_id,
    in_production_group_id,
    s_temp,
    
    in_user_id,
    in_date_added
);


/* Update production_group.num_pigs_weaning
 
 * From production_group_create docs
 *
 * 6.) The pig_production.num_pigs_weaning will have a different meaning if
 *   the entry is a production group;  This is a computed number, not a counted 
 *   number anymore: the sum of all pig_production.num_pigs_current at the time 
 *   a production entry is added into the group.

*/

SELECT  SUM(num_pigs_current)
INTO    cur_count
FROM    pig_production
WHERE   pig_farm_id         = cur_pig_prod_pig_farm_id AND
        production_group_id = in_production_group_id;

SELECT  date_actual_birth
INTO    cur_min_date_of_birth
FROM    pig_production
WHERE   pig_farm_id         = cur_pig_prod_pig_farm_id AND
        production_group_id = in_production_group_id    AND
        date_actual_birth   IS NOT NULL
ORDER BY date_actual_birth ASC
LIMIT   1;


/* Need to update this first, as this is needed in next step.*/
UPDATE pig_production SET
    num_pigs_weaning  = cur_count
WHERE id = in_production_group_id;


/* Compute current total pigs in the production_group*/
CALL production_calculate_current_pigs(in_production_group_id, 0, cur_num_pigs_current);


/* Add all feeds already bought for individual production_entries + the feeds bought
for the production group; This is because the production group will need also
accurate feed cost calculation
*/

/* Individual pig_prod; The individual pig_prod entries are already freezed; 
cannot change data anymore, so the bought feeds information is final.*/
SELECT
    SUM(num_b_gestating),
    SUM(num_b_lactating),          
    SUM(num_b_booster),            
    SUM(num_b_prestarter),         
    SUM(num_b_starter),            
    SUM(num_b_grower),             
    SUM(num_b_finisher),
            
    SUM(num_b_kg_gestating),       
    SUM(num_b_kg_lactating),       
    SUM(num_b_kg_booster),         
    SUM(num_b_kg_prestarter),      
    SUM(num_b_kg_starter),         
    SUM(num_b_kg_grower),          
    SUM(num_b_kg_finisher),
            
    SUM(cost_gestating),           
    SUM(cost_lactating),           
    SUM(cost_booster),             
    SUM(cost_prestarter),          
    SUM(cost_starter),             
    SUM(cost_grower),              
    SUM(cost_finisher)

INTO 
    sum_prod_num_b_gestating,
    sum_prod_num_b_lactating,    
    sum_prod_num_b_booster,      
    sum_prod_num_b_prestarter,   
    sum_prod_num_b_starter,      
    sum_prod_num_b_grower,       
    sum_prod_num_b_finisher,
        
    sum_prod_num_b_kg_gestating, 
    sum_prod_num_b_kg_lactating, 
    sum_prod_num_b_kg_booster,   
    sum_prod_num_b_kg_prestarter,
    sum_prod_num_b_kg_starter,   
    sum_prod_num_b_kg_grower,    
    sum_prod_num_b_kg_finisher,
        
    sum_prod_cost_gestating,     
    sum_prod_cost_lactating,     
    sum_prod_cost_booster,       
    sum_prod_cost_prestarter,    
    sum_prod_cost_starter,       
    sum_prod_cost_grower,        
    sum_prod_cost_finisher
    
FROM    pig_production
WHERE   pig_farm_id         = cur_pig_prod_pig_farm_id AND
        production_group_id = in_production_group_id;

        

/** Sum up all feeds bought related to production_group_id;
Note production_group feeds start at prestarter or starter

*/

SET cur_feed_quantity   = NULL;
SET cur_feed_weight_kg  = NULL;
SET cur_total_cost      = NULL;

SELECT  SUM(quantity),
        SUM(kg_total),
        SUM(total_cost)
        
INTO    cur_feed_quantity,
        cur_feed_weight_kg,
        cur_total_cost
FROM    feed_buy
WHERE   pig_prod_id = in_production_group_id AND feed_type_id = FEED_TYPE_ID_PRESTARTER;

        
SET sum_prod_num_b_prestarter    = IFNULL(sum_prod_num_b_prestarter, 0)       + IFNULL(cur_feed_quantity, 0);
SET sum_prod_num_b_kg_prestarter = IFNULL(sum_prod_num_b_kg_prestarter, 0)    + IFNULL(cur_feed_weight_kg, 0);      
SET sum_prod_cost_prestarter     = IFNULL(sum_prod_cost_prestarter, 0)        + IFNULL(cur_total_cost, 0);      



SET cur_feed_quantity   = NULL;
SET cur_feed_weight_kg  = NULL;
SET cur_total_cost      = NULL;

SELECT  SUM(quantity),
        SUM(kg_total),
        SUM(total_cost)
        
INTO    cur_feed_quantity,
        cur_feed_weight_kg,
        cur_total_cost
FROM    feed_buy
WHERE   pig_prod_id = in_production_group_id AND feed_type_id = FEED_TYPE_ID_STARTER;

        
SET sum_prod_num_b_starter    = IFNULL(sum_prod_num_b_starter, 0)       + IFNULL(cur_feed_quantity, 0);
SET sum_prod_num_b_kg_starter = IFNULL(sum_prod_num_b_kg_starter, 0)    + IFNULL(cur_feed_weight_kg, 0);      
SET sum_prod_cost_starter     = IFNULL(sum_prod_cost_starter, 0)        + IFNULL(cur_total_cost, 0);      


SET cur_feed_quantity   = NULL;
SET cur_feed_weight_kg  = NULL;
SET cur_total_cost      = NULL;

SELECT  SUM(quantity),
        SUM(kg_total),
        SUM(total_cost)
        
INTO    cur_feed_quantity,
        cur_feed_weight_kg,
        cur_total_cost
FROM    feed_buy
WHERE   pig_prod_id = in_production_group_id AND feed_type_id = FEED_TYPE_ID_GROWER;

        
SET sum_prod_num_b_grower    = IFNULL(sum_prod_num_b_grower, 0)       + IFNULL(cur_feed_quantity, 0);
SET sum_prod_num_b_kg_grower = IFNULL(sum_prod_num_b_kg_grower, 0)    + IFNULL(cur_feed_weight_kg, 0);      
SET sum_prod_cost_grower     = IFNULL(sum_prod_cost_grower, 0)        + IFNULL(cur_total_cost, 0);      



SET cur_feed_quantity   = NULL;
SET cur_feed_weight_kg  = NULL;
SET cur_total_cost      = NULL;

SELECT  SUM(quantity),
        SUM(kg_total),
        SUM(total_cost)
        
INTO    cur_feed_quantity,
        cur_feed_weight_kg,
        cur_total_cost
FROM    feed_buy
WHERE   pig_prod_id = in_production_group_id AND feed_type_id = FEED_TYPE_ID_FINISHER;

        
SET sum_prod_num_b_finisher    = IFNULL(sum_prod_num_b_finisher, 0)       + IFNULL(cur_feed_quantity, 0);
SET sum_prod_num_b_kg_finisher = IFNULL(sum_prod_num_b_kg_finisher, 0)    + IFNULL(cur_feed_weight_kg, 0);      
SET sum_prod_cost_finisher     = IFNULL(sum_prod_cost_finisher, 0)        + IFNULL(cur_total_cost, 0);      




/* Update production group*/
UPDATE pig_production SET
    num_pigs_weaning    = cur_count,   
    num_pigs_current    = cur_num_pigs_current,
    
    num_b_gestating     = sum_prod_num_b_gestating,
    num_b_lactating     = sum_prod_num_b_lactating,    
    num_b_booster       = sum_prod_num_b_booster,      
    num_b_prestarter    = sum_prod_num_b_prestarter,   
    num_b_starter       = sum_prod_num_b_starter,      
    num_b_grower        = sum_prod_num_b_grower,       
    num_b_finisher      = sum_prod_num_b_finisher,
                        
    num_b_kg_gestating  = sum_prod_num_b_kg_gestating, 
    num_b_kg_lactating  = sum_prod_num_b_kg_lactating, 
    num_b_kg_booster    = sum_prod_num_b_kg_booster,   
    num_b_kg_prestarter = sum_prod_num_b_kg_prestarter,
    num_b_kg_starter    = sum_prod_num_b_kg_starter,   
    num_b_kg_grower     = sum_prod_num_b_kg_grower,    
    num_b_kg_finisher   = sum_prod_num_b_kg_finisher,
                        
    cost_gestating      = sum_prod_cost_gestating,     
    cost_lactating      = sum_prod_cost_lactating,     
    cost_booster        = sum_prod_cost_booster,       
    cost_prestarter     = sum_prod_cost_prestarter,    
    cost_starter        = sum_prod_cost_starter,       
    cost_grower         = sum_prod_cost_grower,        
    cost_finisher       = sum_prod_cost_finisher,
    
    data_ver_num_pig_prod = data_ver_num_pig_prod + 1
    
WHERE id = in_production_group_id;


/* Update pig_farm; The pig_prod entry becomes a prod_history after added into a group.*/
UPDATE pig_farm SET
    data_ver_num_pig_prod       = data_ver_num_pig_prod + 1,
    data_ver_num_prod_fatten    = data_ver_num_prod_fatten + 1,
    data_ver_num_prod_history   = data_ver_num_prod_history+ 1
WHERE id = cur_pig_prod_pig_farm_id;


END process_user;


SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_production_group_id              AS production_group_id;

END $$

DELIMITER ;
