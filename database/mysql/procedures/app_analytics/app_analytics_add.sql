DELIMITER $$

DROP PROCEDURE IF EXISTS app_analytics_add $$
CREATE PROCEDURE app_analytics_add(
    in_user_id              INT,

    in_app_function_id      INT
)  

BEGIN

/** 
 * Will add app_analytics entry to the system.
 * This is not a user initiated request but for system usage.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since September 10, 2025
 *
 */

SELECT  account_id
INTO    cur_user_account_id
FROM    user
WHERE   id = in_user_id;

INSERT INTO app_analytics(
    account_id,
    user_id,
    app_function_id
    date_usage
) VALUES (
    cur_user_account_id,
    in_user_id,
    in_app_function_id,
    CURRENT_DATE
);

END $$

SELECT 1;

DELIMITER ;
