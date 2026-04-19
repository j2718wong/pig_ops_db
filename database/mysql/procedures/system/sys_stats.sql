DELIMITER $$

DROP PROCEDURE IF EXISTS sys_stats $$
CREATE PROCEDURE sys_stats()  

BEGIN

/** 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since April 19, 2025
 *
 */



/* user.flag bits*/
DECLARE FLAG_BIT_USER_IS_ACTIVE                 INT             DEFAULT 1;
DECLARE FLAG_BIT_USER_EMAIL_VERIFIED            INT             DEFAULT 2;
DECLARE FLAG_BIT_USER_MOBILE_NUM_VERIFIED       INT             DEFAULT 4;
DECLARE FLAG_BIT_USER_IS_DELETED                INT             DEFAULT 8;

DECLARE FLAG_BIT_USER_IS_ACCOUNT_ADMIN          INT             DEFAULT 16;

DECLARE FLAG_BIT_USER_IS_TEST_USER              INT             DEFAULT 128;


DECLARE cur_count_user                          INT             DEFAULT 0;
DECLARE cur_user_inc_account                    INT             DEFAULT 0;
DECLARE cur_count_account                       INT             DEFAULT 0;



/* Count total users excluding test user. */
SELECT  COUNT(*) 
INTO    cur_count_user
FROM    user
WHERE   flag & FLAG_BIT_USER_IS_TEST_USER = 0;


/* Count users who signed up but not created account or join an account. */
SELECT  COUNT(*) 
INTO    cur_user_inc_account
FROM    user
WHERE   account_id IS NULL;
   
   
/* Count total accounts.*/
SELECT  COUNT(*) 
INTO    cur_count_account
FROM    account;

SELECT  
    cur_count_user          AS count_user,
    cur_user_inc_account    AS user_inc_account,
    cur_count_account       AS count_account;


END $$

DELIMITER ;
