-- Rebuild the assignment test database before each independent test.
BEGIN;

-- The P03 foreign keys cascade these deletions to the dependent tables.
DELETE FROM container;
DELETE FROM berth;
DELETE FROM category;
DELETE FROM country;

-- 1. Create yard Y with two bays, two rows and three tiers.
INSERT INTO category (category_type, max_tier)
VALUES ('Simple', 3);

INSERT INTO yard (code, category_type)
VALUES ('Y', 'Simple');

INSERT INTO position (code, bay, row, tier)
VALUES
    ('Y', 0, 0, 1), ('Y', 0, 0, 2), ('Y', 0, 0, 3),
    ('Y', 0, 1, 1), ('Y', 0, 1, 2), ('Y', 0, 1, 3),
    ('Y', 1, 0, 1), ('Y', 1, 0, 2), ('Y', 1, 0, 3),
    ('Y', 1, 1, 1), ('Y', 1, 1, 2), ('Y', 1, 1, 3);

-- 2. Create the two berths.
INSERT INTO berth (code, longitude, latitude)
VALUES ('B1', 0, 0), ('B2', 0, 1);

-- 3. Register the container owner.
INSERT INTO country (name, continent)
VALUES ('Singapore', 'Asia');

INSERT INTO city (name, country_name)
VALUES ('Singapore', 'Singapore');

INSERT INTO company (company_code, name, address, postal_code, city_name, country_name)
VALUES ('ADI', 'Apasaja Distribution International', 'Apasaja Street', '10086',
        'Singapore', 'Singapore');

-- 4. The first ship arrives at B1 with its container.
INSERT INTO ship (mmsi, imo_number, call_sign, name, width, length, berth_code)
VALUES ('211382280', '9229843', '5LJY5', 'ship1', 30, 100, 'B1');

INSERT INTO container (iso_6346, content, company_code)
VALUES ('ADIU4974982', 'shoes', 'ADI');

INSERT INTO loaded_on (iso_6346, mmsi)
VALUES ('ADIU4974982', '211382280');

-- 5. The second ship arrives at B2 with its container.
INSERT INTO ship (mmsi, imo_number, call_sign, name, width, length, berth_code)
VALUES ('209912000', '9261889', '5BLP5', 'ship2', 40, 150, 'B2');

INSERT INTO container (iso_6346, content, company_code)
VALUES ('ADIU7385836', 'clothes', 'ADI');

INSERT INTO loaded_on (iso_6346, mmsi)
VALUES ('ADIU7385836', '209912000');

-- 6. Unload the first container at the bottom of stack (0, 0).
DELETE FROM loaded_on WHERE iso_6346 = 'ADIU4974982';

INSERT INTO stored_at (iso_6346, code, bay, row, tier)
VALUES ('ADIU4974982', 'Y', 0, 0, 1);

-- 7. The first ship leaves B1.
DELETE FROM ship WHERE mmsi = '211382280';

-- 8. The third ship arrives at B1 with its container.
INSERT INTO ship (mmsi, imo_number, call_sign, name, width, length, berth_code)
VALUES ('255806008', '9277400', '3FIV6', 'ship3', 20, 60, 'B1');

INSERT INTO container (iso_6346, content, company_code)
VALUES ('ADIU7583471', 'boxes', 'ADI');

INSERT INTO loaded_on (iso_6346, mmsi)
VALUES ('ADIU7583471', '255806008');

-- 9. The second ship leaves with its remaining cargo.
DELETE FROM container c
USING loaded_on l
WHERE c.iso_6346 = l.iso_6346 AND l.mmsi = '209912000';

DELETE FROM ship WHERE mmsi = '209912000';

-- 10. Unload the third ship's container onto tier 2 of stack (0, 0).
DELETE FROM loaded_on WHERE iso_6346 = 'ADIU7583471';

INSERT INTO stored_at (iso_6346, code, bay, row, tier)
VALUES ('ADIU7583471', 'Y', 0, 0, 2);

-- Additional containers aboard the ship still at B1.
INSERT INTO container (iso_6346, content, company_code)
VALUES
    ('ADIU2345489', 'books', 'ADI'),
    ('ADIU6709357', 'tools', 'ADI'),
    ('ADIU5837752', 'toys', 'ADI');

INSERT INTO loaded_on (iso_6346, mmsi)
VALUES
    ('ADIU2345489', '255806008'),
    ('ADIU6709357', '255806008'),
    ('ADIU5837752', '255806008');

-- Additional containers fill stack (1, 1) from the ground up.
INSERT INTO container (iso_6346, content, company_code)
VALUES
    ('ADIU9767874', 'paper', 'ADI'),
    ('ADIU7434763', 'fabric', 'ADI'),
    ('ADIU5734663', 'parts', 'ADI');

INSERT INTO stored_at (iso_6346, code, bay, row, tier)
VALUES
    ('ADIU9767874', 'Y', 1, 1, 1),
    ('ADIU7434763', 'Y', 1, 1, 2),
    ('ADIU5734663', 'Y', 1, 1, 3);

COMMIT;
