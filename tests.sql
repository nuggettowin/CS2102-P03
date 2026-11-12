/* TEST #1 OPERATION */
BEGIN;
INSERT INTO container (iso_6346, content, company_code)
VALUES ('ADIU9999999', 'parts', 'ADI');
COMMIT;

/* TEST #1 QUERY */
SELECT * FROM container WHERE iso_6346 = 'ADIU9999999';

/* TEST #1 END */


/* TEST #2 OPERATION */
BEGIN;
DELETE FROM loaded_on WHERE iso_6346 = 'ADIU2345489';
COMMIT;

/* TEST #2 QUERY */
SELECT mmsi FROM loaded_on WHERE iso_6346 = 'ADIU2345489';

/* TEST #2 END */


/* TEST #3 OPERATION */
BEGIN;
DELETE FROM container WHERE iso_6346 = 'ADIU2345489';
COMMIT;

/* TEST #3 QUERY */
SELECT mmsi FROM loaded_on WHERE iso_6346 = 'ADIU2345489';

/* TEST #3 END */


/* TEST #4 OPERATION */
BEGIN;
DELETE FROM stored_at WHERE iso_6346 = 'ADIU5734663';
COMMIT;

/* TEST #4 QUERY */
SELECT code, bay, row, tier FROM stored_at WHERE iso_6346 = 'ADIU5734663';

/* TEST #4 END */


/* TEST #5 OPERATION */
BEGIN;
DELETE FROM container WHERE iso_6346 = 'ADIU5734663';
COMMIT;

/* TEST #5 QUERY */
SELECT code, bay, row, tier FROM stored_at WHERE iso_6346 = 'ADIU5734663';

/* TEST #5 END */


/* TEST #6 OPERATION */
BEGIN;
INSERT INTO stored_at (iso_6346, code, bay, row, tier)
VALUES ('ADIU2345489', 'Y', 1, 0, 1);
COMMIT;

/* TEST #6 QUERY */
SELECT code, bay, row, tier FROM stored_at WHERE iso_6346 = 'ADIU2345489';

/* TEST #6 END */


/* TEST #7 OPERATION */
BEGIN;
INSERT INTO loaded_on (iso_6346, mmsi)
VALUES ('ADIU5734663', '255806008');
COMMIT;

/* TEST #7 QUERY */
SELECT mmsi FROM loaded_on WHERE iso_6346 = 'ADIU5734663';

/* TEST #7 END */


/* TEST #8 OPERATION */
BEGIN;
DELETE FROM loaded_on WHERE iso_6346 = 'ADIU6709357';
INSERT INTO stored_at (iso_6346, code, bay, row, tier)
VALUES ('ADIU6709357', 'Y', 1, 0, 1);
COMMIT;

/* TEST #8 QUERY */
SELECT code, bay, row, tier FROM stored_at WHERE iso_6346 = 'ADIU6709357';

/* TEST #8 END */


/* TEST #9 OPERATION */
BEGIN;
DELETE FROM stored_at WHERE iso_6346 = 'ADIU5734663';
INSERT INTO loaded_on (iso_6346, mmsi)
VALUES ('ADIU5734663', '255806008');
COMMIT;

/* TEST #9 QUERY */
SELECT mmsi FROM loaded_on WHERE iso_6346 = 'ADIU5734663';

/* TEST #9 END */


/* TEST #10 OPERATION */
BEGIN;
DELETE FROM stored_at WHERE iso_6346 = 'ADIU9767874';
INSERT INTO loaded_on (iso_6346, mmsi)
VALUES ('ADIU9767874', '255806008');
COMMIT;

/* TEST #10 QUERY */
SELECT mmsi FROM loaded_on WHERE iso_6346 = 'ADIU9767874';

/* TEST #10 END */


/* TEST #11 OPERATION */
BEGIN;
-- A position row lets the move reach the maximum-tier trigger at commit.
INSERT INTO position (code, bay, row, tier) VALUES ('Y', 1, 1, 4);
DELETE FROM loaded_on WHERE iso_6346 = 'ADIU2345489';
INSERT INTO stored_at (iso_6346, code, bay, row, tier)
VALUES ('ADIU2345489', 'Y', 1, 1, 4);
COMMIT;

/* TEST #11 QUERY */
SELECT code, bay, row, tier FROM stored_at WHERE iso_6346 = 'ADIU2345489';

/* TEST #11 END */


/* TEST #12 OPERATION */
BEGIN;
UPDATE stored_at
SET code = 'Y', bay = 1, row = 0, tier = 1
WHERE iso_6346 = 'ADIU5734663';
COMMIT;

/* TEST #12 QUERY */
SELECT code, bay, row, tier FROM stored_at WHERE iso_6346 = 'ADIU5734663';

/* TEST #12 END */


/* TEST #13 OPERATION */
BEGIN;
UPDATE stored_at SET tier = tier + 1 WHERE iso_6346 = 'ADIU7583471';
COMMIT;

/* TEST #13 QUERY */
SELECT code, bay, row, tier FROM stored_at WHERE iso_6346 = 'ADIU7583471';

/* TEST #13 END */


/* TEST #14 OPERATION */
BEGIN;
UPDATE category c
SET max_tier = c.max_tier - 2
FROM yard y
WHERE y.code = 'Y' AND y.category_type = c.category_type;
COMMIT;

/* TEST #14 QUERY */
SELECT c.max_tier
FROM category c JOIN yard y ON y.category_type = c.category_type
WHERE y.code = 'Y';

/* TEST #14 END */


/* TEST #15 OPERATION */
BEGIN;
UPDATE category c
SET max_tier = 10
FROM yard y
WHERE y.code = 'Y' AND y.category_type = c.category_type;
COMMIT;

/* TEST #15 QUERY */
SELECT c.max_tier
FROM category c JOIN yard y ON y.category_type = c.category_type
WHERE y.code = 'Y';

/* TEST #15 END */
