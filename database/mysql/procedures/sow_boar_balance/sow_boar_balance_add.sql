DELIMITER $$

DROP PROCEDURE IF EXISTS sow_boar_balance_add $$
CREATE PROCEDURE sow_boar_balance_add(
    in_user_id              INT,
    in_pig_farm_id          INT,
    
    in_date_balance         VARCHAR(10),
    
    in_num_gestating        DECIMAL(5,1),
    in_num_finisher         DECIMAL(5,1)
)  

BEGIN

/** 
 * Will sow_boar_balance entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 7, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_SOW_BOAR_BALANCE       	INT             DEFAULT 27;


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


DECLARE SOW_STATUS_ID_LACTATING                 INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_sows_total                          INT             DEFAULT 0;
DECLARE cur_boars_total                         INT             DEFAULT 0;
DECLARE cur_sows_lactating                      INT             DEFAULT 0;
DECLARE cur_sows_gestating                      INT             DEFAULT 0;



DECLARE cur_sow_boar_balance_id                INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";



SELECT  account_id
INTO    cur_pig_farm_account_id
FROM    pig_farm 
WHERE   id = in_pig_farm_id;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_farm_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SOW_BOAR_BALANCE,
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
INTO    cur_sow_boar_balance_id
FROM    sow_boar_balance
WHERE   pig_farm_id         = in_pig_farm_id    AND
        date_balance        = in_date_balance
LIMIT   1;
    


IF cur_sow_boar_balance_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/*
sow_boar.flag bits
DECLARE FLAG_BIT_SOW_BOAR_IS_DISPOSED           INT             DEFAULT 1;
DECLARE FLAG_BIT_SOW_BOAR_IS_EXTERNAL           INT             DEFAULT 2;

*/

/* Snap shot sows and boars*/
SELECT  COUNT(*)
INTO    cur_sows_total 
FROM    sow_boar 
WHERE   pig_farm_id = in_pig_farm_id AND sex = 'F' AND (flag & 3) = 0;

SELECT  COUNT(*)
INTO    cur_boars_total 
FROM    sow_boar 
WHERE   pig_farm_id = in_pig_farm_id AND sex = 'M' AND (flag & 3) = 0;


SELECT  COUNT(*)
INTO    cur_sows_lactating 
FROM    sow_boar 
WHERE   pig_farm_id = in_pig_farm_id AND sex = 'F' AND (flag & 3) = 0 AND 
        sow_status_id = SOW_STATUS_ID_LACTATING;

SET cur_sows_gestating  = cur_sows_total - cur_sows_lactating;


INSERT INTO sow_boar_balance(
    pig_farm_id,
    
    date_balance,
    
    num_sows,
    num_boars,
    num_sows_lactating,
    num_sows_gestating,
    
    num_gestating,   
    num_finisher,

    added_by_user_id
) VALUES (
    in_pig_farm_id,
    
    in_date_balance,
    
    cur_sows_total,
    cur_boars_total,
    cur_sows_lactating,
    cur_sows_gestating,
    
    in_num_gestating,
    in_num_finisher,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_sow_boar_balance_id;



UPDATE pig_farm SET
    last_sow_boar_balance_id = cur_sow_boar_balance_id
WHERE id = in_pig_farm_id;



END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_sow_boar_balance_id             AS sow_boar_balance_id;

END $$

DELIMITER ;
