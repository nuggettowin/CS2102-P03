-- A container must either be on a ship or in a yard (but not both).
-- insertion to at least ones is logically handled by q1 trigger 
-- this trigger should check whether if insert into container whether in both places

CREATE OR REPLACE FUNCTION verify_container_not_both()
RETURNS TRIGGER
AS
$$
BEGIN
	IF EXISTS (SELECT * from stored_at s WHERE s.iso_6346 = NEW.iso_6346) AND EXISTS (SELECT * from loaded_on ld WHERE ld.iso_6346 = NEW.iso_6346) THEN
		RAISE EXCEPTION 'Container must not be both on a ship and in a yard';
	END IF;
	RETURN NULL;
	
END;
$$
LANGUAGE plpgsql;


-- when container added, check not both
CREATE CONSTRAINT TRIGGER on_insert_container_both
AFTER INSERT ON container
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_not_both();

CREATE CONSTRAINT TRIGGER on_stored_at_modified
AFTER INSERT OR UPDATE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_not_both();

CREATE CONSTRAINT TRIGGER on_loaded_on_modified
AFTER INSERT OR UPDATE ON loaded_on
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_not_both();

-- Lifan: The first trigger is redundant.
-- AFTER INSERT ON container is unnecessary because inserting
-- a container alone cannot cause it to appear in both tables.
-- DELETE triggers are also unnecessary since deleting a location
-- cannot introduce simultaneous membership in both tables.
