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
WHERE name LIKE 'fiona'





SELECT id, 
num_pigs_dead_at_birth,
num_pigs_live_m,
num_pigs_live_f
FROM pig_production
WHERE sow_id = 5 AND date_actual_birth IS NOT NULL;



SElect id, pig_prod_id, sow_boar_id, date_notes, notes FROM pig_prod_notes;

