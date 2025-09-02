
UPDATE user SET account_id = 0, user_group_id = 0;

TRUNCATE TABLE account;
TRUNCATE TABLE user_group;
TRUNCATE TABLE pig_farm;
TRUNCATE TABLE pig_farm_staff;
TRUNCATE TABLE sow_boar;
TRUNCATE TABLE account_gestating_ops;
TRUNCATE TABLE account_lactating_ops;
TRUNCATE TABLE pig_race_line;
TRUNCATE TABLE semen_supplier;
TRUNCATE TABLE feed_brand;
TRUNCATE TABLE feed_supplier;

TRUNCATE TABLE semen_source;

TRUNCATE TABLE pig_production;
TRUNCATE TABLE pig_prod_notes;	
TRUNCATE TABLE pig_prod_pig_dead;

TRUNCATE TABLE prod_gestating_ops;
TRUNCATE TABLE prod_lactating_ops;


