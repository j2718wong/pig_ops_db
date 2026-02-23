DELIMITER $$

DROP PROCEDURE IF EXISTS feed_balance_update_feed_buy $$
CREATE PROCEDURE feed_balance_update_feed_buy()  

BEGIN

/** 
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since February 18, 2026
 *
 */

DECLARE FEED_TYPE_ID_GESTATING                  INT             DEFAULT 1;
DECLARE FEED_TYPE_ID_LACTATING                  INT             DEFAULT 2;
DECLARE FEED_TYPE_ID_BOOSTER                    INT             DEFAULT 3;
DECLARE FEED_TYPE_ID_PRESTARTER                 INT             DEFAULT 4;
DECLARE FEED_TYPE_ID_STARTER                    INT             DEFAULT 5;
DECLARE FEED_TYPE_ID_GROWER                     INT             DEFAULT 6;
DECLARE FEED_TYPE_ID_FINISHER                   INT             DEFAULT 7;



DECLARE cur_feed_balance_id                     INT             DEFAULT 0;
DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_feed_balance_date_balance           DATE;


DECLARE cur_feed_buy_gestating                  INT             DEFAULT 0;
DECLARE cur_feed_buy_lactating                  INT             DEFAULT 0;
DECLARE cur_feed_buy_booster                    INT             DEFAULT 0;
DECLARE cur_feed_buy_prestarter                 INT             DEFAULT 0;
DECLARE cur_feed_buy_starter                    INT             DEFAULT 0;
DECLARE cur_feed_buy_grower                     INT             DEFAULT 0;
DECLARE cur_feed_buy_finisher                   INT             DEFAULT 0;
    


DECLARE l_last_row_fetched TINYINT;
DECLARE c_feed_balance CURSOR FOR
    SELECT  id,
            pig_prod_id,
            date_balance
    FROM    feed_balance; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 

    
SET l_last_row_fetched=0;
OPEN c_feed_balance;   
    

loop_here: LOOP
    FETCH c_feed_balance INTO 
        cur_feed_balance_id,
        cur_pig_prod_id,
        cur_feed_balance_date_balance;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    
   
    /*
    Count all feed_buy before and on this cur_feed_balance_date_balance
    for every feed_type.
    */



    SELECT  SUM(quantity)
    INTO    cur_feed_buy_gestating
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_GESTATING AND
            date_buy <= cur_feed_balance_date_balance;

    SELECT  SUM(quantity)
    INTO    cur_feed_buy_lactating
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_LACTATING AND
            date_buy <= cur_feed_balance_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_booster
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_BOOSTER AND
            date_buy <= cur_feed_balance_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_prestarter
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_PRESTARTER AND
            date_buy <= cur_feed_balance_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_starter
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_STARTER AND
            date_buy <= cur_feed_balance_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_grower
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_GROWER AND
            date_buy <= cur_feed_balance_date_balance;


    SELECT  SUM(quantity)
    INTO    cur_feed_buy_finisher
    FROM    feed_buy
    WHERE   pig_prod_id = cur_pig_prod_id AND
            feed_type_id = FEED_TYPE_ID_FINISHER AND
            date_buy <= cur_feed_balance_date_balance;

    
    UPDATE feed_balance SET 
        num_b_gestating     = cur_feed_buy_gestating,
        num_b_lactating     = cur_feed_buy_lactating,
        num_b_booster       = cur_feed_buy_booster,
        num_b_prestarter    = cur_feed_buy_prestarter,
        num_b_starter       = cur_feed_buy_starter,
        num_b_grower        = cur_feed_buy_grower,
        num_b_finisher      = cur_feed_buy_finisher
    WHERE id = cur_feed_balance_id;
    

END LOOP loop_here;
 
CLOSE c_feed_balance;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
