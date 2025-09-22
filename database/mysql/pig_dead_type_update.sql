DELIMITER $$

DROP PROCEDURE IF EXISTS pig_dead_type_update $$
CREATE PROCEDURE pig_dead_type_update(
    in_user_id              INT,
	in_pig_dead_type_id		INT,
	
	in_translation_id		INT,

    in_language_id          INT,
    
    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will add pig_dead_type to the system. The business object pig_dead_type
 * has a02_look_up_translation entries. This can be translated to any supported
 * language_id.
 * 
 * 1.) The pig_dead_type is both system owned and account owned.
 * 
 * 2.) A system owned pig_dead_type is searchable by all accounts.
 *     The account_id for system owned pig_dead_type is zero.
 *
 * 3.) An account owned pig_dead_type is searchable by account users only.
 *
 * 4.) However an account owned pig_dead_type can be promoted to system owned
 * and cannot be updated or deleted by the account users. The original account_id
 * of a promoted pig_dead_type is retained; not converted to zero.
 *
 * 5.) The idea is let to the users define and update the pig_dead_type and its 
 *  translations. After it is valid and verified, it becomes system owned and 
 *  cannot be updated except for additional translations. 
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD                      INT             DEFAULT 21;


DECLARE BUSINESS_OBJ_ID_PIG_DEAD_TYPE           INT             DEFAULT 28;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* pig_dead_type.flag bits*/
DECLARE FLAG_BIT_PIG_DEAD_TYPE_IS_DELETED       INT             DEFAULT 1;
DECLARE FLAG_BIT_PIG_DEAD_TYPE_IS_VERIFIED      INT             DEFAULT 2;

DECLARE FLAG_BIT_PIG_DEAD_TYPE_IS_SYSTEM_OWNED  INT             DEFAULT 4;
DECLARE FLAG_BIT_PIG_DEAD_TYPE_NAME_IS_TEMPORARY INT            DEFAULT 8;


DECLARE MAX_UNVERIFIED_ENTRIES_PER_USER         INT             DEFAULT 3;
DECLARE MAX_DELETED_INVALID_ENTRIES_PER_USER    INT             DEFAULT 3;


DECLARE LANGUAGE_ID_ENGLISH                     INT             DEFAULT 1;
DECLARE LANGUAGE_ID_TAGALOG                     INT             DEFAULT 2;
DECLARE LANGUAGE_ID_BISAYA                      INT             DEFAULT 3;





DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_pig_dead_type_id                    INT             DEFAULT 0;
DECLARE cur_pig_dead_type_flag                  INT             DEFAULT 0;
DECLARE cur_pig_dead_type_name                  VARCHAR(50)     DEFAULT '';

DECLARE normalized_name                         VARCHAR(50)     DEFAULT '';

DECLARE cur_count                               INT             DEFAULT 0;

DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    0,
    
    BUSINESS_OBJ_ID_PIG_DEAD_TYPE,
    FLAG_BIT_OPERATION_UPDATE,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* Check abuse usage*/
SELECT  COUNT(*)
INTO    cur_count
FROM    pig_dead_type
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_PIG_DEAD_TYPE_IS_VERIFIED) = 0;

IF cur_count >= MAX_UNVERIFIED_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many unverified entries entered by user.";
    
    LEAVE process_user;

END IF;


SELECT  COUNT(*) 
INTO    cur_count
FROM    pig_dead_type
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_PIG_DEAD_TYPE_IS_DELETED) > 0;
        
IF cur_count >= MAX_DELETED_INVALID_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many invalid entries entered by user.";
    
    LEAVE process_user;

END IF;
        
        
IF in_language_id = LANGUAGE_ID_ENGLISH THEN 
	SELECT 	flag,
			account_id 
			
	INTO 	cur_pig_dead_type_flag
			cur_pig_dead_type_account_id
			
	FROM 	pig_dead_type
	WHERE 	id = in_pig_dead_type_id;
	

  
    
ELSE
    INSERT INTO pig_dead_type(
        account_id,
        flag,
        
        name,
        added_by_user_id
        
    ) VALUES (
        cur_user_account_id,
        FLAG_BIT_PIG_DEAD_TYPE_NAME_IS_TEMPORARY,
        
        in_name,
        in_user_id
    ); 
    SELECT LAST_INSERT_ID() INTO cur_pig_dead_type_id;
    
    
    INSERT INTO a02_look_up_translation VALUES(
        business_object_id,
        table_row_id
        account_id,
        language_id,
        translated_text
    ) VALUES (  
        BUSINESS_OBJ_ID_PIG_DEAD_TYPE,
        cur_pig_dead_type_id,
        cur_user_account_id,
        in_language_id, 
        in_name
    );
    
    
END IF;


END process_user;


SELECT
    flag,
    name
INTO 
    cur_pig_dead_type_flag,
    cur_pig_dead_type_name
FROM pig_dead_type
WHERE id = cur_pig_dead_type_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_dead_type_id                AS pig_dead_type_id,
    cur_pig_dead_type_flag              AS pig_dead_type_flag,
    cur_pig_dead_type_name              AS pig_dead_type_name;

END $$

DELIMITER ;
