DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_feed_bal_update $$
CREATE PROCEDURE pig_prod_feed_bal_update(
    in_user_id              INT,
    
    in_pig_prod_feed_bal_id INT,
    
    in_date_balance         VARCHAR(10),
    
    in_num_pigs             INT,
    
    in_num_lactating        DECIMAL(5,1),
    in_num_booster          DECIMAL(5,1),
    in_num_prestarter       DECIMAL(5,1),
    in_num_starter          DECIMAL(5,1),
    in_num_grower           DECIMAL(5,1),
    in_num_finisher         DECIMAL(5,1)
)  

BEGIN

/** 
 * Will add pig_prod_feed_bal entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 25, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_FEED_BAL       INT             DEFAULT 22


DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE FEED_TYPE_ID_GESTATING                  INT             DEFAULT 1;
DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;



DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;




DECLARE cur_pig_prod_feed_bal_id                INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        status

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status

    FROM pig_production 
    WHERE id = in_pig_prod_id;

ELSE
    SELECT 
        account_id,
        status

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status

    FROM pig_production_group 
    WHERE id = in_pig_prod_group_id;

END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_FEED_BAL,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


UPDATE pig_prod_feed_bal SET 
    date_balance        = in_date_balance,
    
    num_pigs            = in_num_pigs,
    
    num_l_lactating     = in_num_lactating,
    num_l_booster       = in_num_booster,
    num_l_prestarter    = in_num_prestarter,
    num_l_starter       = in_num_starter,
    num_l_grower        = in_num_grower,
    num_l_finisher      = in_num_finisher,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP

WHERE id = in_pig_prod_feed_bal_id;

SELECT LAST_INSERT_ID() INTO cur_pig_prod_feed_bal_id;



UPDATE pig_production SET
    last_feed_balance_id = cur_pig_prod_feed_bal_id
WHERE id = in_pig_prod_id;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_feed_bal_id            AS pig_prod_feed_bal_id;

END $$

DELIMITER ;
