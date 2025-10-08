


TRUNCATE TABLE pig_production;
TRUNCATE TABLE pig_prod_ai;

TRUNCATE TABLE pig_prod_notes;
TRUNCATE TABLE pig_prod_pig_dead;
TRUNCATE TABLE pig_prod_pig_ops;

TRUNCATE TABLE feed_balance;
TRUNCATE TABLE feed_buy;
TRUNCATE TABLE sow_boar_balance;


TRUNCATE TABLE production_harvest;

UPDATE pig_farm SET last_pig_production_id = 0;