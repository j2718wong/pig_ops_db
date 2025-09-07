DELIMITER $$

DROP PROCEDURE IF EXISTS feed_balance_add $$
CREATE PROCEDURE feed_balance_add(
    in_user_id              INT,
    
    in_pig_prod_id          INT,
    in_pig_prod_group_id    INT,
    
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
 * Will add feed_balance entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 25, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_ALREADY_CLOSED         INT             DEFAULT 20;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_FEED_BALANCE            INT             DEFAULT 18;


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


DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;

DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;




DECLARE cur_feed_balance_id                     INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_pig_prod_id > 0 THEN 
    SELECT 
        account_id,
        prod_status_id

    INTO
        cur_pig_prod_account_id,
        cur_pig_prod_status_id

    FROM pig_production 
    WHERE id = in_pig_prod_id;

ELSE
    IF in_prod_group_id > 0 THEN 
        SELECT 
            account_id,
            pig_prod_status_id

        INTO
            cur_pig_prod_account_id,
            cur_pig_prod_status_id

        FROM production_group 
        WHERE id = in_pig_prod_group_id;
 
    END IF;
    
END IF;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_pig_prod_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BALANCE,
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


IF cur_pig_prod_status_id = PRODUCTION_STATUS_ID_CLOSED THEN 
    SET res_num     = RES_NUM_PIG_PROD_ALREADY_CLOSED;
    SET res_code    = "RES_NUM_PIG_PROD_ALREADY_CLOSED";
    
    LEAVE process_user;
END IF;


/* Check for duplicate entry */
IF in_pig_prod_id > 0 THEN 
    SELECT  id
    INTO    cur_feed_balance_id
    FROM    feed_balance
    WHERE   pig_prod_id         = in_pig_prod_id    AND
            date_balance        = in_date_balance
    LIMIT   1;
    
ELSE
    
    IF in_prod_group_id > 0 THEN 
        SELECT  id
        INTO    cur_feed_balance_id
        FROM    feed_balance
        WHERE   pig_prod_group_id   = in_pig_prod_group_id    AND
                date_balance        = in_date_balance
        LIMIT   1;
    END IF;
    
END IF;

IF cur_feed_balance_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* Need to do a data input correction check
1.) When this procedure is called from user, it will be like this
CALL feed_balance_add(1,7,NULL, '2025-08-16', 11, 0, 0, 0,    9,    0, 0);

The zero feed_numbers are already consumed. Users will not differentiate zero 
feeds and null feeds.

Any new feed_buy will be computed as consumed
when doing feed_balance calculation. 

2.) Need to convert zero inputs after non-zero to NULL.
CALL feed_balance_add(1,7,NULL, '2025-08-16', 11, 0, 0, 0,    9,    NULL, NULL);

*/

/* Compute consumption*/




INSERT INTO feed_balance(
    pig_prod_id,
    pig_prod_group_id,
    
    date_balance,
    
    num_pigs,
    
    num_lactating,
    num_booster,
    num_prestarter,
    num_starter,
    num_grower,
    num_finisher,

    added_by_user_id
) VALUES (
    in_pig_prod_id,
    in_pig_prod_group_id,
    
    in_date_balance,
    
    in_num_pigs,
    
    in_num_lactating,
    in_num_booster,
    in_num_prestarter,
    in_num_starter,
    in_num_grower,
    in_num_finisher,

    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_balance_id;


IF in_pig_prod_id > 0 THEN 
    UPDATE pig_production SET
        last_feed_balance_id = cur_feed_balance_id
    WHERE id = in_pig_prod_id;
END IF;


END process_user;



SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_balance_id                 AS feed_balance_id;

END $$

DELIMITER ;
