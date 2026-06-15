-- 177_new_table_account_last_feed_price.sql
-- June 14, 2026
-- Jack Wong ; 

DELIMITER $$

DROP PROCEDURE IF EXISTS add_table_account_last_feed_price $$
CREATE PROCEDURE add_table_account_last_feed_price()

BEGIN
    DECLARE col_exists INT DEFAULT 0;
    
    CREATE TABLE IF NOT EXISTS `account_last_feed_price` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `account_id` int(10) unsigned,
      `last_common_supplier_id` int(10) unsigned,
      `last_feed_buy_id` int(10) unsigned,
     
      `price_puwt_gestating` DECIMAL(6,2),
      `price_puwt_lactating` DECIMAL(6,2),
      `price_puwt_booster` DECIMAL(6,2),
      `price_puwt_prestarter` DECIMAL(6,2),
      `price_puwt_starter` DECIMAL(6,2),
      `price_puwt_grower` DECIMAL(6,2),
      `price_puwt_finisher` DECIMAL(6,2),
      
      `dt_last_update`      datetime, 
      
      `dt_entry` datetime DEFAULT current_timestamp(),
      PRIMARY KEY (`id`)
    );

    
END$$

DELIMITER ;

CALL add_table_account_last_feed_price();
DROP PROCEDURE add_table_account_last_feed_price;
