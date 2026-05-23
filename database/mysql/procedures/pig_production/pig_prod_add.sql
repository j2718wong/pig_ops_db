DELIMITER $$

DROP PROCEDURE IF EXISTS pig_prod_add $$
CREATE PROCEDURE pig_prod_add(
    in_user_id              INT,
   
    in_sow_id               INT,    /* Cannot be updated*/
    in_boar_id              INT,
    in_semen_supplier_id    INT,
    in_semen_sup_semen_id   INT,    /* semen supplier semen_id*/
    in_semen_ai_boar_id     INT,    /* semen coming from one of farm's boar*/
    
    in_semen_cost           DECIMAL(6,2),
    in_insemination_cost    DECIMAL(6,2),
    in_comments             VARCHAR(160),
    
    in_insem_staff_id       INT,
    in_done_by_user         INT, 
    
    in_date_insemination    VARCHAR(10)  /* in YYYY-MM-DD format*/
)  

BEGIN

/** 
 * Will create pig_production entry.
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since August 17, 2025
 *
 */

DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE RES_NUM_DUPLICATE_ENTRY                 INT             DEFAULT 20;


DECLARE BUSINESS_OBJ_ID_PIG_PRODUCTION          INT             DEFAULT 21;

DECLARE FLAG_BIT_OPERATION_ADD                  INT             DEFAULT 1;
DECLARE FLAG_BIT_OPERATION_UPDATE               INT             DEFAULT 2;
DECLARE FLAG_BIT_OPERATION_DELETE               INT             DEFAULT 4;


DECLARE INSEMINATION_TYPE_BOAR                  VARCHAR(2)      DEFAULT 'B';
DECLARE INSEMINATION_TYPE_ARTIFICIAL_EXTERNAL   VARCHAR(4)      DEFAULT 'AI_X';
DECLARE INSEMINATION_TYPE_ARTIFICIAL_INTERNAL   VARCHAR(4)      DEFAULT 'AI_N';


/* common_supplier.flag bits*/
DECLARE FLAG_BIT_SUPPLIER_IS_DELETED            INT             DEFAULT 1;
DECLARE FLAG_BIT_SUPPLIER_IS_VERIFIED           INT             DEFAULT 2;


/* semen_supplier_semen.flag bits*/
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_DELETED  INT             DEFAULT 1;
DECLARE FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED INT             DEFAULT 2;




DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;

DECLARE SOW_STATUS_ID_GESTATING                 INT             DEFAULT 2;


DECLARE PIG_OPERATION_TYPE_GESTATING            INT             DEFAULT 1;
DECLARE PIG_OPERATION_TYPE_LACTATING_PIGLETS    INT             DEFAULT 2;
DECLARE PIG_OPERATION_TYPE_LACTATING_SOW        INT             DEFAULT 3;
DECLARE PIG_OPERATION_TYPE_GILT_OPS             INT             DEFAULT 4;
DECLARE PIG_OPERATION_TYPE_WEANING_SOW_OPS      INT             DEFAULT 5;


/* Date insemination is day 0.*/
DECLARE PIG_NUM_DAYS_GESTATION                  INT             DEFAULT 114;


DECLARE MIN_COUNT_SUPPLIER_IS_VERIFIED          INT             DEFAULT 3;
DECLARE MIN_COUNT_SEMEN_IS_VERIFIED             INT             DEFAULT 3;


DECLARE cur_user_account_id                     INT             DEFAULT 0;
DECLARE cur_user_group_id                       INT             DEFAULT 0;
DECLARE cur_user_staff_id                       INT             DEFAULT 0;
DECLARE cur_user_name_first                     VARCHAR(50)     DEFAULT '';
DECLARE cur_user_name_last                      VARCHAR(50)     DEFAULT '';


DECLARE cur_sow_boar_account_id                 INT             DEFAULT 0;
DECLARE cur_sow_boar_pig_farm_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_farm_sow_id                INT             DEFAULT 0;
DECLARE cur_sow_boar_last_prod_id               INT             DEFAULT 0;
DECLARE cur_sow_boar_last_prod_status_id        INT             DEFAULT 0;


DECLARE cur_insemination_type                   VARCHAR(4)      DEFAULT '';


DECLARE cur_pig_farm_last_pig_production_id     INT             DEFAULT 0;


DECLARE cur_pig_prod_id                         INT             DEFAULT 0;
DECLARE cur_pig_prod_ai_id                      INT             DEFAULT 0;

DECLARE cur_pig_prod_notes_id                   INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;
DECLARE cur_count_semen_sup_semen_usage         INT             DEFAULT 0;
DECLARE cur_count_semen_sup_semen_account       INT             DEFAULT 0;
DECLARE cur_flag_bit                            INT             DEFAULT 0;


DECLARE res_num                                 INT             DEFAULT 0;
DECLARE res_code                                VARCHAR(80)     DEFAULT '';
DECLARE res_desc                                VARCHAR(180)    DEFAULT '';


SET res_num     = RES_NUM_SUCCESS;
SET res_code    = "SUCCESS";


SELECT  a.account_id,
        a.pig_farm_id,
        a.farm_sow_id,
        a.last_pig_production_id,
        b.prod_status_id
        
INTO    cur_sow_boar_account_id,
        cur_sow_boar_pig_farm_id,
        cur_sow_boar_farm_sow_id,
        cur_sow_boar_last_prod_id,
        cur_sow_boar_last_prod_status_id
FROM    sow_boar a
LEFT OUTER JOIN pig_production b ON a.last_pig_production_id = b.id
WHERE   a.id = in_sow_id
LIMIT   1;


CALL basic_user_check(
    in_user_id, 
    1, /* user must have an account*/
    cur_sow_boar_account_id, /* compare user.account_id to this account_id*/
    
    BUSINESS_OBJ_ID_PIG_PRODUCTION,
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
INTO    cur_pig_prod_id
FROM    pig_production
WHERE   pig_farm_id         = cur_sow_boar_pig_farm_id AND
        sow_id              = in_sow_id     AND 
        date_insemination   = in_date_insemination 
LIMIT   1;


IF cur_pig_prod_id > 0 THEN
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
            cur_pig_prod_account_id,
            cur_pig_prod_pig_farm_id,
            in_user_id,
            CONCAT(cur_user_name_first, ' ', cur_user_name_last),
            
            in_user_id
        );
        SELECT LAST_INSERT_ID() INTO cur_user_staff_id;
        
        
        UPDATE pig_farm SET 
            data_ver_num_staff = data_ver_num_staff + 1
        WHERE id = cur_sow_boar_pig_farm_id;
        
        
        UPDATE user SET 
            pig_farm_staff_id = cur_user_staff_id
        WHERE id = in_user_id;
        
    END IF;
    
    
    SET in_insem_staff_id = cur_user_staff_id;
    
END IF;





/* Set previous pig_production of this sow to not pregnant, if status is gestating*/
UPDATE pig_production SET 
    prod_status_id = PRODUCTION_STATUS_ID_NOT_PREGNANT
WHERE sow_id = in_sow_id AND prod_status_id = PRODUCTION_STATUS_ID_GESTATING;


/* Update pig_farm.data_ver_num_not_pregnant*/
IF cur_sow_boar_last_prod_status_id = PRODUCTION_STATUS_ID_GESTATING THEN 
    UPDATE pig_farm SET 
        data_ver_num_not_pregnant =  data_ver_num_not_pregnant + 1
    WHERE id = cur_sow_boar_pig_farm_id;
END IF;


SELECT  last_pig_production_id
INTO    cur_pig_farm_last_pig_production_id
FROM    pig_farm
WHERE   id = cur_sow_boar_pig_farm_id;

SET cur_pig_farm_last_pig_production_id = cur_pig_farm_last_pig_production_id + 1;

IF in_boar_id IS NOT NULL THEN 
    INSERT INTO pig_production (
        account_id,
        pig_farm_id,
        farm_prod_id,
        
        insemination_type,
        
        sow_id,
        boar_id,
        
        semen_cost,
        insemination_cost,
        
        date_insemination,
        date_expected_birth,
        
        prod_status_id,
        insem_staff_id
    ) VALUES (
        cur_user_account_id,
        cur_sow_boar_pig_farm_id,
        cur_pig_farm_last_pig_production_id,
        
        INSEMINATION_TYPE_BOAR,
        
        in_sow_id,
        in_boar_id,
        
        NULL,
        in_insemination_cost,
        
        in_date_insemination,
        DATE_ADD(in_date_insemination, INTERVAL PIG_NUM_DAYS_GESTATION DAY),

        PRODUCTION_STATUS_ID_GESTATING,
        in_insem_staff_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;

    
    /* Insert to sow_boar_mate*/
    INSERT INTO sow_boar_mate(
        pig_prod_id,
        sow_boar_id,
        mate_sow_boar_id,
        date_mate,
        added_by_user_id
    ) 
    VALUES
    (
        cur_pig_prod_id,
        in_sow_id,
        in_boar_id,
        in_date_insemination,
        in_user_id
    ),
    
    (
        cur_pig_prod_id,
        in_boar_id,
        in_sow_id,
        in_date_insemination,
        in_user_id
    );



    /* Update sow_boar last mate*/
    UPDATE sow_boar SET
        last_pig_production_id  = cur_pig_prod_id,
        mate_count              = mate_count + 1,
        date_last_mate          = in_date_insemination,
        last_mate_sow_boar_id   = in_sow_id
    WHERE id = in_boar_id;

    UPDATE sow_boar SET
        last_pig_production_id  = cur_pig_prod_id,
        mate_count              = mate_count + 1,
        date_last_mate          = in_date_insemination,
        last_mate_sow_boar_id   = in_boar_id
    WHERE id = in_sow_id;


ELSE
    /* artificial insemination */
    
    /* Check if semen is coming from external supplier*/
    IF in_semen_sup_semen_id > 0 THEN 
        SET cur_insemination_type = INSEMINATION_TYPE_ARTIFICIAL_EXTERNAL;
    ELSE
        IF in_semen_ai_boar_id > 0 THEN 
            SET cur_insemination_type = INSEMINATION_TYPE_ARTIFICIAL_INTERNAL;
        END IF;
        
    END IF;
    
    
        
        
    
    INSERT INTO pig_production (
        account_id,
        pig_farm_id,
        farm_prod_id,
        
        insemination_type,
        
        sow_id,
        boar_id,
        
        semen_supplier_id,
        semen_sup_semen_id,
        semen_ai_boar_id,
        
        semen_cost,
        insemination_cost,
        
        date_insemination,
        date_expected_birth,
        
        prod_status_id,
        insem_staff_id
    ) VALUES (
        cur_user_account_id,
        cur_sow_boar_pig_farm_id,
        cur_pig_farm_last_pig_production_id,
        
        cur_insemination_type,
        
        in_sow_id,
        NULL,
        
        in_semen_supplier_id,
        in_semen_sup_semen_id,
        in_semen_ai_boar_id,
        
        in_semen_cost,
        in_insemination_cost,
        
        in_date_insemination,
        DATE_ADD(in_date_insemination, INTERVAL PIG_NUM_DAYS_GESTATION DAY),

        PRODUCTION_STATUS_ID_GESTATING,
        in_insem_staff_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_id;
    
    
    
    IF in_semen_supplier_id > 0 THEN 
    
        /* Insert account_id INTO account_selection.semen_supplier_id*/
        SELECT  COUNT(*) 
        INTO    cur_count
        FROM    account_selection
        WHERE   account_id =  cur_user_account_id AND 
                semen_supplier_id = in_semen_supplier_id;
                
        IF cur_count = 0 THEN 
            INSERT INTO account_selection(
                account_id,
                semen_supplier_id,
                added_by_user_id
            ) VALUES (
                cur_user_account_id,
                in_semen_supplier_id,
                in_user_id
            );
        END IF;
        
        
        /*Compute common_supplier.flag.FLAG_BIT_SUPPLIER_IS_VERIFIED*/
        SELECT  COUNT(*) 
        INTO    cur_count
        FROM    account_selection
        WHERE   (feed_supplier_id = in_semen_supplier_id OR
                semen_supplier_id = in_semen_supplier_id OR
                gilt_supplier_id  = in_semen_supplier_id) AND 
                
                account_id !=  cur_user_account_id;
                
        /* Update common_supplier.flag.FLAG_BIT_SUPPLIER_IS_VERIFIED*/
        IF cur_count >= MIN_COUNT_SUPPLIER_IS_VERIFIED THEN
            UPDATE common_supplier SET 
                flag = flag | FLAG_BIT_SUPPLIER_IS_VERIFIED
            WHERE id = in_semen_supplier_id;
        END IF;
        
        
        /* Insert account_id INTO account_selection.semen_sup_semen_id*/
        SELECT  COUNT(*) 
        INTO    cur_count
        FROM    account_selection
        WHERE   account_id =  cur_user_account_id AND 
                semen_sup_semen_id = in_semen_sup_semen_id;
                
        IF cur_count = 0 THEN 
            INSERT INTO account_selection(
                account_id,
                semen_sup_semen_id,
                added_by_user_id
            ) VALUES (
                cur_user_account_id,
                in_semen_sup_semen_id,
                in_user_id
            );
        END IF;
        
        
        SELECT  COUNT(*)
        INTO    cur_count_semen_sup_semen_account
        FROM    account_selection
        WHERE   semen_sup_semen_id = in_semen_sup_semen_id;
    
        
        IF cur_count_semen_sup_semen_account >= MIN_COUNT_SEMEN_IS_VERIFIED THEN 
            SET cur_flag_bit = FLAG_BIT_SEMEN_SUPPLIER_SEMEN_IS_VERIFIED;
        END IF;
        
        
        UPDATE semen_supplier_semen SET 
            account_counter     = cur_count_semen_sup_semen_account,
            usage_counter       = usage_counter + 1,
            flag                = flag | cur_flag_bit
        WHERE id = in_semen_sup_semen_id;
        
        
        
        /* Update supplier account counter and usage*/
        SELECT  COUNT(*) 
        INTO    cur_count
        FROM    account_selection
        WHERE   semen_supplier_id = in_semen_supplier_id;
        
        UPDATE  common_supplier SET 
            ss_account_counter  = cur_count,
            ss_usage_counter    = ss_usage_counter + 1
        WHERE id = in_semen_supplier_id;
        
        
    
    END IF;
    
    
    INSERT INTO pig_prod_ai(
        pig_farm_id,
        pig_prod_id,
        semen_supplier_id,
        semen_sup_semen_id,
        semen_ai_boar_id,
        
        insem_staff_id,
        date_insemination,
        
        added_by_user_id
    ) VALUES(
        cur_sow_boar_pig_farm_id,
        cur_pig_prod_id,
        in_semen_supplier_id,
        in_semen_sup_semen_id,
        in_semen_ai_boar_id,
        
        in_insem_staff_id,
        in_date_insemination,
        
        in_user_id
    );
    
    SELECT LAST_INSERT_ID() INTO cur_pig_prod_ai_id;
    
END IF; 


/* Add comments*/
IF in_comments IS NOT NULL THEN 
    INSERT INTO pig_prod_notes (
        account_id,
        pig_farm_id,
        
        pig_prod_id,
        sow_boar_id,
        
        notes,
        date_notes,
        added_by_user_id
        
    ) VALUES (
        cur_sow_boar_account_id,
        cur_sow_boar_pig_farm_id,
    
        cur_pig_prod_id,
        in_sow_id,
        
        in_comments,
        in_date_insemination,
        in_user_id
    );

    SELECT LAST_INSERT_ID() INTO cur_pig_prod_notes_id;
    
    /* pig_production.insem_notes_id*/
    UPDATE pig_production SET
        insem_notes_id = cur_pig_prod_notes_id
    WHERE id = cur_pig_prod_id;

END IF;
    

/* Count production entries of the farm*/
SELECT  COUNT(*)
INTO    cur_count
FROM    pig_production
WHERE   pig_farm_id = cur_sow_boar_pig_farm_id;


/*
2026-05-23:
1.) Previously, when 
- a new Gesta entry is added
- a gesta entry is updated to lacta status
- a lacta entry is updated to weaning(fattening) status
- a fattening entry is fully harvested
- a fattening entry is joined to form a production group 

pig_farm.data_ver_num_pig_prod is incremented;

2.) Up until to this date, all production entries are queried in every app startup.
Each production entry is a large data.

3.) After this date, the new change is there is a system option to cache 
production data into client device. To have a granular control of the cache data,
these version numbers are added in pig_farm

- data_ver_num_prod_gesta
- data_ver_num_prod_lacta
- data_ver_num_prod_fatten

4.) So there are now 5 version numbers in pig_farm object that track the changes 
of production entry. Old version tracking
- data_ver_num_pig_prod
- data_ver_num_prod_history


Production Data Version Numbers (pig_farm table):

1. data_ver_num_pig_prod     - Overall production (any change in gesta, lacta, fattening)
2. data_ver_num_prod_history - Production history list
3. data_ver_num_prod_gesta   - Gestating list only
4. data_ver_num_prod_lacta   - Lactating list only
5. data_ver_num_prod_fatten  - Fattening list only

Increment rules:
- Add/update/delete gestating entry     → gesta + overall
- Add/update/delete lactating entry     → lacta + overall
- Add/update/delete fattening entry     → fatten + overall
- Status change (gesta → lacta)         → gesta + lacta + overall
- Status change (lacta → weaning)       → lacta + fatten + overall
- Status change (fattening → harvested) → fatten + history + overall
- Status change (fattening → prod_group) → fatten + history + overall

Client caching:
- Client stores each list separately
- Compares version numbers to know which list to refresh
- Reduces network transfer by ~75%
*/


/* Increment pig_farm.last_pig_production_id*/
UPDATE pig_farm SET 
    last_pig_production_id  = cur_pig_farm_last_pig_production_id,
    count_pig_prod          = cur_count,
    data_ver_num_pig_prod   = data_ver_num_pig_prod + 1,
    data_ver_num_prod_gesta = data_ver_num_prod_gesta + 1
WHERE id = cur_sow_boar_pig_farm_id;


/* Update sow status*/
UPDATE sow_boar SET
    last_pig_production_id  = cur_pig_prod_id,
    sow_status_id           = SOW_STATUS_ID_GESTATING,
    data_ver_num_sow_boar   = data_ver_num_sow_boar + 1
WHERE id = in_sow_id;



/* Count production entries of the account*/
SELECT  COUNT(*)
INTO    cur_count
FROM    pig_production
WHERE   account_id = cur_user_account_id;

UPDATE account SET 
    count_pig_prod = cur_count
WHERE id = cur_user_account_id;



/* Create pig_prod_pig_ops entry*/
CALL pig_prod_pig_ops_add(
    in_user_id, 
    
    cur_sow_boar_account_id,
    PIG_OPERATION_TYPE_GESTATING,
    cur_pig_prod_id, 
    in_date_insemination);


/* Since this is a gestating pig ops, need to relate to SOW.*/
UPDATE pig_prod_pig_ops SET 
    sow_boar_id = in_sow_id
WHERE pig_prod_id = cur_pig_prod_id AND operation_type = PIG_OPERATION_TYPE_GESTATING;



END process_user;

SELECT 
    res_num                             AS result_number,
    res_code                            AS result_code,
    res_desc                            AS result_desc,
    
    cur_pig_prod_id                     AS pig_prod_id,
    cur_pig_prod_ai_id                  AS pig_prod_ai_id;
    

END $$

DELIMITER ;
