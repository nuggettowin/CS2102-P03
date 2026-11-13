-- Test 1: Add container without any position (constraint violation)
BEGIN;
    INSERT INTO container(iso_6346, content, company_code)
    VALUES ('ADI9999999', 'hopes and dreams', 'ADI');
COMMIT;

-- Should show nothing
SELECT *
FROM container c
WHERE c.iso_6346 = 'ADI9999999';

-- Test 2: Remove container from ship without removing it completely (constraint violation)
BEGIN;
    DELETE FROM loaded_on WHERE iso_6346 = 'ADIU2345489';
COMMIT;

-- Should show '255806008'
SELECT l.mmsi
FROM loaded_on l
WHERE l.iso_6346 = 'ADIU2345489';

-- Test 3: Remove container from ship and removing it completely (no constraint violation)
BEGIN;
    DELETE FROM loaded_on WHERE iso_6346 = 'ADIU2345489';
    DELETE FROM container WHERE iso_6346 = 'ADIU2345489';
    -- you could technically delete from the contatiner straight away as the 
    -- deletion is cascading, but this adheres to the test requirements better
COMMIT;

-- Should show nothing
SELECT l.mmsi
FROM loaded_on l
WHERE l.iso_6346 = 'ADIU2345489';

-- Test 4: Remove container from yard without removing it completely (constraint violation)
BEGIN;
    DELETE FROM stored_at WHERE iso_6346 = 'ADIU5734663';
COMMIT;

-- Should show ("Y", 1, 1, 3)
SELECT s.code, s.bay, s.row, s.tier
FROM stored_at s
WHERE s.iso_6346 = 'ADIU5734663';

-- Test 5: Remove container from yard and removing it completely (no constraint violation)
BEGIN;
    DELETE FROM loaded_on WHERE iso_6346 = 'ADIU5734663';
    DELETE FROM container WHERE iso_6346 = 'ADIU5734663';
    -- same comment as Test 3
COMMIT;

-- Should show nothing
SELECT s.code, s.bay, s.row, s.tier
FROM stored_at s
WHERE s.iso_6346 = 'ADIU5734663';


-- Test 6: Add existing ship container to a yard (constraint violation)
BEGIN;
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('ADIU2345489', 1, 0, 1, 'Y');
COMMIT;

-- Should show nothing
SELECT s.code, s.bay, s.row, s.tier
FROM stored_at s
WHERE s.iso_6346 = 'ADIU2345489';


-- Test 7: Add existing yard container to a ship (constraint violation)
BEGIN;
    INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('ADIU5734663', '255806008');
COMMIT;

-- Should show nothing
SELECT l.mmsi
FROM loaded_on l
WHERE l.iso_6346 = 'ADIU5734663';

-- Test 8: Move ship container to valid yard location (no constraint violation)
BEGIN;
    DELETE FROM loaded_on WHERE iso_6346 = 'ADIU6709357';
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('ADIU6709357', 1, 0, 1, 'Y');
COMMIT;

-- Should show ("Y", 1, 0, 1)
SELECT s.code, s.bay, s.row, s.tier
FROM stored_at s
WHERE s.iso_6346 = 'ADIU6709357';

-- Test 9: Move topmost yard container to a ship (no constraint violation)
BEGIN;
    DELETE FROM stored_at WHERE iso_6346 = 'ADIU5734663';
	INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('ADIU5734663', '255806008');
COMMIT;

-- Should show 255806008
SELECT l.mmsi
FROM loaded_on l
WHERE l.iso_6346 = 'ADIU5734663';

-- Test 10: Move non-top yard container (constraint violation)
BEGIN;
    DELETE FROM stored_at WHERE iso_6346 = 'ADIU9767874';
	INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('ADIU9767874', '255806008');
COMMIT;

-- Should show nothing
SELECT l.mmsi
FROM loaded_on l
WHERE l.iso_6346 = 'ADIU9767874';


-- Test 11: Move a ship container to a location above the maximum tier
BEGIN;
    DELETE FROM loaded_on WHERE iso_6346 = 'ADIU2345489';
    INSERT INTO position (bay, row, tier, code)
    VALUES (1, 1, 4, 'Y');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('ADIU2345489', 1, 1, 4, 'Y');
COMMIT;

-- Should show nothing
SELECT s.code, s.bay, s.row, s.tier
FROM stored_at s
WHERE s.iso_6346 = 'ADIU2345489';

-- Test 12: Move topmost yard container to another valid yard location (no constraint violation)
BEGIN;
    UPDATE stored_at 
    SET bay = 1, row = 0, tier = 1, code = 'Y' 
    WHERE iso_6346 = 'ADIU5734663';
COMMIT;

-- Should show ("Y", 1, 0, 1)
SELECT s.code, s.bay, s.row, s.tier
FROM stored_at s
WHERE s.iso_6346 = 'ADIU5734663';

-- Test 13: Increase tier of a topmost container (constraint violation)
BEGIN;
    UPDATE stored_at
    SET bay = 0, row = 0, tier = 3, code = 'Y'
    WHERE iso_6346 = 'ADIU7583471';
COMMIT;

-- Should show ("Y", 0, 0, 2)
SELECT s.code, s.bay, s.row, s.tier
FROM stored_at s
WHERE s.iso_6346 = 'ADIU7583471';

-- Test 14: Reduce the maximum tier of a yard (constraint violation)
BEGIN;
    UPDATE category
    SET max_tier = max_tier - 2
    WHERE category_type = 'Simple';
COMMIT;

-- Should show 3 still
SELECT c.max_tier
FROM category c, yard Y
WHERE y.category_type = c.category_type
    AND y.code = 'Y' 

-- Test 15: Increase the maximum tier of a yard (no constraint violation)
BEGIN;
    UPDATE category
    SET max_tier = 10
    WHERE category_type = 'Simple';
COMMIT;

-- Should show 10 now
SELECT c.max_tier
FROM category c, yard Y
WHERE y.category_type = c.category_type
    AND y.code = 'Y' 
