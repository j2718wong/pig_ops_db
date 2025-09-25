
/* New AI entry*/
CALL sow_new_ai_entry(342298, 1, 3, '2024-09-10', 'AI PIC 337');
CALL sow_new_ai_entry(342298, 1, 2, '2025-03-18', 'AI PIC 337');
CALL sow_new_ai_entry(342298, 1, 2, '2025-04-08', 'AI PIC 337');
CALL sow_new_ai_entry(342298, 1, 2, '2025-04-28', 'AI PIC 337');
CALL sow_new_insemination_entry(342298, 2, 2, '2025-05-20', 'Kasta Landrace');



CALL sow_new_ai_entry(342265, 1, 2, '2024-11-03', 'AI PIC 337');

CALL sow_new_ai_entry(342271, 1, 2, '2024-11-03', 'AI PIC 337');
CALL sow_new_ai_entry(342271, 1, 2, '2025-01-06', 'AI PIC 337');
CALL sow_new_ai_entry(342271, 1, 2, '2025-03-10', 'AI PIC 337');
CALL sow_new_ai_entry(342271, 2, 2, '2025-03-16', 'Kasta Landrace');
CALL sow_new_insemination_entry(342271, 1, 2, '2025-08-26', 'AI PIC 337');

CALL sow_new_ai_entry(324478, 1, 2, '2025-01-09', 'AI PIC 337');

CALL sow_new_ai_entry(324658, 1, 2, '2025-02-06', 'AI PIC 337');
CALL sow_new_ai_entry(324658, 1, 2, '2025-02-24', 'AI PIC 337');

CALL pig_prod_add(1, 5, NULL, 1, 1800, 360, "load Elmer + gasolina", 2, "2025-09-10")





CALL sow_update_actual_birth_date(1, '2025-01-05', 4, 3, 6);
CALL sow_update_actual_birth_date(5, '2025-05-03', 1, 1, 2);
CALL sow_update_actual_birth_date(7, '2025-06-19', 1, 9, 5);
CALL sow_update_actual_birth_date(9, '2025-07-06', 2, 10, 10);

CALL pig_prod_update_birth(1, 13, '2025-09-10', 0, 5, 6, 2)



CALL pig_prod_notes_add(1, 1, "2024-09-11", "20 days gamay kaon after AI, sayop ni; dapat 5 days ra");
CALL pig_prod_notes_add(1, 1, "2024-11-29", "Iron dextran 2mL");
CALL pig_prod_notes_add(1, 1, "2024-12-20", "Ivermictin 2mL purga");
CALL pig_prod_notes_add(1, 1, "2025-01-01", "sugod bantay sa gabie");
CALL pig_prod_notes_add(1, 1, "2025-01-02", "Nagsugod ug langas ang baboy");
CALL pig_prod_notes_add(1, 1, "2025-01-03", "wala pa nanganak baboy");
CALL pig_prod_notes_add(1, 1, "2025-01-04", "Nanganak baboy 9PM  until kadlawon");
CALL pig_prod_notes_add(1, 1, "2025-01-05", "9 buhi, 2 patay baktin; 3 lake, 6 baye");
CALL pig_prod_notes_add(1, 1, "2025-01-05", "putol ngipon baktin");
CALL pig_prod_notes_add(1, 1, "2025-01-08", "Nanganak balik baboy 9PM, 2 still birth");
CALL pig_prod_notes_add(1, 1, "2025-01-08", "Hinay gatas sa anay");
CALL pig_prod_notes_add(1, 1, "2025-01-08", "Inject iron baktin");


CREATE PROCEDURE feed_buy_add(
    in_user_id              INT,
	
    in_pig_farm_id          INT,
    in_pig_prod_id          INT,
    in_prod_group_id        INT,
    
    in_date_buy             VARCHAR(10),
    in_feed_type_id         INT,
    in_feed_brand_id        INT,
    in_feed_supplier_id     INT,
    in_quantity             INT,
    in_kg_per_unit          DECIMAL(5,1),
    
    in_unit_cost            DECIMAL(8,2),
    in_total_cost           DECIMAL(8,2)
)  

CALL feed_buy_add(1, NULL, 5, NULL, '2025-05-09', 3, 1, 1, 1, 1, 75, 75);
CALL feed_buy_add(1, NULL, 5, NULL, '2025-05-28', 3, 1, 1, 2, 1, 75, 150);
CALL feed_buy_add(1, NULL, 5, NULL, '2025-06-02', 4, 1, 1, 2, 25, 1330, 2660);
CALL feed_buy_add(1, NULL, 5, NULL, '2025-06-23', 5, 1, 1, 3, 50, 1865, 5595);
CALL feed_buy_add(1, NULL, 5, NULL, '2025-07-31', 6, 1, 1, 6, 50, 1700, 10200);
CALL feed_buy_add(1, NULL, 5, NULL, '2025-09-02', 7, 1, 1, 3, 50, 1575, 4725);



CALL feed_buy_add(1, NULL, 7, NULL, '2025-06-23', 2, 1, 1, 2, 50, 1670, 3340);
CALL feed_buy_add(1, NULL, 7, NULL, '2025-06-23', 3, 1, 1, 10, 1, 75, 750);
CALL feed_buy_add(1, NULL, 7, NULL, '2025-07-05', 3, 1, 1, 10, 1, 75, 750);
CALL feed_buy_add(1, NULL, 7, NULL, '2025-07-17', 4, 1, 1, 2, 25, 1320, 2640);
CALL feed_buy_add(1, NULL, 7, NULL, '2025-07-31', 5, 1, 1, 11, 50, 1850, 20350);
CALL feed_buy_add(1, NULL, 7, NULL, '2025-09-02', 6, 1, 1, 4, 50, 1700, 6800);
CALL feed_buy_add(1, NULL, 7, NULL, '2025-09-24', 6, 1, 1, 4, 50, 1700, 6800);


CALL feed_buy_add(1, NULL, 9, NULL, '2025-06-23', 2, 1, 1, 1, 50, 1670, 1670);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-07-17', 3, 1, 1, 10, 1, 75, 750);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-07-31', 3, 1, 1, 10, 1, 75, 750);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-08-01', 2, 1, 2, 1, 50, 1615, 1615);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-08-14', 2, 1, 1, 1, 50, 1670, 1670);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-07-31', 4, 1, 1, 2, 25, 1320, 2640);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-07-31', 5, 1, 1, 6, 50, 1850, 11100);

CALL feed_buy_add(1, NULL, 13, NULL, '2025-09-02', 2, 1, 1, 2, 50, 1670, 3340);
CALL feed_buy_add(1, NULL, 13, NULL, '2025-09-20', 3, 1, 1, 10, 1, 75, 750);


CALL feed_buy_add(1, NULL, 9, NULL,  '2025-09-10', 5, 1, 1, 5, 50, 1850, 9250);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-09-12', 5, 1, 1, 1, 50, 1850, 1850);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-09-24', 5, 1, 1, 4, 50, 1850, 7400);

CALL feed_buy_add(1, 1, NULL, NULL,  '2025-09-17', 7, 1, 1, 2, 50, 1575, 3150);


CREATE PROCEDURE pig_prod_feed_bal_add(
    in_user_id              INT,
    in_pig_prod_id          INT,
    in_pig_prod_group_id    INT,
    
    in_date_balance         VARCHAR(10),
    
    in_num_pigs             INT,
    
    in_num_lactating        DECIMAL(5,1),
    in_num_booster          DECIMAL(5,1),
    in_num_prestarter       DECIMAL(5,1),
    in_num_starter          DECIMAL(5,1),
    in_num_grower           DECIMAL(5,1),
    in_num_finisher         DECIMAL(5,1)
) 


CALL feed_balance_add(1,  5, NULL, '2025-08-09',  3, 0,   0, 0,     0,  4.5,  NULL);
CALL feed_balance_add(1,  7, NULL, '2025-08-09', 11, 0,   0, 0,  10.5,  NULL , NULL);
CALL feed_balance_add(1,  9, NULL, '2025-08-09', 17, 0.1, 0, 1.5,   6,  NULL , NULL);
CALL sow_boar_balance_add(1,  1,   '2025-08-09', 3.5, NULL);

CALL feed_balance_add(1,  5, NULL, '2025-08-16',  3,  0,   0, 0,     0,  4.0,  NULL);
CALL feed_balance_add(1,  7, NULL, '2025-08-16', 11,  0,   0, 0,     9,  NULL, NULL);
CALL feed_balance_add(1,  9, NULL, '2025-08-16', 17,  0.5, 0, 1,     6,  NULL, NULL);
CALL sow_boar_balance_add(1,  1,  '2025-08-16', 2, NULL);

CALL feed_balance_add(1,  5, NULL, '2025-08-23',  3,  0,   0, 0,     0,  3.0, NULL);
CALL feed_balance_add(1,  7, NULL, '2025-08-23', 11,  0,   0, 0,     8,  NULL, NULL);
CALL feed_balance_add(1,  9, NULL, '2025-08-23', 16,  0,   0, 0,     6,  NULL, NULL);
CALL sow_boar_balance_add(1,  1,   '2025-08-23', 2, NULL);

CALL feed_balance_add(1,  5, NULL, '2025-08-30',  3,  0,   0, 0,     0,  2.0, NULL);
CALL feed_balance_add(1,  7, NULL, '2025-08-30', 11,  0,   0, 0,     6,  NULL, NULL);
CALL feed_balance_add(1,  9, NULL, '2025-08-30', 16,  0,   0, 0,     5,  NULL, NULL);
CALL sow_boar_balance_add(1,  1,  '2025-08-30', 1, NULL);


CALL feed_balance_add(1,  5, NULL, '2025-09-06',  3,  0,   0, 0,     0,  0.5,  3);
CALL feed_balance_add(1,  7, NULL, '2025-09-06', 11,  0,   0, 0,     4,  4,    NULL);
CALL feed_balance_add(1,  9, NULL, '2025-09-06', 16,  0,   0, 0,     3,  NULL, NULL);
CALL feed_balance_add(1, 13, NULL, '2025-09-06', 0,   2, NULL, NULL,  NULL, NULL, NULL);
CALL sow_boar_balance_add(1,  1,  '2025-09-06', 3.5, NULL);


/* to update number lactating sows */
CALL sow_boar_balance_add(1,  1,  '2025-09-11', 3.5, NULL);


CALL feed_balance_add(1,  5, NULL, '2025-09-13',  3,  0,   0, 0,     0,  0,    2);
CALL feed_balance_add(1,  7, NULL, '2025-09-13', 11,  0,   0, 0,     1,  4,    NULL);
CALL feed_balance_add(1,  9, NULL, '2025-09-13', 16,  0,   0, 0,     6,  NULL, NULL);
CALL feed_balance_add(1, 13, NULL, '2025-09-13', 11,   1.5, NULL, NULL,  NULL, NULL, NULL);
CALL sow_boar_balance_add(1,  1,  '2025-09-13', 2, NULL);


CALL feed_balance_add(1,  5, NULL, '2025-09-20',  2,  0,   0, 0,     0,  0,    1);
CALL feed_balance_add(1,  7, NULL, '2025-09-20', 11,  0,   0, 0,     0,  2,    NULL);
CALL feed_balance_add(1,  9, NULL, '2025-09-20', 16,  0,   0, 0,     3,  NULL, NULL);
CALL feed_balance_add(1, 13, NULL, '2025-09-20', 11,   1, NULL, NULL,  NULL, NULL, NULL);
CALL sow_boar_balance_add(1,  1,  '2025-09-20', 2, 2);





  
CALL pig_prod_update_feed_type(1, 5, 7, '2025-09-11')
CALL pig_prod_update_feed_type(1, 7, 6, '2025-09-17')


CALL account_pig_buyer_add(1, 1, 49, 1013, 27033, "Meloy Requinto", NULL, NULL, NULL);

CALL production_harvest_add(1,5,NULL,1, '2025-09-19', 1, NULL, 78.6, 77.6, NULL, 200, 15320,200, 'plete');

















