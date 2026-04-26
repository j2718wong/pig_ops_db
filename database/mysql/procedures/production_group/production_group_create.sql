DELIMITER $$

DROP PROCEDURE IF EXISTS production_group_create $$
CREATE PROCEDURE production_group_create(
    in_user_id              INT,

    in_pig_prod_id          INT, /*initial pig_production in the production_group*/
    
    in_date_added           VARCHAR(10)
)  

BEGIN

/** 
 * Will add production_group entry. A production group is formed
 * when a pig_production entry is converted to a production group and more 
 * pig_production entries are added into the production group. This is usually 
 * done in the pig farm to conserve pig pen.
 *
 * 1.) A production group is saved in pig_production table just like a normal 
 * pig_production entry. The only difference is a production group has   
 * (flag & FLAG_BIT_IS_A_GROUP) > 0;
 *
 * 2.) Therefore all data attributes of a production entry applies to a  
 *  production group.
 * 
 * 3.) The pig_production.date_actual_birth of a production group will be 
 *  populated by oldest batch in the group; This is necessary to calculate 
 *  the age of the pigs to estimate when is the target harvest date of the group.
 *
 * 4.) All individual pig_production in a production group, will be updated to 
 *   status PRODUCTION_STATUS_ID_COMBINED and the individual entries will not  
 *   be returned anymore in Fattening list. The pig_production.production_group_id 
 *   will also be populated by the production group id;
 *
 * 5.) In a production_group, there is no breeding information. But will have
 *  date_actual_birth
 *  num_pigs_weaning 
 * 
 * 6.) The pig_production.num_pigs_weaning will have a different meaning if
 *   the entry is a production group;  This is a computed number, not a counted 
 *   number anymore: the sum of all pig_production.num_pigs_current at the time 
 *   a production entry is added into the group.
 *
 * 7.) The pig_production.num_pigs_current will behave the same as a normal
 *  production entry. So this is computed as
 
    num_pigs_current = pig_production.num_pigs_weaning 
                        - SUM(dead_pigs in the group) 
                        - SUM (harvested_pigs in the group) 
  
 * 8.) The production group is just another fattening entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since April 6, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_ALREADY_IN_GROUP                INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_COMBINE_TO_GROUP         INT             DEFAULT 21;


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


/* pig_production.flag bits*/
/* Normally pig_production cannot be deleted. However if piglets are bought from
outside, and manually entered into the production list, the user can delete it.*/
DECLARE FLAG_BIT_PIG_PROD_IS_DELETED            INT             DEFAULT 1;

DECLARE FLAG_BIT_IS_A_GROUP                     INT             DEFAULT 2;
DECLARE FLAG_BIT_EXTERNAL_PIGLETS               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_pig_prod_production_group_id        INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;
DECLARE cur_pig_prod_date_actual_birth          DATE            DEFAULT NULL;
DECLARE cur_pig_prod_num_pigs_current           INT             DEFAULT 0; 

DECLARE cur_pig_prod_num_b_gestating            INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_lactating            INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_booster              INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_prestarter           INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_starter              INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_grower               INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_finisher             INT             DEFAULT NULL;
                                                
DECLARE cur_pig_prod_num_b_kg_gestating         INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_kg_lactating         INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_kg_booster           INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_kg_prestarter        INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_kg_starter           INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_kg_grower            INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_kg_finisher          INT             DEFAULT NULL;
                    
DECLARE cur_pig_prod_cost_gestating             DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_lactating             DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_booster               DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_prestarter            DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_starter               DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_grower                DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_finisher              DECIMAL(10,2)   DEFAULT NULL;


DECLARE cur_pig_farm_last_pig_production_id     INT             DEFAULT 0;

DECLARE cur_production_group_id                 INT             DEFAULT 0;

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
        
        production_group_id,
        prod_status_id,
        date_actual_birth,
        num_pigs_current,
        
        num_b_gestating,    
        num_b_lactating,    
        num_b_booster,      
        num_b_prestarter,   
        num_b_starter,      
        num_b_grower,       
        num_b_finisher,     
                           
        num_b_kg_gestating, 
        num_b_kg_lactating, 
        num_b_kg_booster,   
        num_b_kg_prestarter,
        num_b_kg_starter,   
        num_b_kg_grower,    
        num_b_kg_finisher,  
                           
        cost_gestating,     
        cost_lactating,     
        cost_booster,       
        cost_prestarter,    
        cost_starter,       
        cost_grower,        
        cost_finisher      

INTO    cur_pig_prod_account_id,
        cur_pig_prod_pig_farm_id,
        
        cur_pig_prod_production_group_id,
        cur_pig_prod_status_id,
        cur_pig_prod_date_actual_birth,
        cur_pig_prod_num_pigs_current,
        
        cur_pig_prod_num_b_gestating,    
        cur_pig_prod_num_b_lactating,    
        cur_pig_prod_num_b_booster,      
        cur_pig_prod_num_b_prestarter,   
        cur_pig_prod_num_b_starter,      
        cur_pig_prod_num_b_grower,       
        cur_pig_prod_num_b_finisher,     
                          
        cur_pig_prod_num_b_kg_gestating, 
        cur_pig_prod_num_b_kg_lactating, 
        cur_pig_prod_num_b_kg_booster,   
        cur_pig_prod_num_b_kg_prestarter,
        cur_pig_prod_num_b_kg_starter,   
        cur_pig_prod_num_b_kg_grower,    
        cur_pig_prod_num_b_kg_finisher,  
                           
        cur_pig_prod_cost_gestating,     
        cur_pig_prod_cost_lactating,     
        cur_pig_prod_cost_booster,       
        cur_pig_prod_cost_prestarter,    
        cur_pig_prod_cost_starter,       
        cur_pig_prod_cost_grower,        
        cur_pig_prod_cost_finisher

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


/* check pig_prod if already in group*/
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


/* Get pig_farm.last_pig_production_id*/
SELECT  last_pig_production_id
INTO    cur_pig_farm_last_pig_production_id
FROM    pig_farm
WHERE   id = cur_pig_prod_pig_farm_id;

SET cur_pig_farm_last_pig_production_id = cur_pig_farm_last_pig_production_id + 1;



/** Create production group; The already bought feeds from production entry,
needs to be copied to production_group.*/
INSERT INTO pig_production(
    account_id,
    pig_farm_id,
    farm_prod_id,
    
    prod_status_id,
    
    flag,
    
    date_actual_birth,
    num_pigs_weaning,
    num_pigs_current,
    
    num_b_gestating,    
    num_b_lactating,    
    num_b_booster,      
    num_b_prestarter,   
    num_b_starter,      
    num_b_grower,       
    num_b_finisher,     
                       
    num_b_kg_gestating, 
    num_b_kg_lactating, 
    num_b_kg_booster,   
    num_b_kg_prestarter,
    num_b_kg_starter,   
    num_b_kg_grower,    
    num_b_kg_finisher,  
                       
    cost_gestating,     
    cost_lactating,     
    cost_booster,       
    cost_prestarter,    
    cost_starter,       
    cost_grower,        
    cost_finisher      

)
VALUES(
    cur_pig_prod_account_id,
    cur_pig_prod_pig_farm_id,
    cur_pig_farm_last_pig_production_id,
    
    PRODUCTION_STATUS_ID_GROWING,
    
    FLAG_BIT_IS_A_GROUP,
    
    cur_pig_prod_date_actual_birth,
    cur_pig_prod_num_pigs_current,
    cur_pig_prod_num_pigs_current,
    
    cur_pig_prod_num_b_gestating,    
    cur_pig_prod_num_b_lactating,    
    cur_pig_prod_num_b_booster,      
    cur_pig_prod_num_b_prestarter,   
    cur_pig_prod_num_b_starter,      
    cur_pig_prod_num_b_grower,       
    cur_pig_prod_num_b_finisher,     
                      
    cur_pig_prod_num_b_kg_gestating, 
    cur_pig_prod_num_b_kg_lactating, 
    cur_pig_prod_num_b_kg_booster,   
    cur_pig_prod_num_b_kg_prestarter,
    cur_pig_prod_num_b_kg_starter,   
    cur_pig_prod_num_b_kg_grower,    
    cur_pig_prod_num_b_kg_finisher,  
                       
    cur_pig_prod_cost_gestating,     
    cur_pig_prod_cost_lactating,     
    cur_pig_prod_cost_booster,       
    cur_pig_prod_cost_prestarter,    
    cur_pig_prod_cost_starter,       
    cur_pig_prod_cost_grower,        
    cur_pig_prod_cost_finisher
);
SELECT LAST_INSERT_ID() INTO cur_production_group_id;


/* Update pig_production*/
UPDATE pig_production SET 
    prod_status_id          = PRODUCTION_STATUS_ID_COMBINED,
    
    production_group_id     = cur_production_group_id, 
    
    date_added_to_group     = in_date_added,
    added_to_group_by_id    = in_user_id,
    
    data_ver_num_pig_prod   = data_ver_num_pig_prod + 1,
    last_update_user_id     = in_user_id,  
    dt_last_update          = CURRENT_TIMESTAMP
WHERE id = in_pig_prod_id;


/* Update pig_farm*/
UPDATE pig_farm SET
    last_pig_production_id  = cur_pig_farm_last_pig_production_id,
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
SET s_temp = CONCAT(s_temp, '; Group PID = ', cur_pig_farm_last_pig_production_id);

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



SET s_temp = CONCAT('SYS: New production group; added by ', cur_user_name_first, ' ', cur_user_name_last);
SET s_temp = CONCAT(s_temp, '; Group PID = ', cur_pig_farm_last_pig_production_id);

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
    cur_production_group_id,
    s_temp,
    
    in_user_id,
    in_date_added
);


END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_production_group_id             AS production_group_id;

END $$

DELIMITER ;
