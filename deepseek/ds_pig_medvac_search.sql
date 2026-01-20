
/*
Given a MYSLQ table:
id(integer),
account_id (integer)
u_brand_name (string),
u_type_name (string),
u_acc_medvac_name (string),


1.) Create a procedure that has these inputs
account_id, search_str

2.) Will search through the string columns

3.) will return top 8 names from either u_brand_name, u_type_name, u_acc_medvac_name

with each result has searched count.

the ouput in memory or temp table should should have columns

searched_str, num_hits

*/

DELIMITER $$

CREATE PROCEDURE pig_medvac_search_key_string(
    IN p_account_id INT,
    IN p_search_str VARCHAR(255)
)
BEGIN
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
    ) AS combined_results
    GROUP BY searched_str, priority
    ORDER BY priority ASC, SUM(hits) DESC
    LIMIT 8;
    
END $$

DELIMITER ;




/*
Given a MYSLQ table:
id(integer),
account_id (integer),
sow_boar_id (integer),
u_brand_name (string),
u_type_name (string),
u_acc_medvac_name (string),



1.) Create a procedure that has these inputs
account_id, search_str

2.) Will search through the string columns

3.)  return rows where prioritizes strings starting with the search term

*/


CREATE PROCEDURE search_account_data_optimized(
    IN p_account_id INT,
    IN p_search_str VARCHAR(255)
)
BEGIN
    -- Return all results in priority order
    SELECT 
        id,
        account_id,
        sow_boar_id,
        u_brand_name,
        u_type_name,
        u_acc_medvac_name
    FROM your_table_name
    WHERE account_id = p_account_id
        AND (
            u_brand_name LIKE CONCAT('%', p_search_str, '%') OR
            u_type_name LIKE CONCAT('%', p_search_str, '%') OR
            u_acc_medvac_name LIKE CONCAT('%', p_search_str, '%')
        )
    ORDER BY 
        CASE 
            WHEN u_brand_name LIKE CONCAT(p_search_str, '%') THEN 1
            WHEN u_type_name LIKE CONCAT(p_search_str, '%') THEN 1
            WHEN u_acc_medvac_name LIKE CONCAT(p_search_str, '%') THEN 1
            ELSE 2
        END ASC,
        id ASC;
    
END //

DELIMITER ;


/*
how to select the word in a string mysql column that starts with a given string?

Example: column = "The quick brown fox"; search_str = "br"; it should return the word "brown"








*/
