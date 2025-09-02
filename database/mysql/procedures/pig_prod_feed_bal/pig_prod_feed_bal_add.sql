DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_feed_bal_add $$
CREATE PROCEDURE pig_prod_feed_bal_add(
    in_user_id              INT,

    in_pig_prod_id          INT,
    
    in_date                 VARCHAR(10),
    
    in_num_lactating        DECIMAL(5,1),
    in_num_booster          INT,
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


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PROD_BUY_FEED      INT             DEFAULT 128;


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

DECLARE cur_pig_prod_num_b_lactating            INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_booster              INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_prestarter           INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_starter              INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_grower               INT             DEFAULT NULL;
DECLARE cur_pig_prod_num_b_finisher             INT             DEFAULT NULL;

DECLARE cur_pig_prod_num_l_lactating            DECIMAL(5,1)    DEFAULT NULL;
DECLARE cur_pig_prod_num_l_booster              DECIMAL(5,1)    DEFAULT NULL;
DECLARE cur_pig_prod_num_l_prestarter           DECIMAL(5,1)    DEFAULT NULL;
DECLARE cur_pig_prod_num_l_starter              DECIMAL(5,1)    DEFAULT NULL;
DECLARE cur_pig_prod_num_l_grower               DECIMAL(5,1)    DEFAULT NULL;
DECLARE cur_pig_prod_num_l_finisher             DECIMAL(5,1)    DEFAULT NULL;

DECLARE cur_pig_prod_cost_lactating             DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_booster               DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_prestarter            DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_starter               DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_grower                DECIMAL(10,2)   DEFAULT NULL;
DECLARE cur_pig_prod_cost_finisher              DECIMAL(10,2)   DEFAULT NULL;
    



DECLARE cur_pig_prod_feed_bal_id                    INT             DEFAULT 0;
DECLARE cur_pig_prod_feed_bal_flag                  INT             DEFAULT 0;
DECLARE cur_pig_prod_feed_bal_name                  VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_pig_prod_account_id
FROM    pig_production
WHERE   id = in_pig_prod_id;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PROD_FEED_BAL,
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


/* Check for duplicate entry */
SELECT  id
INTO    cur_pig_prod_feed_bal_id
FROM    pig_prod_feed_bal
WHERE   pig_prod_id         = in_pig_prod_id    AND
        date                = in_date           AND
        feed_type_id        =in_feed_type_id
LIMIT   1;

IF cur_pig_prod_feed_bal_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


SELECT
    status_id,

    num_b_lactating,
    num_b_booster,
    num_b_prestarter,
    num_b_starter,
    num_b_grower,
    num_b_finisher,
    num_l_lactating,
    num_l_booster,
    num_l_prestarter,
    num_l_starter,
    num_l_grower,
    num_l_finisher,
    cost_lactating,
    cost_booster,
    cost_prestarter,
    cost_starter,
    cost_grower,
    cost_finisher
    
INTO
    cur_pig_prod_status_id,

    cur_pig_prod_num_b_lactating,
    cur_pig_prod_num_b_booster,
    cur_pig_prod_num_b_prestarter,
    cur_pig_prod_num_b_starter,
    cur_pig_prod_num_b_grower,
    cur_pig_prod_num_b_finisher,
    
    cur_pig_prod_num_l_lactating,
    cur_pig_prod_num_l_booster,
    cur_pig_prod_num_l_prestarter,
    cur_pig_prod_num_l_starter,
    cur_pig_prod_num_l_grower,
    cur_pig_prod_num_l_finisher,
    
    cur_pig_prod_cost_lactating,
    cur_pig_prod_cost_booster,
    cur_pig_prod_cost_prestarter,
    cur_pig_prod_cost_starter,
    cur_pig_prod_cost_grower,
    cur_pig_prod_cost_finisher
    
FROM pig_production
WHERE id = in_pig_prod_id;
  



INSERT INTO pig_prod_feed_bal(
    pig_prod_id,
    
    date,
    
    num_lactating,
    num_booster,
    num_prestarter,
    num_starter,
    num_grower,
    num_finisher,

    added_by_user_id
) VALUES (
    in_pig_prod_id,
    
    in_date,
    
    in_num_lactating,
    in_num_booster,
    in_num_prestarter,
    in_num_starter,
    in_num_grower,
    in_num_finisher,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_pig_prod_feed_bal_id;



UPDATE pig_production SET
    num_l_lactating     = in_num_lactating,
    num_l_booster       = in_num_booster,
    num_l_prestarter    = in_num_prestarter,
    num_l_starter       = in_num_starter,
    num_l_grower        = in_num_grower,
    num_l_finisher      = in_num_finisher,
    
    date_last_feed_balance = CURRENT_DATE
WHERE id = in_pig_prod_id;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_feed_bal_id            AS pig_prod_feed_bal_id;

END $$

DELIMITER ;
