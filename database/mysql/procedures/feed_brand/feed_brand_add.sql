DELIMITER $$

DROP PROCEDURE IF EXISTS feed_brand_add $$
CREATE PROCEDURE feed_brand_add(
    in_user_id              INT,

    in_country_id           INT,
    
    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will add feed_brand entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_FEED_BRAND              INT             DEFAULT 15;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* feed_brand.flag bits*/
DECLARE FLAG_BIT_FEED_BRAND_IS_DELETED          INT             DEFAULT 1;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_feed_brand_id                       INT             DEFAULT 0;
DECLARE cur_feed_brand_flag                     INT             DEFAULT 0;
DECLARE cur_feed_brand_name                     VARCHAR(50)     DEFAULT '';


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_FEED_BRAND,
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
INTO    cur_feed_brand_id
FROM    feed_brand
WHERE   country_id          = in_country_id   AND
        UPPER(name)         = UPPER(in_name)
LIMIT   1;

IF cur_feed_brand_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



INSERT INTO feed_brand(
    country_id,
    
    name,
    added_by_user_id
    
) VALUES (
   in_country_id,
  
   in_name,
   in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_feed_brand_id;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_feed_brand_flag,
    cur_feed_brand_name
FROM feed_brand
WHERE id = cur_feed_brand_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_feed_brand_id               AS feed_brand_id,
    cur_feed_brand_flag             AS feed_brand_flag,
    cur_feed_brand_name             AS feed_brand_name;

END $$

DELIMITER ;
