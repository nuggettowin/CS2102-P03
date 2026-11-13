-- Schema
CREATE TABLE category (
	category_type VARCHAR(50) PRIMARY KEY,
	max_tier INTEGER NOT NULL CHECK (max_tier >= 1)
);

CREATE TABLE yard (
	code VARCHAR(50) PRIMARY KEY,
	category_type VARCHAR(50) NOT NULL
	    REFERENCES category(category_type)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE
);

CREATE TABLE position(
	bay INTEGER CHECK (bay >= 0),
	row INTEGER CHECK (row >= 0),

	-- Tier should be limited to the max_tier of category,
	-- but this cannot be enforced without creating a foreign key to a non-minimal primary key
	-- since category_type is the minimal primary key of category.
	tier INTEGER CHECK (tier >= 1),
	code VARCHAR(50)
	    REFERENCES yard(code)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,
	PRIMARY KEY (bay, row, tier, code)
);

CREATE TABLE country (
	name VARCHAR(100) PRIMARY KEY, 
	continent VARCHAR(15) NOT NULL
);

CREATE TABLE city (
	name VARCHAR(200),
	country_name VARCHAR(60)
	    REFERENCES country (name)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,
	
	PRIMARY KEY (name, country_name)
);

CREATE TABLE company (
	company_code VARCHAR(50) PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	address VARCHAR(50) NOT NULL, 
	postal_code VARCHAR(50) NOT NULL,
	city_name VARCHAR(200) NOT NULL,
	country_name VARCHAR(60) NOT NULL,
	
	FOREIGN KEY (city_name, country_name)
	    REFERENCES city (name, country_name)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE
);

CREATE TABLE berth (
	longitude NUMERIC(8, 5) NOT NULL CHECK (longitude >= -180 AND longitude <=180),
	latitude NUMERIC(8, 5) NOT NULL CHECK (latitude >= -90 AND latitude <=90),
	
	-- The specification describes berth codes as natural numbers,
	-- but the required operations explicitly use codes 'B1' and 'B2'.
	-- VARCHAR is therefore used to support the prescribed operations.
	code VARCHAR(50) PRIMARY KEY,
	
	CONSTRAINT berth_position UNIQUE (longitude, latitude) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE ship (
    mmsi VARCHAR(9) PRIMARY KEY,
    imo_number VARCHAR(10) NOT NULL,
    call_sign VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    width DECIMAL(8, 2) NOT NULL CHECK (width > 0),
    length DECIMAL(8, 2) NOT NULL CHECK (length > 0),
    berth_code VARCHAR(50) NOT NULL,
    
    UNIQUE (imo_number) DEFERRABLE INITIALLY DEFERRED,
    UNIQUE (call_sign) DEFERRABLE INITIALLY DEFERRED,
    UNIQUE (berth_code) DEFERRABLE INITIALLY DEFERRED,
    
    FOREIGN KEY (berth_code)
        REFERENCES berth (code)
        ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE INITIALLY IMMEDIATE
);

-- Unable to enforce that container must be in either ship or yard.
CREATE TABLE container (
	iso_6346 VARCHAR(15) PRIMARY KEY, 
	content VARCHAR(50) NOT NULL,
	
	company_code VARCHAR(50) NOT NULL,	
	
	FOREIGN KEY (company_code)
	    REFERENCES company (company_code)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,

	-- Ownership is indicated by the first three letters of the
	-- container's ISO identification.
	CHECK (SUBSTRING(iso_6346 FROM 1 FOR 3) = company_code)
);

-- Unable to enforce that container cannot be stacked higher than the max tier of the yard,
-- and unable to enforce that a container is either on the ground or on top of another container.
CREATE TABLE stored_at (
	iso_6346 VARCHAR(15) PRIMARY KEY,
	FOREIGN KEY (iso_6346)
	    REFERENCES container (iso_6346)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,
	
	bay INTEGER NOT NULL,
	row INTEGER NOT NULL,
	tier INTEGER NOT NULL,
	code VARCHAR(50) NOT NULL,

	FOREIGN KEY (bay, row, tier, code)
	    REFERENCES position (bay, row, tier, code)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,
	
	CONSTRAINT yard_pos UNIQUE (bay, row, tier, code) DEFERRABLE INITIALLY IMMEDIATE
	
);

CREATE TABLE loaded_on (
	iso_6346 VARCHAR(15) PRIMARY KEY,
	FOREIGN KEY (iso_6346)
	    REFERENCES container (iso_6346)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,
	
	mmsi VARCHAR(9) NOT NULL,
	
	FOREIGN KEY (mmsi)
	    REFERENCES ship (mmsi)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE
);





-- Q1: There is no container that is neither on a ship nor in a yard
CREATE OR REPLACE FUNCTION verify_container_is_stored()
RETURNS TRIGGER
AS
$$
DECLARE
    target_iso VARCHAR(15);
BEGIN
    IF TG_OP = 'INSERT' THEN
        target_iso := NEW.iso_6346;
    ELSE
        target_iso := OLD.iso_6346;
    END IF;


    IF EXISTS (SELECT 1 FROM container c WHERE c.iso_6346 = target_iso) THEN
        IF NOT EXISTS (SELECT 1 FROM stored_at s WHERE s.iso_6346 = target_iso) 
           AND NOT EXISTS (SELECT 1 FROM loaded_on l WHERE l.iso_6346 = target_iso) THEN
            RAISE EXCEPTION 'Container % is neither on a ship nor in a yard', target_iso;
        END IF;
        
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER inserted_container_is_stored
AFTER INSERT ON container
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();

CREATE CONSTRAINT TRIGGER delete_stored_on_is_still_stored
AFTER UPDATE OR DELETE ON stored_at			
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();

CREATE CONSTRAINT TRIGGER delete_loaded_on_is_still_stored
AFTER UPDATE OR DELETE ON loaded_on
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();

-- Q2: A container must either be on a ship or in a yard (but not both).
-- We only need to check that it is not on both stored_at and loaded_on
-- as combined with the trigger from q1 we gurantee that the container is either
-- on a ship or on a yard

CREATE OR REPLACE FUNCTION verify_container_not_both()
RETURNS TRIGGER
AS
$$
BEGIN
    IF EXISTS (SELECT 1 FROM stored_at s WHERE s.iso_6346 = NEW.iso_6346) 
		AND EXISTS (SELECT 1 FROM loaded_on l WHERE l.iso_6346 = NEW.iso_6346) THEN
		RAISE EXCEPTION 'Container % cannot be both on a ship or at a yard', NEW.iso_6346;
	END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER modified_stored_at_not_both
AFTER INSERT OR UPDATE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_not_both();

CREATE CONSTRAINT TRIGGER modified_loaded_on_not_both
AFTER INSERT OR UPDATE ON loaded_on
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_not_both();



-- Q3: A container in a yard cannot be stacked higher than the maximum tier of that yard.

CREATE OR REPLACE FUNCTION verify_max_tiers()
RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM stored_at s
        JOIN yard y ON s.code = y.code
        JOIN category c ON y.category_type = c.category_type
        WHERE s.tier > c.max_tier
    ) THEN
        RAISE EXCEPTION 'Container cannot be stored at a tier higher than the maximum tier allowed for its yard category.';
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_max_tier_stored_at
AFTER INSERT OR UPDATE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_max_tiers();

CREATE CONSTRAINT TRIGGER check_max_tier_yard
AFTER UPDATE ON yard
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_max_tiers();

CREATE CONSTRAINT TRIGGER check_max_tier_category
AFTER UPDATE ON category
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_max_tiers();

-- Q4: A container in a yard is either on the ground or on top of another container
-- We just need to check that after the transaction, for every yard, every bay and row must have
-- the maximum tier equal the number of containers in that bay and row. This works because since bay
-- row and code are equal, tiers must be unique.

CREATE OR REPLACE FUNCTION verify_grounded_container()
RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM stored_at s
        GROUP BY s.code, s.bay, s.row
        HAVING MAX(s.tier) <> COUNT(s.tier)
    ) THEN
        RAISE EXCEPTION 'Container in a yard must either be on the ground or on top of another container';
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER stored_at_all_grounded
AFTER INSERT OR UPDATE OR DELETE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_grounded_container();

