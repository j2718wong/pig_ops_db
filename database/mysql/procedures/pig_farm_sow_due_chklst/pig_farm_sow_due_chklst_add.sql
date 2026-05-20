DELIMITER $$

DROP PROCEDURE IF EXISTS pig_farm_sow_due_chklst_add $$
CREATE PROCEDURE pig_farm_sow_due_chklst_add(
    in_pig_farm_id                  INT
)  

BEGIN

/** 
 * Will add pig_farm_sow_due_chklst entry. This is called from a CRON job.
 * Not from user;
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since May 19, 2026
 *
 */


DECLARE RES_NUM_SUCCESS                         INT             DEFAULT 0;


DECLARE NUM_DAYS_SHOW_DUE_SOWS                  INT             DEFAULT 7;

DECLARE PRODUCTION_STATUS_ID_GESTATING          INT             DEFAULT 1;
DECLARE PRODUCTION_STATUS_ID_TERMINATED         INT             DEFAULT 2;
DECLARE PRODUCTION_STATUS_ID_NOT_PREGNANT       INT             DEFAULT 3;
DECLARE PRODUCTION_STATUS_ID_LACTATING          INT             DEFAULT 4;
DECLARE PRODUCTION_STATUS_ID_WEANING            INT             DEFAULT 5;
DECLARE PRODUCTION_STATUS_ID_GROWING            INT             DEFAULT 6;
DECLARE PRODUCTION_STATUS_ID_COMBINED           INT             DEFAULT 7;
DECLARE PRODUCTION_STATUS_ID_HARVESTED          INT             DEFAULT 8;



DECLARE cur_pig_farm_account_id                 INT             DEFAULT 0;
DECLARE cur_pig_farm_sow_due_chklst_id          INT             DEFAULT 0;
DECLARE cur_pig_farm_new_chklst_id              INT             DEFAULT 0;


DECLARE cur_count                               INT             DEFAULT 0;
DECLARE cur_count_chklst                        INT             DEFAULT 0;



SELECT  account_id,
        last_sow_due_chklst_id
        
INTO    cur_pig_farm_account_id,
        cur_pig_farm_sow_due_chklst_id

FROM    pig_farm
WHERE   id = in_pig_farm_id;



process_user : BEGIN


/** Step 1: Count gestating pig_production entries. */
SELECT  COUNT(*)
INTO    cur_count
FROM    pig_production
WHERE   pig_farm_id = in_pig_farm_id  
        AND prod_status_id = PRODUCTION_STATUS_ID_GESTATING;


IF cur_count = 0 THEN 
    IF cur_pig_farm_sow_due_chklst_id > 0 THEN 
        /** The current pig farm sow due checklist becomes inactive. */
        UPDATE pig_farm_sow_due_chklst SET
            date_start_end = CURRENT_DATE
        WHERE id = cur_pig_farm_sow_due_chklst_id;
        
        UPDATE pig_farm SET 
            last_sow_due_chklst_id  = 0, 
            data_ver_num_sd_chklst  = data_ver_num_sd_chklst + 1
        WHERE id = in_pig_farm_id;
        
    END IF;
    
    LEAVE process_user;
    
END IF;


/** Step 2: Count gestating pig_production entries that are due in next 7 days  */
SET cur_count = 0;

SELECT  COUNT(*)
INTO    cur_count
FROM    pig_production
WHERE   pig_farm_id = in_pig_farm_id  
        AND prod_status_id = PRODUCTION_STATUS_ID_GESTATING
        AND DATEDIFF(date_expected_birth, CURRENT_DATE) <= NUM_DAYS_SHOW_DUE_SOWS; 
        
        
IF cur_count = 0 THEN 
    IF cur_pig_farm_sow_due_chklst_id > 0 THEN 
        /** The current pig farm sow due checklist becomes inactive. */
        UPDATE pig_farm_sow_due_chklst SET
            date_start_end = CURRENT_DATE
        WHERE id = cur_pig_farm_sow_due_chklst_id;
        
        UPDATE pig_farm SET 
            last_sow_due_chklst_id  = 0,
            data_ver_num_sd_chklst  = data_ver_num_sd_chklst + 1 
        WHERE id = in_pig_farm_id;
        
    END IF;
    
    LEAVE process_user;
    
ELSE
    IF cur_pig_farm_sow_due_chklst_id = 0 THEN
        /** Check first account if there are account_sow_due_chklst entries*/
        SELECT  COUNT(*)
        INTO    cur_count_chklst
        FROM    account_sow_due_chklst
        WHERE   account_id = cur_pig_farm_account_id;
        
        IF cur_count_chklst = 0 THEN
            CALL account_sow_due_chklst_create(cur_pig_farm_account_id);
        END IF;
    
    
        /** Create pig_farm_sow_due_chklst entry. */
        INSERT INTO pig_farm_sow_due_chklst(
            pig_farm_id,
            date_start_show
            -- date_start_end will be NULL initially
        ) VALUES (
            in_pig_farm_id,
            CURRENT_DATE
        );

        SELECT LAST_INSERT_ID() INTO cur_pig_farm_new_chklst_id; 


        /** Update pig_farm. */
        UPDATE pig_farm SET 
            last_sow_due_chklst_id  = cur_pig_farm_new_chklst_id,
            data_ver_num_sd_chklst  = data_ver_num_sd_chklst + 1
        WHERE id = in_pig_farm_id;


        /** Create pf_sow_due_chklst_item entries*/
        INSERT INTO pf_sow_due_chklst_item(
            pf_sow_due_chklst_id,
            acc_sow_due_chklst_id
        )

        SELECT
            cur_pig_farm_new_chklst_id, 
            id
        FROM account_sow_due_chklst
        WHERE account_id = cur_pig_farm_account_id 
            AND flag & 1 = 0
        ORDER BY name;
    
    END IF;
    
END IF;




END process_user;




END $$

DELIMITER ;
