
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
CALL pig_prod_add(1, 5, NULL, 2, 1800, 0, "", 2, "2025-10-08");
CALL pig_prod_add(1, 1, 6, NULL, 0, 0, "", 2, "2025-11-06");
CALL pig_prod_add(1, 3, 6, NULL, 0, 0, "", 2, "2025-11-06");


CALL pig_prod_add(1, 7, 12, NULL, NULL, NULL, 0, 0, "Pirmerong Takal Desidido+Kurdapya", 2, 0, "2026-01-18");


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
CALL feed_buy_add(1, NULL, 7, NULL, '2025-09-24', 6, 1, 1, 6, 50, 1700, 10200);
CALL feed_buy_add(1, NULL, 7, NULL, '2025-10-03', 6, 1, 1, 4, 50, 1700, 6800);
CALL feed_buy_add(1, NULL, 7, NULL, '2025-10-10', 6, 1, 1, 8, 50, 1700, 13600);
CALL feed_buy_add(1, NULL, 7, NULL, '2025-10-13', 7, 1, 1, 4, 50, 1575, 6300);
CALL feed_buy_add(1, NULL, 7, NULL, '2025-10-27', 7, 1, 2, 7, 50, 1555, 10885);


CALL feed_buy_add(1, NULL, 9, NULL, '2025-06-23', 2, 1, 1, 1, 50, 1670, 1670);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-07-17', 3, 1, 1, 10, 1, 75, 750);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-07-31', 3, 1, 1, 10, 1, 75, 750);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-08-01', 2, 1, 2, 1, 50, 1615, 1615);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-08-14', 2, 1, 1, 1, 50, 1670, 1670);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-07-31', 4, 1, 1, 2, 25, 1320, 2640);
CALL feed_buy_add(1, NULL, 9, NULL, '2025-07-31', 5, 1, 1, 6, 50, 1850, 11100);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-09-10', 5, 1, 1, 5, 50, 1850, 9250);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-09-12', 5, 1, 1, 1, 50, 1850, 1850);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-09-24', 5, 1, 1, 4, 50, 1850, 7400);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-10-03', 6, 1, 1, 4, 50, 1700, 6800);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-10-10', 6, 1, 1, 6, 50, 1700, 10200);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-10-13', 6, 1, 1, 8, 50, 1700, 13600);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-10-27', 6, 1, 2, 1, 50, 1680, 1680);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-11-01', 6, 1, 1, 13, 50, 1700, 22100);
CALL feed_buy_add(1, NULL, 9, NULL,  '2025-11-11', 7, 1, 1, 15, 50, 1555, 23325);


CALL feed_buy_add(1, NULL, 13, NULL, '2025-09-02', 2, 1, 1, 2, 50, 1670, 3340);
CALL feed_buy_add(1, NULL, 13, NULL, '2025-09-20', 3, 1, 1, 10, 1, 75, 750);
CALL feed_buy_add(1, NULL, 13, NULL, '2025-10-03', 4, 1, 1, 1, 25, 1350, 1350);
CALL feed_buy_add(1, NULL, 13, NULL, '2025-10-03', 2, 1, 1, 1, 50, 1670, 1670);
CALL feed_buy_add(1, NULL, 13, NULL, '2025-10-13', 5, 1, 1, 2, 50, 1865, 3730);
CALL feed_buy_add(1, NULL, 13, NULL, '2025-10-13', 5, 1, 1, 2, 50, 1865, 3730);
CALL feed_buy_add(1, NULL, 13, NULL, '2025-11-01', 5, 1, 1, 7, 50, 1865, 13055);
CALL feed_buy_add(1, NULL, 13, NULL, '2025-12-02', 6, 1, 2, 9, 50, 1680, 15120);
CALL feed_buy_add(1, NULL, 13, NULL, '2026-01-07', 6, 1, 1, 8, 50, 1700, 13600);
CALL feed_buy_add(1, NULL, 13, NULL, '2026-01-07', 7, 1, 1, 10, 50, 1575, 15750);


CALL feed_buy_add(1, NULL, 16, NULL, '2026-01-31', 2, 1, 1, 1, 50, 1670, 1670);
CALL feed_buy_add(1, NULL, 16, NULL, '2026-02-09', 2, 1, 1, 1, 50, 1670, 1670);
CALL feed_buy_add(1, NULL, 16, NULL, '2026-02-09', 3, 1, 1, 4, 1, 75, 300);
CALL feed_buy_add(1, NULL, 16, NULL, '2026-02-17', 3, 1, 1, 12, 1, 75, 1000);



CALL feed_buy_add(1, 1, NULL, NULL,  '2025-09-17', 7, 1, 1, 2, 50, 1575, 3150);
CALL feed_buy_add(1, 1, NULL, NULL,  '2025-10-01', 1, 1, 1, 5, 50, 1480, 7400);
CALL feed_buy_add(1, 1, NULL, NULL,  '2025-10-10', 7, 1, 1, 1, 50, 1575, 1575);
CALL feed_buy_add(1, 1, NULL, NULL,  '2025-10-27', 7, 1, 2, 2, 50, 1525, 3050);
CALL feed_buy_add(1, 1, NULL, NULL,  '2025-11-01', 7, 1, 1, 10, 50, 1575, 15750);
CALL feed_buy_add(1, 1, NULL, NULL,  '2025-12-02', 1, 1, 1, 6, 50, 1460, 8760);
CALL feed_buy_add(1, 1, NULL, NULL,  '2025-12-02', 7, 1, 1, 4, 50, 1575, 6300);
CALL feed_buy_add(1, 1, NULL, NULL,  '2025-12-02', 7, 1, 2, 11, 50, 1555, 17105);

CALL feed_buy_add(1, 1, NULL, NULL,  '2026-01-07', 1, 1, 1, 6, 50, 1460, 8760);
CALL feed_buy_add(1, 1, NULL, NULL,  '2026-01-07', 7, 1, 1, 4, 50, 1575, 6300);



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


CALL feed_balance_add(1,  5, NULL, '2025-09-27',  2,  0,   0, 0,     0,  0,    0);
CALL feed_balance_add(1,  7, NULL, '2025-09-27', 11,  0,   0, 0,     0,  4,    NULL);
CALL feed_balance_add(1,  9, NULL, '2025-09-27', 16,  0,   0, 0,     4,  NULL, NULL);
CALL feed_balance_add(1, 13, NULL, '2025-09-27', 11,   0.5, NULL, NULL,  NULL, NULL, NULL);
CALL sow_boar_balance_add(1,  1,  '2025-09-27', 1, 2);


CALL feed_balance_add(1,  7, NULL, '2025-10-04', 11,  0,   0, 0,     0,  4,    NULL);
CALL feed_balance_add(1,  9, NULL, '2025-10-04', 16,  0,   0, 0,     0,  3,    NULL);
CALL feed_balance_add(1, 13, NULL, '2025-10-04', 10,   1, 1, NULL,  NULL, NULL, NULL);
CALL sow_boar_balance_add(1,  1,  '2025-10-04', 5, 1);

CALL feed_balance_add(1,  7, NULL, '2025-10-11', 11,  0,   0, 0,     0,  7,    NULL);
CALL feed_balance_add(1,  9, NULL, '2025-10-11', 16,  0,   0, 0,     0,  6,    NULL);
CALL feed_balance_add(1, 13, NULL, '2025-10-11', 10,   0.5, 0, 1,  NULL, NULL, NULL);
CALL sow_boar_balance_add(1,  1,  '2025-10-11', 4, 2);


CALL feed_balance_add(1,  7, NULL, '2025-10-18', 11,  0,   0, 0,     0,  5,    NULL);
CALL feed_balance_add(1,  9, NULL, '2025-10-18', 16,  0,   0, 0,     0,  9,    NULL);
CALL feed_balance_add(1, 13, NULL, '2025-10-18', 10,  0,   0, 0.5,  NULL, NULL, NULL);
CALL sow_boar_balance_add(1,  1,  '2025-10-18', 3, 1);


CALL pig_prod_update_weaning(1,13,'2025-10-24',5,5,NULL);
CALL production_harvest_add(1,13,NULL,NULL,'2025-10-23', 1, NULL,NULL, NULL, NULL, NULL, NULL, NULL, NULL, "Bayad Butakal");

CALL feed_balance_add(1,  7, NULL, '2025-10-25', 11,  0,   0, 0,     0,  0,    4);
CALL feed_balance_add(1,  9, NULL, '2025-10-25', 16,  0,   0, 0,     0,  4,    NULL);
CALL feed_balance_add(1, 13, NULL, '2025-10-25',  9,  0,   0, 0,     2,  NULL, NULL);
CALL sow_boar_balance_add(1,  1,  '2025-10-25', 2, 0);


CALL feed_balance_add(1,  7, NULL, '2025-11-01', 11,  0,   0, 0,     0,  0,    5);
CALL feed_balance_add(1,  9, NULL, '2025-11-01', 16,  0,   0, 0,     0,  0.5,    NULL);
CALL feed_balance_add(1,  13, NULL, '2025-11-01', 9,  0,   0, 0,     1.5, NULL,    NULL);
CALL sow_boar_balance_add(1,  1,  '2025-11-01', 6, 10);


CALL feed_balance_add(1,  7, NULL, '2025-11-08', 11,  0,   0, 0,     0,  0,    0);
CALL feed_balance_add(1,  9, NULL, '2025-11-08', 16,  0,   0, 0,     0,  6,    NULL);
CALL feed_balance_add(1,  13, NULL, '2025-11-08', 9,  0,   0, 0,     8, NULL,    NULL);
CALL sow_boar_balance_add(1,  1,  '2025-11-08', 5, 10);
CALL sow_boar_balance_add(1,  1,  '2025-11-10', 5, 9);


CALL feed_balance_add(1,  9, NULL, '2025-11-15', 15,  0,   0, 0,     0,  0,    15);
CALL feed_balance_add(1,  13, NULL, '2025-11-15', 9,  0,   0, 0,     7, NULL,    NULL);
CALL sow_boar_balance_add(1,  1,  '2025-11-15', 4, 8);



CALL feed_balance_add(1,  9, NULL, '2025-11-22', 15,  0,   0, 0,     0,  0,    8);
CALL feed_balance_add(1,  13, NULL, '2025-11-22', 9,  0,   0, 0,     5.5, NULL,    NULL);
CALL sow_boar_balance_add(1,  1,  '2025-11-22', 2.5, 5);


CALL feed_balance_add(1,  9, NULL, '2025-11-29', 2,  0,   0, 0,     0,  0,    2);
CALL feed_balance_add(1,  13, NULL, '2025-11-29', 9,  0,   0, 0,     4, NULL,    NULL);
CALL sow_boar_balance_add(1,  1,  '2025-11-29', 1, 2);


CALL feed_balance_add(1,  13, NULL, '2025-12-06', 9,  0,   0, 0,     2, 9,    NULL);
CALL sow_boar_balance_add(1,  1,  '2025-12-06', 6, 17);

CALL feed_balance_add(1,  13, NULL, '2025-12-13', 9,  0,   0, 0,     0.5, 9,    NULL);
CALL sow_boar_balance_add(1,  1,  '2025-12-13', 5, 15);


CALL feed_balance_add(1,  13, NULL, '2025-12-20', 9,  0,   0, 0,     0, 7,    NULL);
CALL sow_boar_balance_add(1,  1,  '2025-12-20', 4, 12);


CALL feed_balance_add(1,  13, NULL, '2025-12-27', 9,  0,   0, 0,     0, 4,    NULL);
CALL sow_boar_balance_add(1,  1,  '2025-12-27', 2, 10);

CALL feed_balance_add(1,  13, NULL, '2026-01-03', 9,  0,   0, 0,     0, 1,    NULL);
CALL sow_boar_balance_add(1,  1,  '2026-01-03', 1, 7);


CALL feed_balance_add(1,  13, NULL, '2026-01-10', 9,  0,   0, 0,     0, 6,    8);
CALL sow_boar_balance_add(1,  1,  '2026-01-10', 6, 10);

CALL feed_balance_add(1,  13, NULL, '2026-01-17', 9,  0,   0, 0,     0, 2,    8);
CALL sow_boar_balance_add(1,  1,  '2026-01-17', 4.5, 8);

CALL feed_balance_add(1,  13, NULL, '2026-01-24', 9,  0,   0, 0,     0, 0,    7);
CALL sow_boar_balance_add(1,  1,  '2026-01-24', 3.5, 3.5);


CALL feed_balance_add(1,  13, NULL, '2026-01-31', 9,  0,   0, 0,     0, 0,    2);
CALL feed_balance_add(1,  16, NULL, '2026-01-31', 0,  1,   NULL, NULL,     NULL, NULL,    NULL);
CALL sow_boar_balance_add(1,  1,  '2026-01-31', 7, 12);


CALL feed_balance_add(1,  16, NULL, '2026-02-07', 0,  0.5,   NULL, NULL,     NULL, NULL,    NULL);
CALL sow_boar_balance_add(1,  1,  '2026-02-07', 6, 11);


CALL feed_balance_add(1,  16, NULL, '2026-02-14', 0,  1,   NULL, NULL,     NULL, NULL,    NULL);
CALL sow_boar_balance_add(1,  1,  '2026-02-14', 5.5, 9);


CALL feed_balance_add(1,  16, NULL, '2026-02-21', 0,  0.5,   NULL, NULL,     NULL, NULL,    NULL);
CALL sow_boar_balance_add(1,  1,  '2026-02-21', 4.5, 7.5);

  
CALL pig_prod_update_feed_type(1, 5, 7, '2025-09-11')
CALL pig_prod_update_feed_type(1, 7, 6, '2025-09-17')


CALL account_pig_buyer_add(1, 1, 49, 1013, 27033, "Meloy Requinto", NULL, NULL, NULL);
CALL account_pig_buyer_add(1, 1, 49, 1011, 0, "Mingla Lamesa Mangrasyon", NULL, NULL, NULL);
CALL account_pig_buyer_add(1, 1, 49, 1013, 0, "Ting Rasyon sa Naga merkado", NULL, NULL, NULL);
CALL account_pig_buyer_add(1, 1, 49, 1013, 27033, "Silingan Punod Namatyan", NULL, NULL, NULL);
CALL account_pig_buyer_add(1, 1, 49, 1013, 27033, "Silingan Punod Palit Anay", NULL, NULL, NULL);
CALL account_pig_buyer_add(1, 1, 49, 1004, 0, NULL, NULL, 0, "Nagbuhat sa Farrowing", NULL, NULL, NULL, NULL);



CREATE PROCEDURE production_harvest_add(
    in_user_id              INT,
    in_pig_prod_id          INT,
    in_production_group_id  INT,
    in_acc_pig_buyer_id     INT,
    
    in_date_harvest         VARCHAR(10),
    
    in_num_pigs_harvest     INT,
    in_harvest_type_id      INT,
    
    in_live_weight          DECIMAL(6,1),
    in_slaughter_weight     DECIMAL(6,1),
    in_slaughter_net_weight DECIMAL(6,1),
    
    in_live_price_per_unit          DECIMAL(6,1),
    in_slaughther_price_per_unit    DECIMAL(6,1),
    
    in_net_sales            DECIMAL(8,1),
    in_harvest_cost         DECIMAL(5,1),
    in_comments             VARCHAR(160)
)  


/* Harvested bayad sa butakal; harvest_type to be updated later*/
CALL production_harvest_add(1,5,NULL,1, '2025-09-19', 1, NULL, 78.6, 77.6, NULL, 200, 15320,200, 'plete');

/* Harvested as SOW/BOAR; harvest_type to be updated later*/
CALL production_harvest_add(1,5,NULL,NULL,'2025-09-27', 2, NULL,NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

/* Harvested rasyon mIngla*/
CALL production_harvest_add(1,7,NULL,2,'2025-11-10', 6, NULL,NULL,487,481,NULL,215,101615,NULL,NULL);

/* Harvested as 3 SOW, 2 Boar*/
CALL production_harvest_add(1,7,NULL,NULL,'2025-11-11', 5, NULL,NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


/* Harvested as internla cosumo kay nibuto ang posod; gitiwasan*/
CALL production_harvest_add(1,9,NULL,NULL,'2025-11-10', 1, NULL,NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


/* Harvested rasyon Naga*/
CALL production_harvest_add(1,9,NULL,3,'2025-11-26', 3, NULL,NULL,207,204,NULL,215,42810,1350,"plete baboy 350 isa, sakwat baboy 100 isa");

/* Harvested rasyon Silingan Punod*/
CALL production_harvest_add(1,9,NULL,4,'2025-11-28', 3, NULL,NULL,207,207,NULL,215,44505,0,"walay plete kay silingan");

/* Harvested rasyon Naga*/
CALL production_harvest_add(1,9,NULL,3,'2025-11-29', 7, NULL,NULL,525,518,NULL,215,108920,2450,"plete baboy 350 isa, sakwat baboy 100 isa");

/* Harvested Silingan anay*/
CALL production_harvest_add(1,9,NULL,5,'2025-12-02', 2, NULL,NULL,168,168,NULL,215,36120,0,"Gitupong ang timbangs a pinakabugat na narasyon");


/* Harvested rasyon Naga*/
CALL production_harvest_add(1,13,NULL,3,'2026-02-04', 6, NULL,NULL,412,412,NULL,210,86520,2700,"plete baboy 2100, sakwat baboy 600");


/* Harvested Danao palit  anay*/
CALL production_harvest_add(1,13,NULL,6,'2026-02-05', 3, NULL,NULL,234,234,NULL,210,49140,0,"Gitupong ang timbang sa pinakabugat na narasyon");




CALL semen_supplier_add(1,1,49,1013,27033, "Primary", NULL, NULL, NULL);

CALL semen_source_add(1,1,NULL, 2,2, "PIC337", "Semen AI from Primary")

CALL pig_prod_pig_dead_add(1, 13, NULL, "2025-10-01", 1, 1, "Nalisang anay sa linog, nadat ugan baktin")

CALL pig_prod_pig_dead_add(1, 16, NULL, "2026-02-27", 1, 1, "Wala ka survive ang luyahon")
CALL pig_prod_pig_dead_add(1, 16, NULL, "2026-02-28", 1, 1, "daot kaayo na baktin. wala ka survive")




CREATE PROCEDURE sow_boar_add(
    1,
    
    1,
    7,
    1,
    1,
    
    'F',
    0,
    
    NULL,
    'Medi',
    '2025-06-19',
    NULL
);

CALL sow_boar_add(
    1,
    
    1,
    7,
    1,
    1,
    
    'F',
    0,
    
    NULL,
    'Menang',
    '2025-06-19',
    NULL
);

CALL sow_boar_add(
    1,
    
    1,
    7,
    1,
    1,
    
    'F',
    0,
    
    NULL,
    'Ging2x',
    '2025-06-19',
    NULL
);


CALL sow_boar_add(
    1,
    
    1,
    7,
    1,
    1,
    
    'M',
    0,
    
    NULL,
    'Desidido',
    '2025-06-19',
    NULL
);

CALL sow_boar_add(
    1,
    
    1,
    7,
    1,
    1,
    
    'M',
    0,
    
    NULL,
    'Nanding',
    '2025-06-19',
    NULL
);
















