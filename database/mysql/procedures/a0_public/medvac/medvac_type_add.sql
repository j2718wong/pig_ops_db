DELIMITER $$

DROP PROCEDURE IF EXISTS medvac_type_add $$
CREATE PROCEDURE medvac_type_add(
    in_user_id              INT,

    in_name                 VARCHAR(50)
)  

BEGIN

/** 
 * Will add medvac_type entry to the system.
 * 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 24, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;
DECLARE RES_NUM_CANNOT_ADD                      INT             DEFAULT 21;




/* medvac_type.flag bits*/
DECLARE FLAG_BIT_MEDVAC_TYPE_IS_DELETED     	INT             DEFAULT 1;
DECLARE FLAG_BIT_MEDVAC_TYPE_IS_VERIFIED       	INT             DEFAULT 2;


DECLARE MAX_UNVERIFIED_ENTRIES_PER_USER         INT             DEFAULT 2;
DECLARE MAX_DELETED_INVALID_ENTRIES_PER_USER    INT             DEFAULT 3;

DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;


DECLARE cur_medvac_type_id                   	INT             DEFAULT 0;
DECLARE cur_medvac_type_flag                 	INT             DEFAULT 0;
DECLARE cur_medvac_type_name                 	VARCHAR(50)     DEFAULT '';
	
DECLARE in_name_upper                         	VARCHAR(50)     DEFAULT '';

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
    
    0, /* public business object*/
    0,
    
    cur_user_account_id, 
    cur_user_group_id,
    res_num, 
    res_code, 
    res_desc);


process_user : BEGIN

IF res_num != RES_NUM_SUCCESS THEN 
    LEAVE process_user;
END IF;


/* All public object names are in UPPER case. Except address names.*/
SET in_name_upper = UPPER(in_name);



/* Check for duplicate entry */
SELECT  id
INTO    cur_medvac_type_id
FROM    medvac_type
WHERE   name                = in_name_upper
LIMIT   1;

IF cur_medvac_type_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;


/* medvac_type can be added by any user. To prevent abuse of entering
invalid medvac_type, unverified entries will be counted and 
deleted entries against the user will be counted.*/

SELECT  COUNT(*)
INTO    cur_count
FROM    medvac_type
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_MEDVAC_TYPE_IS_VERIFIED) = 0;

IF cur_count >= MAX_UNVERIFIED_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many unverified entries entered by user.";
    
    LEAVE process_user;

END IF;


SELECT  COUNT(*) 
INTO    cur_count
FROM    medvac_type
WHERE   added_by_user_id = in_user_id AND 
        (flag & FLAG_BIT_MEDVAC_TYPE_IS_DELETED) > 0;
        
IF cur_count >= MAX_DELETED_INVALID_ENTRIES_PER_USER THEN 
    SET res_num     = RES_NUM_CANNOT_ADD;
    SET res_code    = "RES_NUM_CANNOT_ADD";
    SET res_desc    = "Too many invalid entries entered by user.";
    
    LEAVE process_user;

END IF;
        

INSERT INTO medvac_type(
    name,
    added_by_user_id
    
) VALUES (
	in_name_upper,
	in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_medvac_type_id;


SET cur_count = 0;

/* Insert INTO account_selection*/
SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_user_account_id AND 
        medvac_type_id = cur_medvac_type_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        medvac_type_id
    ) VALUES (
        cur_user_account_id,
        cur_medvac_type_id
    );
END IF;



END process_user;


SELECT
    flag,
    name
INTO 
    cur_medvac_type_flag,
    cur_medvac_type_name
FROM medvac_type
WHERE id = cur_medvac_type_id;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_medvac_type_id                	AS medvac_type_id,
    cur_medvac_type_flag               	AS medvac_type_flag,
    cur_medvac_type_name               	AS medvac_type_name;

END $$

DELIMITER ;
