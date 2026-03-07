DELIMITER $$

DROP PROCEDURE IF EXISTS user_request_add_farms_to_user $$
CREATE PROCEDURE user_request_add_farms_to_user(
    in_account_id           INT,
    in_requesting_user_id   INT,
    in_approving_user_id    INT
)  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since March 7, 2026
 *
 */

DECLARE cur_pig_farm_id                         INT             DEFAULT 0;

DECLARE cur_count                               INT             DEFAULT 0;



DECLARE l_last_row_fetched TINYINT;
DECLARE c_pig_farm CURSOR FOR
    SELECT  id
    FROM    pig_farm
    WHERE   account_id      = in_account_id 
    ORDER BY id ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 




    
SET l_last_row_fetched=0;
OPEN c_pig_farm;   
    

loop_here: LOOP
    FETCH c_pig_farm INTO 
        cur_pig_farm_id;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    SET cur_count = 0;

    SELECT  COUNT(*)
    INTO    cur_count
    FROM    user_pig_farm
    WHERE   pig_farm_id = cur_pig_farm_id AND user_id = in_requesting_user_id;
    
    
    IF cur_count = 0 THEN 

        INSERT INTO user_pig_farm(
            pig_farm_id,
            user_id,
            added_by_user_id
        ) VALUES (
            cur_pig_farm_id,
            in_requesting_user_id,
            in_approving_user_id
        );
    END IF;

END LOOP loop_here;
 
CLOSE c_pig_farm;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
