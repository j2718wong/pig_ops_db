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


UPDATE pig_prod_pig_ops a, pig_production b SET
    a.sow_boar_id = b.sow_id
WHERE a.pig_prod_id = b.id AND a.operation_type = 1;

UPDATE pig_prod_pig_ops a, pig_production b SET
    a.sow_boar_id = b.sow_id
WHERE a.pig_prod_id = b.id AND a.operation_type = 3;


SELECT 
a.id,
a.pig_prod_id,
a.sow_boar_id,
b.name as sow_boar_name,
a.date_notes,
a.notes
FROM pig_prod_notes a
LEFT OUTER JOIN sow_boar b ON a.sow_boar_id = b.id;


UPDATE pig_prod_notes a, pig_production b SET 
    a.sow_boar_id = b.sow_id
WHERE a.pig_prod_id = 19;
