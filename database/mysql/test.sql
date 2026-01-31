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
 