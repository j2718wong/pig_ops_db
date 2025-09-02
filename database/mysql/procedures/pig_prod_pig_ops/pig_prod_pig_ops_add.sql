DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_pig_ops_add $$
CREATE PROCEDURE pig_prod_pig_ops_add(
    in_user_id              INT,
    
    in_account_id           INT,
    in_operation_type       INT,
    in_pig_prod_id          INT,
    in_date_reference       VARCHAR(10)
)  

BEGIN

/** 
 * A sub procedure to create pig_prod_pig_ops entries.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 30, 2025
 *
 */
 
DECLARE cur_account_pig_ops_id                  INT             DEFAULT 0;
DECLARE cur_account_pig_ops_num_days            INT             DEFAULT 0;


DECLARE l_last_row_fetched TINYINT;
DECLARE c_account_pig_ops CURSOR FOR
    SELECT  id,
            num_days_since
    FROM    account_pig_ops
    WHERE   account_id = in_account_id      AND 
            operation_type = in_operation_type AND 
            (flag & 1) = 0
    ORDER BY num_days_since ASC; 

DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_last_row_fetched=1; 


    
SET l_last_row_fetched=0;
OPEN c_account_pig_ops;   
    

loop_here: LOOP
    FETCH c_account_pig_ops INTO 
        cur_account_pig_ops_id,
        cur_account_pig_ops_num_days;
        
    IF l_last_row_fetched=1 THEN LEAVE loop_here; END IF;

    INSERT INTO pig_prod_pig_ops(
        pig_prod_id,
        account_pig_ops_id,
        operation_type,
        date_target
    ) VALUES (
        in_pig_prod_id,
        cur_account_pig_ops_id,
        in_operation_type,
        DATE_ADD(in_date_reference, INTERVAL cur_account_pig_ops_num_days DAY)
    );
    

END LOOP loop_here;
 
CLOSE c_account_pig_ops;
SET l_last_row_fetched=0;   

END $$

DELIMITER ;
