SELECT 
a.id,
a.farm_prod_id,
a.sow_id,
b.name,
a.insem_staff_id,
c.name
FROM pig_production a 
LEFT OUTER JOIN sow_boar b ON a.sow_id = b.id
LEFT OUTER JOIN pig_farm_staff c ON a.insem_staff_id = c.id
WHERE a.farm_prod_id = 27


SELECT a.id
a.farm_prod_id,
a.sow_id,
b.name,
a.prod_status_id,
c.name
FROM pig_production a 
LEFT OUTER JOIN sow_boar b ON a.sow_id = b.id
LEFT OUTER JOIN production_status c ON a.prod_status_id = c.id
WHERE a.id = 20


SELECT 
id,
name
FROm sow_boar
WHERE name LIKE 'Rosita'


SELECT 
id,
name
FROm sow_boar
WHERE name LIKE 'Kurdapya'


SELECT 
id,
name
FROm sow_boar
WHERE name LIKE 'soling'

SELECT 
id,
name
FROm sow_boar
WHERE name LIKE 'osang'

SELECT 
id,
name
FROm sow_boar
WHERE name LIKE 'fiona';



SELECT
a.id,
b.name AS sow_boar_name, 
c.name AS acc_pig_ops,
a.date_target,
a.date_actual,
a.notes_id
FROM pig_prod_pig_ops a
LEFT OUTER JOIN sow_boar b ON a.sow_boar_id = b.id
LEFT OUTER JOIN account_pig_ops c ON a.account_pig_ops_id = c.id 
WHERE a.sow_boar_id = 10;


SELECT id, 
num_pigs_dead_at_birth,
num_pigs_live_m,
num_pigs_live_f
FROM pig_production
WHERE sow_id = 5 AND date_actual_birth IS NOT NULL;



SElect id, pig_prod_id, sow_boar_id, date_notes, notes FROM pig_prod_notes;


SELECT 
    ROUTINE_SCHEMA as `Database`,
    ROUTINE_NAME as `Procedure`
    
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'pig_ops_dev'
    AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;


SELECT 
a.id,                
a.pig_prod_id,
a.sow_boar_id,  
b.name AS sow_name,
a.account_pig_ops_id,
c.name AS pig_ops_name,
a.pig_medvac_id,     
a.operation_type,    
a.date_target,       
a.date_actual,       
a.staff_id, 
a.notes_id

FROM pig_prod_pig_ops a
LEFT OUTER JOIN sow_boar b ON a.sow_boar_id = b.id
LEFT OUTER JOIN account_pig_ops c ON a.account_pig_ops_id = c.id  
WHERE a.pig_prod_id = 16;


SELECT 
a.id,
a.pig_prod_id,
b.name AS sow_boar_name,
a.pig_prod_pig_ops_id AS pig_ops_id,
a.health_issue_id,
a.date_medvac,
a.medvac_brand_id,
a.medvac_type_id,
a.acc_medvac_id
FROM pig_medvac a
LEFT OUTER JOIN sow_boar b ON a.sow_boar_id = b.id;




SELECT 
a.id,
a.pig_prod_id,
a.sow_boar_id,
a.flag,
b.name as sow_boar_name,
a.date_notes,
a.notes
FROM pig_prod_notes a
LEFT OUTER JOIN sow_boar b ON a.sow_boar_id = b.id
WHERE a.sow_boar_id=15;


UPDATE pig_prod_notes a, pig_production b SET 
    a.sow_boar_id = b.sow_id
WHERE a.pig_prod_id = 19;


SELECT 
a.id,
a.pig_prod_id,
b.name as sow_name,
c.name AS acc_pig_ops,
a.operation_type,
a.date_target,
a.date_actual,
a.notes_id

FROm pig_prod_pig_ops a
LEFT outer join sow_boar b ON a.sow_boar_id = b.id
LEFT outer join account_pig_ops c ON a.account_pig_ops_id = c.id
WHERE a.pig_prod_id = 18;


SELECT
id,
flag,
name,
added_by_user_id
FROM medvac_type;


SELECT
a.id,
b.name as prod_status,
a.num_pigs_current
FROM pig_production a 
LEFT OUTER JOIN pig_prod_status b ON a.prod_status_id = b.id
WHERE a.date_actual_birth IS NOT NULL;


SELECT
id,
name,
add_notes_id,
notes
FROm sow_boar;


SELECT
a.id,
a.name,
a.add_notes_id,
a.is_production_ready,
b.date_notes,
b.notes AS pig_prod_notes,
a.sow_status_id,
c.name AS sow_status,
a.parent_sow_id,
a.parent_boar_id
FROm sow_boar a
LEFT OUTER JOIN pig_prod_notes b ON a.add_notes_id = b.id
LEFT OUTER JOIN sow_status c ON a.sow_status_id = c.id
WHERE a.name LIKE 'rosita'

SELECT 
a.id,
a.pig_prod_id,
a.sow_boar_id,
b.name as sow_boar_name,
a.notes,
a.date_notes
FROM pig_prod_notes a
LEFT OUTER JOIN sow_boar b ON a.sow_boar_id = b.id;



SELECT 
id,
name,
notes
FROM sow_boar
WHERE id >=1 AND id <=8

--common_supplier
+---------------------+------------------------+------+-----+---------------------+----------------+
| Field               | Type                   | Null | Key | Default             | Extra          |
+---------------------+------------------------+------+-----+---------------------+----------------+
| id                  | int(10) unsigned       | NO   | PRI | NULL                | auto_increment |
| country_id          | int(10) unsigned       | YES  | MUL | 0                   |                |
| address_level_1_id  | int(10) unsigned       | YES  | MUL | 0                   |                |
| address_level_2_id  | int(10) unsigned       | YES  | MUL | 0                   |                |
| address_level_3_id  | int(10) unsigned       | YES  |     | 0                   |                |
| flag                | int(10) unsigned       | YES  |     | 0                   |                |
| is_feed_supplier    | int(10) unsigned       | YES  |     | 0                   |                |
| is_gilt_supplier    | int(10) unsigned       | YES  |     | 0                   |                |
| is_semen_supplier   | int(10) unsigned       | YES  |     | 0                   |                |
| fs_account_counter  | int(10) unsigned       | YES  |     | 0                   |                |
| gs_account_counter  | int(10) unsigned       | YES  |     | 0                   |                |
| ss_account_counter  | int(10) unsigned       | YES  |     | 0                   |                |
| fs_usage_counter    | int(10) unsigned       | YES  |     | 0                   |                |
| gs_usage_counter    | int(10) unsigned       | YES  |     | 0                   |                |
| ss_usage_counter    | int(10) unsigned       | YES  |     | 0                   |                |
| latitude            | decimal(10,5) unsigned | YES  |     | NULL                |                |
| longitude           | decimal(10,5) unsigned | YES  |     | NULL                |                |
| name                | varchar(50)            | YES  |     | NULL                |                |
| contact_number      | varchar(20)            | YES  |     | NULL                |                |
| whatsapp            | varchar(20)            | YES  |     | NULL                |                |
| messenger           | varchar(50)            | YES  |     | NULL                |                |
| deleted_by_user_id  | int(11)                | YES  |     | NULL                |                |
| added_by_user_id    | int(11)                | YES  |     | NULL                |                |
| last_update_user_id | int(11)                | YES  |     | NULL                |                |
| dt_last_update      | datetime               | YES  |     | NULL                |                |
| dt_entry            | datetime               | YES  |     | current_timestamp() |                |
+---------------------+------------------------+------+-----+---------------------+----------------+

MariaDB [pig_ops_dev]> DESCRIBE account_selection;
+---------------------+------------------+------+-----+---------------------+----------------+
| Field               | Type             | Null | Key | Default             | Extra          |
+---------------------+------------------+------+-----+---------------------+----------------+
| id                  | int(10) unsigned | NO   | PRI | NULL                | auto_increment |
| account_id          | int(10) unsigned | YES  | MUL | 0                   |                |
| flag                | int(10) unsigned | YES  |     | 0                   |                |
| feed_brand_id       | int(10) unsigned | YES  | MUL | NULL                |                |
| feed_supplier_id    | int(10) unsigned | YES  | MUL | NULL                |                |
| gilt_supplier_id    | int(10) unsigned | YES  | MUL | NULL                |                |
| semen_supplier_id   | int(10) unsigned | YES  | MUL | NULL                |                |
| semen_sup_semen_id  | int(10) unsigned | YES  | MUL | NULL                |                |
| medvac_brand_id     | int(10) unsigned | YES  | MUL | NULL                |                |
| medvac_type_id      | int(10) unsigned | YES  | MUL | NULL                |                |
| address_level_1_id  | int(10) unsigned | YES  |     | NULL                |                |
| address_level_2_id  | int(10) unsigned | YES  |     | NULL                |                |
| address_level_3_id  | int(10) unsigned | YES  |     | NULL                |                |
| last_update_user_id | int(10) unsigned | YES  |     | NULL                |                |
| added_by_user_id    | int(10) unsigned | YES  |     | NULL                |                |
| dt_last_update      | datetime         | YES  |     | NULL                |                |
| dt_entry            | datetime         | YES  |     | current_timestamp() |                |
+---------------------+------------------+------+-----+---------------------+----------------+

SELECT
a.feed_supplier_id,
b.name,
b.is_feed_supplier, 
b.is_gilt_supplier, 
b.is_semen_supplier

FROM account_selection a
LEFT OUTER JOIN common_supplier b ON a.feed_supplier_id = b.id
WHERE a.account_id = 1 AND a.flag&1 = 0 
AND a.feed_supplier_id IS NOT NULL
AND b.is_feed_supplier > 0;


SELECT id,
account_id,
flag,
feed_supplier_id, 
gilt_supplier_id, 
semen_supplier_id
FROM account_selection;

+---------------------+------------------+------+-----+---------------------+----------------+
| Field               | Type             | Null | Key | Default             | Extra          |
+---------------------+------------------+------+-----+---------------------+----------------+
| id                  | int(10) unsigned | NO   | PRI | NULL                | auto_increment |
| account_id          | int(10) unsigned | NO   |     | 0                   |                |
| pig_farm_id         | int(11)          | YES  | MUL | NULL                |                |
| date_buy            | date             | YES  |     | NULL                |                |
| feed_supplier_id    | int(11)          | YES  |     | NULL                |                |
| total_feed_cost     | decimal(10,2)    | YES  |     | NULL                |                |
| other_cost          | decimal(8,2)     | YES  |     | NULL                |                |
| added_by_user_id    | int(11)          | YES  |     | NULL                |                |
| last_update_user_id | int(11)          | YES  |     | NULL                |                |
| dt_last_update      | datetime         | YES  |     | NULL                |                |
| dt_entry            | datetime         | YES  |     | current_timestamp() |                |
+---------------------+------------------+------+-----+---------------------+----------------+

SELECT 
a.id,
a.account_id,
a.pig_farm_id,
a.date_buy,
b.name as feed_supplier,
a.total_feed_cost,
a.other_cost
FROM pig_farm_feed_buy a
LEFT OUTER JOIN common_supplier b ON a.feed_supplier_id = b.id
WHERE a.pig_farm_id = 1;


SELECT 
    a.id,
    
    a.date_buy,
    
    a.total_feed_cost,
    a.other_cost,
    
    a.feed_supplier_id,
    b.name AS feed_supplier_name
    
FROM pig_farm_feed_buy a 
LEFT OUTER JOIN feed_supplier b     ON a.feed_supplier_id = b.id
WHERE a.pig_farm_id = 1
ORDER BY a.date_buy DESC
LIMIT 50 OFFSET 0 



SELECT 
a.account_id,
a.feed_brand_id,
b.name as brand_name

FROM account_selection a
LEFT OUTER JOIN feed_brand b ON a.feed_brand_id = b.id
WHERE a.account_id = 1 AND a.feed_brand_id IS NOT NULL;


SELECT 
id,
flag,
country_id,
name,
added_by_user_id
FROM feed_brand



+----------------------+------------------+------+-----+---------------------+----------------+
| Field                | Type             | Null | Key | Default             | Extra          |
+----------------------+------------------+------+-----+---------------------+----------------+
| id                   | int(10) unsigned | NO   | PRI | NULL                | auto_increment |
| pig_farm_feed_buy_id | int(11)          | YES  | MUL | NULL                |                |
| feed_type_id         | int(11)          | YES  |     | NULL                |                |
| feed_brand_id        | int(11)          | YES  |     | NULL                |                |
| quantity             | int(11)          | YES  |     | NULL                |                |
| kg_per_unit          | decimal(5,1)     | YES  |     | NULL                |                |
| kg_total             | decimal(6,1)     | YES  |     | NULL                |                |
| unit_cost            | decimal(8,2)     | YES  |     | NULL                |                |
| total_cost           | decimal(10,2)    | YES  |     | NULL                |                |
| added_by_user_id     | int(11)          | YES  |     | NULL                |                |
| last_update_user_id  | int(11)          | YES  |     | NULL                |                |
| dt_last_update       | datetime         | YES  |     | NULL                |                |
| dt_entry             | datetime         | YES  |     | current_timestamp() |                |
+----------------------+------------------+------+-----+---------------------+----------------+

SELECT 
a.id,
b.name as feed_type,
c.name AS feed_brand,
a.quantity as qty,
a.unit_cost,
a.total_cost
FROM pig_farm_feed_buy_item a 
LEFT OUTER JOIN feed_type b ON a.feed_type_id = b.id
LEFT OUTER JOIN feed_brand c ON a.feed_brand_id = c.id;



SELECT
a.id,
a.date_actual_birth,
a.date_weaning,
a.sow_id,
b.name AS sow_name,
a.prod_status_id,
c.name AS prod_status

FROM pig_production a 
LEFT OUTER JOIN sow_boar b ON a.sow_id = b.id
LEFT OUTER JOIN pig_prod_status c ON a.prod_status_id = c.id
WHERE a.id = 14;


SELECT 
        a.id,
        a.name,
        
        a.sow_status_id,
        b.name as sow_status,
        
        
        d.farm_prod_id,
        d.date_insemination,
        d.date_expected_birth,
        
        a.last_mate_sow_boar_id,
        a.mate_count,
        a.date_last_mate

        
        
    FROM sow_boar a
    LEFT OUTER JOIN sow_status b    ON a.sow_status_id  = b.id
    LEFT OUTER JOIN pig_production d    ON a.last_pig_production_id  = d.id
    LEFT OUTER JOIN pig_prod_notes e    ON a.add_notes_id           = e.id
    WHERE a.id =9;

SELECT 
a.id, 
a.pig_farm_id, 
a.pig_prod_id, 
a.pig_farm_feed_buy_id AS pf_feed_buy_id,
a.pig_prod_feed_id,
a.date_buy, 
a.feed_type_id,
b.name,
a.quantity as qty,
a.unit_cost,
a.total_cost
FROm feed_buy a
LEFT OUTER JOIN feed_type b ON a.feed_type_id = b.id
WHERE a.pig_farm_feed_buy_id = 1
ORDER BY a.id;


SELECT
a.id,
a.name AS sow_boar_name,
a.add_notes_id,
b.notes
FROm sow_boar a
LEFT OUTER JOIN pig_prod_notes b ON a.add_notes_id = b.id; 


SELECT 
id,
pig_prod_id,
date_balance,
num_pigs,
num_b_gestating,
num_b_lactating,
num_b_booster,
num_b_prestarter,
num_b_starter,


num_gestating,
num_lactating,
num_booster,
num_prestarter,
num_starter


FROm feed_balance


MariaDB [pig_operations]> DESCRIBE production_harvest;
+--------------------------+-----------------------+------+-----+---------------------+----------------+
| Field                    | Type                  | Null | Key | Default             | Extra          |
+--------------------------+-----------------------+------+-----+---------------------+----------------+
| id                       | int(10) unsigned      | NO   | PRI | NULL                | auto_increment |
| account_id               | int(10) unsigned      | YES  | MUL | 0                   |                |
| pig_prod_id              | int(10) unsigned      | YES  | MUL | 0                   |                |
| production_group_id      | int(10) unsigned      | YES  |     | 0                   |                |
| acc_pig_buyer_id         | int(10) unsigned      | YES  |     | NULL                |                |
| date_harvest             | date                  | YES  |     | NULL                |                |
| num_days_since_birth     | int(10) unsigned      | YES  |     | NULL                |                |
| num_pigs_harvest         | int(10) unsigned      | YES  |     | 1                   |                |
| harvest_type_id          | int(10) unsigned      | YES  |     | NULL                |                |
| live_weight              | decimal(6,1) unsigned | YES  |     | NULL                |                |
| live_weight_ave          | decimal(6,1)          | YES  |     | NULL                |                |
| live_price_per_unit      | decimal(6,1) unsigned | YES  |     | NULL                |                |
| slaughter_weight         | decimal(6,1) unsigned | YES  |     | NULL                |                |
| slaughter_minus_weight   | decimal(6,1) unsigned | YES  |     | NULL                |                |
| slaughter_net_weight     | decimal(6,1) unsigned | YES  |     | NULL                |                |
| slaughter_weight_ave     | decimal(6,1) unsigned | YES  |     | NULL                |                |
| slaughter_price_per_unit | decimal(6,1) unsigned | YES  |     | NULL                |                |
| net_sales                | decimal(8,1) unsigned | YES  |     | NULL                |                |
| net_sales_pp             | decimal(8,1) unsigned | YES  |     | NULL                |                |
| harvest_cost             | decimal(5,1) unsigned | YES  |     | NULL                |                |
| weight_pp_lw_csv         | varchar(400)          | YES  |     | NULL                |                |
| weight_pp_sw_csv         | varchar(400)          | YES  |     | NULL                |                |
| comments                 | varchar(160)          | YES  |     | NULL                |                |
| last_update_user_id      | int(11)               | YES  |     | NULL                |                |
| added_by_user_id         | int(11)               | YES  |     | NULL                |                |
| dt_last_update           | datetime              | YES  |     | NULL                |                |
| dt_entry                 | datetime              | YES  |     | current_timestamp() |                |
+--------------------------+-----------------------+------+-----+---------------------+----------------+





SELECT 
a.id,
a.date_harvest, 
a.pig_farm_id,
a.pig_prod_id, 
b.name AS pig_buyer,
a.num_pigs_harvest as num_pigs,
c.name AS harvest_type,
a.slaughter_weight_ave AS slaughter_ave,
a.net_sales, 
a.comments,
a.weight_pp_sw_csv
FROM production_harvest a
LEFT OUTER JOIN account_pig_buyer b ON a.acc_pig_buyer_id = b.id
LEFT OUTER JOIN harvest_type c ON a.harvest_type_id = c.id  


CALL production_calculate_current_pigs(13, 0, @cur_pigs);


SELECT id,
prod_status_id,
num_pigs_live_m,
num_pigs_live_f,
num_pigs_weaning_m,
num_pigs_weaning_f,
num_pigs_current

FROm pig_production
WHERE id = 13;




+----+--------------+-------------+----------+-----------------------------+-----------------+-----------+--------------+-------------------------------------------------+-------------------------------+
| id | date_harvest | pig_prod_id | buyer_id | pig_buyer                   | harvest_type_id | net_sales | harvest_cost | comments                                        | weight_pp_sw_csv              |
+----+--------------+-------------+----------+-----------------------------+-----------------+-----------+--------------+-------------------------------------------------+-------------------------------+
|  1 | 2025-02-16   |           1 |     NULL | NULL                        |            NULL |      NULL |         NULL | baligya kay nawadan trabaho                     | NULL                          |
|  2 | 2025-08-19   |           9 |     NULL | NULL                        |            NULL |      NULL |         NULL | Bayad Butakal                                   | NULL                          |
|  3 | 2025-09-19   |           5 |        1 | Meloy Requinto              |            NULL |   15320.0 |        200.0 | plete                                           | 78.6                          |
|  4 | 2025-09-27   |           5 |     NULL | NULL                        |            NULL |      NULL |         NULL | himo 1 anay, 1 butakal                          | NULL                          |
|  5 | 2025-10-23   |          13 |     NULL | NULL                        |            NULL |      NULL |         NULL | Bayad Butakal                                   | NULL                          |
|  6 | 2025-11-10   |           7 |        2 | Mingla Weni Mangrasyon      |            NULL |  101615.0 |       2000.0 | NULL                                            | 85.5,80.9,77.7,92.2,71.5,79.2 |
|  7 | 2025-11-11   |           7 |     NULL | NULL                        |            NULL |      NULL |         NULL | himo 3 anay, 2 butakal                          | NULL                          |
|  8 | 2025-11-10   |           9 |     NULL | NULL                        |            NULL |      NULL |         NULL | NULL                                            | NULL                          |
|  9 | 2025-11-26   |           9 |        3 | Ting Rasyon sa Naga merkado |            NULL |   42810.0 |       1350.0 | plete baboy 350 isa, sakwat baboy 100 isa       | 63,61,83                      |
| 10 | 2025-11-28   |           9 |        4 | Silingan Punod Namatyan     |            NULL |   44505.0 |          0.0 | walay plete kay silingan                        | 75,80,52                      |
| 11 | 2025-11-29   |           9 |        3 | Ting Rasyon sa Naga merkado |            NULL |  104015.0 |       4130.0 | plete baboy 350 isa, sakwat baboy 100 isa       | 65,58,75,82,82,65,83          |
| 12 | 2025-12-02   |           9 |        5 | Silingan Punod Palit Anay   |            NULL |   36120.0 |          0.0 | Gitupong ang timbangs a pinakabugat na narasyon | NULL                          |
| 13 | 2026-02-04   |          13 |        3 | Ting Rasyon sa Naga merkado |            NULL |   86520.0 |       2700.0 | plete baboy 2100, sakwat baboy 600              | NULL                          |
| 14 | 2026-02-05   |          13 |        6 | Nagbuhat sa Farrowing       |            NULL |   49140.0 |          0.0 | Gitupong ang timbang sa pinakabugat na narasyon | NULL                          |
+----+--------------+-------------+----------+-----------------------------+-----------------+-----------+--------------+-------------------------------------------------+-------------------------------+

ALTER TABLE pig_production ADD COLUMN harvest_wt_pp_live    VARCHAR(400)  AFTER cost_finisher;
ALTER TABLE pig_production ADD COLUMN harvest_wt_pp_live    VARCHAR(400)  AFTER cost_finisher;  
ALTER TABLE pig_production ADD COLUMN harvest_wt_slaughter_ave  DECIMAL(6,1) UNSIGNED AFTER cost_finisher;
ALTER TABLE pig_production ADD COLUMN harvest_wt_slaughter  DECIMAL(6,1) UNSIGNED AFTER cost_finisher;
ALTER TABLE pig_production ADD COLUMN harvest_wt_live_ave   DECIMAL(6,1) UNSIGNED AFTER cost_finisher;
ALTER TABLE pig_production ADD COLUMN harvest_wt_live       DECIMAL(6,1) UNSIGNED AFTER cost_finisher;
ALTER TABLE pig_production ADD COLUMN harvest_num_sold_pigs INT UNSIGNED AFTER cost_finisher;
ALTER TABLE pig_production ADD COLUMN harvest_num_sold_boar INT UNSIGNED AFTER cost_finisher;
ALTER TABLE pig_production ADD COLUMN harvest_num_sold_gilt INT UNSIGNED AFTER cost_finisher;
ALTER TABLE pig_production ADD COLUMN harvest_num_int_sow_boar INT UNSIGNED AFTER cost_finisher;

SELECT id, name, num_births, num_pigs_wean FROm sow_boar;


SELECT
id,
account_id,
flag,
name,
name_first,
name_last,
email

FROM user;


SELECT id, account_id, name, country_id, address_level_1_id FROm pig_farm;

