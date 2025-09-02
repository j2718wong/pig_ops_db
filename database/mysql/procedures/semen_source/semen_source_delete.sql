DELIMITER $$

DROP PROCEDURE IF EXISTS semen_source_delete $$
CREATE PROCEDURE semen_source_delete(
    in_user_id              INT,
    
    in_semen_source_id      INT
)  

BEGIN

/** 
 * Will delete semen_source entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 18, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


/* semen_source.flag bits*/
DECLARE FLAG_BIT_SEMEN_SOURCE_IS_DELETED        INT             DEFAULT 1;

DECLARE BUSINESS_OBJ_ID_SEMEN_SOURCE            INT             DEFAULT 18;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_semen_source_id                     INT             DEFAULT 0;
DECLARE cur_semen_source_flag                   INT             DEFAULT 0;
DECLARE cur_semen_source_account_id             INT             DEFAULT 0;
DECLARE cur_semen_source_name                   VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';



SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  account_id
INTO    cur_semen_source_account_id
FROM    semen_source
WHERE   id = in_semen_source_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_semen_source_account_id,/* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_SEMEN_SOURCE,
    FLAG_BIT_OPERATION_DELETE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


UPDATE semen_source SET
    flag                = flag | FLAG_BIT_SEMEN_SOURCE_IS_DELETED,
    
    last_update_user_id = in_user_id,
    dt_last_update      = CURRENT_TIMESTAMP
WHERE id =  in_semen_source_id;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_semen_source_flag,
    cur_semen_source_name
FROM semen_source
WHERE id = in_semen_source_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    in_semen_source_id                  AS semen_source_id,
    cur_semen_source_flag               AS semen_source_flag,
    cur_semen_source_name               AS semen_source_name;
    

END $$

DELIMITER ;
