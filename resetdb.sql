-- operation 1
INSERT INTO category (category_type, max_tier)
VALUES ('Simple', 3);

INSERT INTO yard (code, category_type)
VALUES ('Y', 'Simple');

INSERT INTO position (bay, row, tier, code)
VALUES 
	(0, 0, 1, 'Y'),
	(0, 1, 1, 'Y'),
	(1, 0, 1, 'Y'),
	(1, 1, 1, 'Y'),
	(0, 0, 2, 'Y'),
	(0, 1, 2, 'Y'),
	(1, 0, 2, 'Y'),
	(1, 1, 2, 'Y'),
	(0, 0, 3, 'Y'),
	(0, 1, 3, 'Y'),
	(1, 0, 3, 'Y'),
	(1, 1, 3, 'Y');

-- operation 2
INSERT INTO berth (longitude, latitude, code)
VALUES 
	(0, 0, 'B1'),
	(0, 1, 'B2');

-- operation 3
INSERT INTO country (name, continent)
VALUES ('Singapore', 'Asia');

INSERT INTO city (name, country_name)
VALUES ('Singapore', 'Singapore');

INSERT INTO company (company_code, name, address, postal_code, city_name, country_name)
VALUES ('ADI', 'Apasaja Distribution International', 'Apasaja Street', '10086', 'Singapore', 'Singapore');

-- operation 4
INSERT INTO ship(mmsi, imo_number, call_sign, name, width, length, berth_code)
VALUES ( '211382280', '9229843', '5LJY5', 'ship1', 30, 100, 'B1');

BEGIN;
    INSERT INTO container(iso_6346, content, company_code)
    VALUES ('ADIU4974982', 'shoes', 'ADI');
    INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('ADIU4974982', '211382280');
COMMIT;

-- operation 5
INSERT INTO ship(mmsi, imo_number, call_sign, name, width, length, berth_code)
VALUES ('209912000', '9261889', '5BLP5', 'ship2', 40, 150, 'B2');

BEGIN;
    INSERT INTO container(iso_6346, content, company_code)
    VALUES ('ADIU7385836', 'clothes', 'ADI');
    INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('ADIU7385836', '209912000');
COMMIT;

-- operation 6
BEGIN;
    DELETE FROM loaded_on WHERE iso_6346 = 'ADIU4974982';
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('ADIU4974982', 0, 0, 1, 'Y');
COMMIT;

-- operation 7
DELETE FROM ship WHERE mmsi = '211382280';


-- operation 8
INSERT INTO ship (mmsi, imo_number, call_sign, name, width, length,	berth_code)
VALUES ('255806008', '9277400',	'3FIV6', 'ship3', 20, 60, 'B1');
BEGIN;
    INSERT INTO container(iso_6346, content, company_code)
    VALUES ('ADIU7583471', 'clothes', 'ADI');
    INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('ADIU7583471', '255806008');
COMMIT;

-- operation 9
BEGIN;
    DELETE FROM ship WHERE mmsi = '209912000';
    DELETE FROM container WHERE iso_6346 = 'ADIU7385836';
COMMIT;

-- operation 10
BEGIN;
    DELETE FROM loaded_on WHERE iso_6346 = 'ADIU7583471';
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('ADIU7583471', 0, 0, 2, 'Y');
COMMIT;

-- additional data 1
BEGIN;
    INSERT INTO container(iso_6346, content, company_code)
    VALUES ('ADIU2345489', 'plushies', 'ADI');
    INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('ADIU2345489', '255806008');
    INSERT INTO container(iso_6346, content, company_code)
    VALUES ('ADIU6709357', 'rams', 'ADI');
    INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('ADIU6709357', '255806008');
    INSERT INTO container(iso_6346, content, company_code)
    VALUES ('ADIU5837752', 'the constitution', 'ADI');
    INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('ADIU5837752', '255806008');
COMMIT;

BEGIN;
    INSERT INTO container(iso_6346, content, company_code)
    VALUES ('ADIU9767874', 'pianos', 'ADI');
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('ADIU9767874', 1, 1, 1, 'Y');
    INSERT INTO container(iso_6346, content, company_code)
    VALUES ('ADIU7434763', 'debt', 'ADI');
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('ADIU7434763', 1, 1, 2, 'Y');
    INSERT INTO container(iso_6346, content, company_code)
    VALUES ('ADIU5734663', 'my sanity', 'ADI');
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('ADIU5734663', 1, 1, 3, 'Y');
COMMIT;
