-- there is no container that is neither on a ship nor in a yard
CREATE OR REPLACE FUNCTION verify_container_is_stored()
RETURNS TRIGGER
AS
$$
BEGIN
	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		IF NOT EXISTS (SELECT * FROM stored_at s WHERE s.iso_6346 = NEW.iso_6346) AND NOT EXISTS (SELECT * FROM loaded_on loaded where loaded.iso_6346 = NEW.iso_6346) THEN
			RAISE EXCEPTION 'Container is neither on a ship nor in a yard';
		END IF;
	ELSE -- for deletion events only on the storage tables
		IF NOT EXISTS (SELECT * FROM stored_at s WHERE s.iso_6346 = OLD.iso_6346) AND NOT EXISTS (SELECT * FROM loaded_on loaded where loaded.iso_6346 = OLD.iso_6346) THEN
			RAISE EXCEPTION 'Container is neither on a ship nor in a yard';
		END IF;		
	END IF;
	RETURN NULL;
END;
$$
LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER on_insert_container
AFTER INSERT ON container 
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();


CREATE CONSTRAINT TRIGGER on_delete_or_update_stored_at
AFTER DELETE OR UPDATE ON stored_at 
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();

CREATE CONSTRAINT TRIGGER on_delete_or_update_loaded_on
AFTER DELETE OR UPDATE ON loaded_on 
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();

--Lifan: The current implementation fails at:  1. loaded_on  A stored_at  B, when you change A to B, current validates this transaction via NEW.iso_6346 = 'B', B has a location so it passes. but it should fail because A has no location.
-- 2.  insert container (iso_6346, content, company_code)  with VALUES ('XXX', 'YYY', 'ZZZ'); then delete from container where iso_6346 = 'XXX".   NEW.iso wont have a location, the AFTER INSERT still gets triggered even if its correct.
-- my proposed way:
-- BEGIN
--     IF TG_OP = 'INSERT' THEN
--         IF EXISTS (
--             SELECT 1 FROM container c
--             WHERE c.iso_6346 = NEW.iso_6346
--         )
--         AND NOT EXISTS (
--             SELECT 1 FROM stored_at s
--             WHERE s.iso_6346 = NEW.iso_6346
--         )
--         AND NOT EXISTS (
--             SELECT 1 FROM loaded_on l
--             WHERE l.iso_6346 = NEW.iso_6346
--         ) THEN
--             RAISE EXCEPTION 'Container is neither on a ship nor in a yard';
--         END IF;

--     ELSE
--         IF EXISTS (
--             SELECT 1 FROM container c
--             WHERE c.iso_6346 = OLD.iso_6346
--         )
--         AND NOT EXISTS (
--             SELECT 1 FROM stored_at s
--             WHERE s.iso_6346 = OLD.iso_6346
--         )
--         AND NOT EXISTS (
--             SELECT 1 FROM loaded_on l
--             WHERE l.iso_6346 = OLD.iso_6346
--         ) THEN
--             RAISE EXCEPTION 'Container is neither on a ship nor in a yard';
--         END IF;
--     END IF;

--     RETURN NULL;
-- END;
