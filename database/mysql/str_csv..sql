
DELIMITER $$

DROP FUNCTION IF EXISTS string_csv_count $$
CREATE FUNCTION string_csv_count(
    in_str          VARCHAR(10000), 
    in_delim        VARCHAR(2)
) RETURNS INT

/*
    This will count items in a csv string.
    Example:

    in_str = 'one, two, 3, 4, five';
    string_csv_count(in_str, ',') = 5
*/


BEGIN
    DECLARE temp            VARCHAR(100);
    DECLARE pos             INT;
    DECLARE item_count      INT;

    SET item_count = 0;

    IF in_str = '' THEN RETURN 0; END IF;



loop_here: LOOP
    SET pos     = INSTR(in_str, in_delim);
    SET temp    = SUBSTRING_INDEX(in_str, in_delim, 1);
    
    IF pos > 0 THEN
        SET item_count = item_count + 1;
        SET in_str = mid(in_str, pos+1, CHAR_LENGTH(in_str));
        ELSE LEAVE loop_here;

    END IF;

    IF item_count > 10000 THEN LEAVE loop_here; END IF;
    
END LOOP loop_here;
  
  
SET item_count = item_count + 1;
  
RETURN item_count;
END $$

DELIMITER ;




DELIMITER $$

DROP FUNCTION IF EXISTS string_array_item` $$
CREATE FUNCTION string_array_item`(in_str VARCHAR(10000), in_delim VARCHAR(10), daPos SMALLINT) RETURNS varchar(500)

BEGIN
  DECLARE pos SMALLINT;
  DECLARE dastr VARCHAR(100) DEFAULT '';
  DECLARE daCount SMALLINT;

  SET daCount = 0;

  IF in_str = "" THEN RETURN 0; END IF;


  loop_here: LOOP
    SET pos = instr(in_str, in_delim);
    SET dastr = SUBSTRING_INDEX(in_str, in_delim, 1);
    
    IF pos > 0 THEN
      SET daCount = daCount + 1;
      SET in_str = mid(in_str, pos+1, CHAR_LENGTH(in_str));
      ELSE LEAVE loop_here;
    END IF;
    
    IF in_str = "" THEN LEAVE loop_here; END IF;

    IF daCount = daPos THEN LEAVE loop_here; END IF;
    IF daCount > 10000 THEN LEAVE loop_here; END IF;
  END LOOP loop_here;
  
  
  RETURN dastr;
END $$

DELIMITER ;

