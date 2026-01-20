DELIMITER $$

DROP PROCEDURE IF EXISTS pig_medvac_search_keys $$
CREATE PROCEDURE pig_medvac_search_keys(
    IN p_account_id INT,
    IN p_search_str VARCHAR(255)
)  

BEGIN

/** 
 * Will search medvac key; using deepseek 
 * 
 * @author Jack Wong (j2718wong@gmail.com) 
 * @since January 19, 2026
 *
 */
	SELECT 
        searched_str,
        SUM(hits) as num_hits
    FROM (
        -- Strings that START WITH the search term (priority 1)
        SELECT 
            u_brand_name AS searched_str,
            COUNT(*) as hits,
            1 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_brand_name LIKE CONCAT(p_search_str, '%')
        GROUP BY u_brand_name
        
        UNION ALL
        
        SELECT 
            u_type_name AS searched_str,
            COUNT(*) as hits,
            1 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_type_name LIKE CONCAT(p_search_str, '%')
        GROUP BY u_type_name
        
        UNION ALL
        
        SELECT 
            u_acc_medvac_name AS searched_str,
            COUNT(*) as hits,
            1 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_acc_medvac_name LIKE CONCAT(p_search_str, '%')
        GROUP BY u_acc_medvac_name
        
        UNION ALL
        
		
		
		
        -- Strings that CONTAIN the search term but don't start with it (priority 2)
        SELECT 
            u_brand_name AS searched_str,
            COUNT(*) as hits,
            2 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_brand_name LIKE CONCAT('%', p_search_str, '%')
            AND u_brand_name NOT LIKE CONCAT(p_search_str, '%')
        GROUP BY u_brand_name
        
        UNION ALL
        
        SELECT 
            u_type_name AS searched_str,
            COUNT(*) as hits,
            2 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_type_name LIKE CONCAT('%', p_search_str, '%')
            AND u_type_name NOT LIKE CONCAT(p_search_str, '%')
        GROUP BY u_type_name
        
        UNION ALL
        
        SELECT 
            u_acc_medvac_name AS searched_str,
            COUNT(*) as hits,
            2 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND u_acc_medvac_name LIKE CONCAT('%', p_search_str, '%')
            AND u_acc_medvac_name NOT LIKE CONCAT(p_search_str, '%')
        GROUP BY u_acc_medvac_name
		
		UNION ALL
        
        SELECT 
            notes AS searched_str,
            COUNT(*) as hits,
            2 as priority
        FROM pig_medvac 
        WHERE account_id = p_account_id 
            AND notes LIKE CONCAT('%', p_search_str, '%')
        GROUP BY notes
		
    ) AS combined_results
    GROUP BY searched_str, priority
    ORDER BY priority ASC, SUM(hits) DESC
    LIMIT 8;
    

END $$

DELIMITER ;