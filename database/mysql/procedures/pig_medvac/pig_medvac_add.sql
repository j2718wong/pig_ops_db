DELIMITER $$

DROP PROCEDURE IF EXISTS pig_medvac_add $$
CREATE PROCEDURE pig_medvac_add(
    in_user_id              INT,
    

    in_sow_boar_id          INT,
    in_pig_prod_id          INT,
    in_pig_prod_pig_ops_id  INT,
    in_health_issue_id      INT,
    
    in_date_medvac          VARCHAR(10),
    in_medvac_brand_id      INT,
    in_medvac_type_id       INT,
    in_acc_medvac_id        INT,
    
    in_staff_id             INT,
    in_done_by_user         INT,
    in_notes                VARCHAR(160)
)  

BEGIN

/** 
 * Will add medvac entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since January 8, 2026
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_MEDVAC  INT          DEFAULT 20;
DECLARE RES_NUM_DISPOSED_SOW_BOAR_CANNOT_ADD_MEDVAC INT         DEFAULT 21;
DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 22;


DECLARE BUSINESS_OBJ_ID_FEED_BUY                INT             DEFAULT 17;


DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;
DECLARE PRODUCTION_STATUS_ID_CLOSED             INT             DEFAULT 9;




DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


/* medvac_brand.flag bits*/
DECLARE FLAG_BIT_MEDVAC_BRAND_IS_DELETED        INT             DEFAULT 1;
DECLARE FLAG_BIT_MEDVAC_BRAND_IS_VERIFIED       INT             DEFAULT 2;


/* medvac_type.flag bits*/
DECLARE FLAG_BIT_MEDVAC_TYPE_IS_DELETED          INT            DEFAULT 1;
DECLARE FLAG_BIT_MEDVAC_TYPE_IS_VERIFIED         INT            DEFAULT 2;



DECLARE MIN_COUNT_MEDVAC_BRAND_IS_VERIFIED      INT             DEFAULT 3;
DECLARE MIN_COUNT_MEDVAC_TYPE_IS_VERIFIED       INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';



DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_is_disposed                INT             DEFAULT 0;


DECLARE cur_pig_prod_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_prod_status_id                  INT             DEFAULT 0;


DECLARE cur_medvac_id                           INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;
DECLARE cur_count                               INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


IF in_sow_boar_id > 0 THEN 
    SELECT  account_id,
            pig_farm_id,
            is_disposed
            
    INTO    cur_sow_boar_account_id,
            cur_sow_boar_pig_farm_id,
            cur_sow_boar_is_disposed
    
    FROM    sow_boar
    WHERE   id = in_sow_boar_id;
ELSE
    SELECT  account_id,
            pig_farm_id
            
    INTO    cur_sow_boar_account_id,
            cur_sow_boar_pig_farm_id
            
    FROM    pig_production
    WHERE   id = in_pig_prod_id;

END IF;



CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_FEED_BUY, /* TODO */
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


/* Check pig_production status*/
IF in_pig_prod_id > 0 THEN
    IF cur_pig_prod_status_id IN (  PRODUCTION_STATUS_ID_TERMINATED,
                                    PRODUCTION_STATUS_ID_NOT_PREGNANT,
                                    PRODUCTION_STATUS_ID_HARVESTED,
                                    PRODUCTION_STATUS_ID_CLOSED) THEN 
        SET res_num     = RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_MEDVAC;
        SET res_code    = "RES_NUM_PIG_PROD_STATUS_CANNOT_ADD_MEDVAC";
        
        LEAVE process_user;
    END IF;
END IF;


/* Check sow_boar status*/
IF in_sow_boar_id > 0 THEN 
    IF cur_sow_boar_is_disposed > 0 THEN 
        SET res_num     = RES_NUM_DISPOSED_SOW_BOAR_CANNOT_ADD_MEDVAC;
        SET res_code    = "RES_NUM_DISPOSED_SOW_BOAR_CANNOT_ADD_MEDVAC";
        
        LEAVE process_user;
    END IF;
    
END IF;




/* Check for duplicate entry */
IF in_sow_boar_id > 0 THEN
    SELECT  id
    INTO    cur_medvac_id
    FROM    pig_medvac
    WHERE   sow_boar_id = in_sow_boar_id        AND
            date_medvac = in_date_medvac        AND 
            medvac_brand_id = in_medvac_brand_id AND
            medvac_type_id = in_medvac_type_id  AND
            acc_medvac_id = in_acc_medvac_id
    LIMIT   1;
ELSE
    SELECT  id
    INTO    cur_medvac_id
    FROM    pig_medvac
    WHERE   pig_prod_id = in_pig_prod_id AND
            date_medvac = in_date_medvac AND 
            medvac_brand_id = in_medvac_brand_id AND
            medvac_type_id = in_medvac_type_id  AND
            acc_medvac_id = in_acc_medvac_id
    LIMIT   1;

END IF;


IF cur_medvac_id > 0 THEN 
    SET res_num     = RES_NUM_DUPLICATE_ENTRY;
    SET res_code    = "RES_NUM_DUPLICATE_ENTRY";
    
    LEAVE process_user;
END IF;



/* If done by user, user will be added to staff list.
Note: not all staff are users
*/
IF in_done_by_user > 0 THEN
    SELECT  pig_farm_staff_id,
            name_first,
            name_last
    
    INTO    cur_user_staff_id,
            cur_user_name_first,
            cur_user_name_last
    FROM    user 
    WHERE   id = in_user_id;
    
    
    IF cur_user_staff_id = 0 THEN 
        INSERT INTO pig_farm_staff (
            account_id,
            pig_farm_id,
            user_id,
            name,
            
            added_by_user_id
        ) VALUES (
            cur_sow_boar_account_id,
            cur_sow_boar_pig_farm_id,
            in_user_id,
            CONCAT(cur_user_name_first, ' ', cur_user_name_last),
            
            in_user_id
        );
        SELECT LAST_INSERT_ID() INTO cur_user_staff_id;
        
        
        UPDATE user SET 
            pig_farm_staff_id = cur_user_staff_id
        WHERE id = in_user_id;
        
    END IF;
    
    
    SET in_staff_id = cur_user_staff_id;
    
END IF;



INSERT INTO pig_medvac(
    
    account_id,
    
    sow_boar_id,
    pig_prod_id,
    
    pig_prod_pig_ops_id,
    health_issue_id,
    
    date_medvac,
    medvac_type_id,
    medvac_brand_id,
    acc_medvac_id,
    
    
    notes,
    
    staff_id,
    
    added_by_user_id

) VALUES (
    cur_sow_boar_account_id,

    in_sow_boar_id,
    in_pig_prod_id,
    
    in_pig_prod_pig_ops_id,
    in_health_issue_id,
    
    
    in_date_medvac,
    in_medvac_type_id,
    in_medvac_brand_id,
    in_acc_medvac_id,
    

    in_notes,
    
    in_staff_id,
    
    in_user_id
);

SELECT LAST_INSERT_ID() INTO cur_medvac_id;


IF in_health_issue_id > 0 THEN 
    UPDATE pig_prod_notes SET 
        last_pig_medvac_id = cur_medvac_id
    WHERE id = in_health_issue_id;
END IF;



/* Insert INTO account_selection*/
SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_sow_boar_account_id AND 
        medvac_brand_id = in_medvac_brand_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        medvac_brand_id
    ) VALUES (
        cur_sow_boar_account_id,
        in_medvac_brand_id
    );
END IF;


/* Update medvac_brand counter. */
SELECT  COUNT(*)
INTO    cur_count
FROM    account_selection
WHERE   medvac_brand_id = in_medvac_brand_id;

UPDATE  medvac_brand SET
    account_counter = cur_count
WHERE id = in_medvac_brand_id;


/* Update feed_brand.flag.FLAG_BIT_MEDVAC_BRAND_IS_VERIFIED*/
IF cur_count >= MIN_COUNT_MEDVAC_BRAND_IS_VERIFIED THEN 
    UPDATE medvac_brand SET
        flag = flag | FLAG_BIT_MEDVAC_BRAND_IS_VERIFIED
    WHERE id = in_medvac_brand_id;

END IF;



SELECT  COUNT(*) 
INTO    cur_count
FROM    account_selection
WHERE   account_id =  cur_sow_boar_account_id AND 
        medvac_type_id = in_medvac_type_id;
        

IF cur_count = 0 THEN 
    INSERT INTO account_selection(
        account_id,
        medvac_type_id
    ) VALUES (
        cur_sow_boar_account_id,
        in_medvac_type_id
    );
END IF;


/* Update medvac_type counter. */
SELECT  COUNT(*)
INTO    cur_count
FROM    account_selection
WHERE   medvac_type_id = in_medvac_type_id;

UPDATE  medvac_type SET
    account_counter = cur_count
WHERE id = in_medvac_type_id;


/* Update feed_brand.flag.MIN_COUNT_MEDVAC_TYPE_IS_VERIFIED*/
IF cur_count >= MIN_COUNT_MEDVAC_TYPE_IS_VERIFIED THEN 
    UPDATE medvac_type SET
        flag = flag | MIN_COUNT_MEDVAC_TYPE_IS_VERIFIED
    WHERE id = in_medvac_type_id;

END IF;






END process_user;




SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_medvac_id                       AS medvac_id;

END $$

DELIMITER ;