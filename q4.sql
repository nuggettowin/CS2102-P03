-- A container in a yard is either on the ground or on top of another container
-- insert container check if tier = ground or exists container with tier-1
-- delete container check if not exists container with tier + 1
-- update container check if tier = ground or exists container with tier - 1 and if not exists container with tier + 1

CREATE OR REPLACE FUNCTION has_matching_stored_at
    (IN target_bay INTEGER, IN target_row INTEGER, IN target_tier INTEGER, IN target_code VARCHAR(50))
RETURNS BOOLEAN
AS $$

DECLARE
    has_match BOOLEAN;

BEGIN
    IF EXISTS (SELECT * FROM stored_at s WHERE s.bay = target_bay AND s.row = target_row AND s.tier = target_tier AND s.code = target_code) THEN
        has_match := TRUE;
    ELSE
        has_match := FALSE;
    END IF;

	RETURN has_match;

END;

$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION verify_consecutive_containers()
RETURNS TRIGGER AS
$$
BEGIN
	IF TG_OP = 'INSERT' THEN
		IF NEW.tier <> 1 AND NOT has_matching_stored_at(NEW.bay, NEW.row, NEW.tier - 1, NEW.code) THEN
			RAISE EXCEPTION 'Container in a yard must either be on the ground or on top of another container';
		END IF;

	ELSEIF (TG_OP = 'DELETE') THEN
        IF has_matching_stored_at(OLD.bay, OLD.row, OLD.tier + 1, OLD.code) THEN
			RAISE EXCEPTION 'Container in a yard must support a container on top of it, if there exists one such container';
		END IF;

	ELSE
        IF (NEW.tier <> 1 AND NOT has_matching_stored_at(NEW.bay, NEW.row, NEW.tier - 1, NEW.code)) OR has_matching_stored_at(OLD.bay, OLD.row, OLD.tier + 1, OLD.code) THEN
			RAISE EXCEPTION 'Container in a yard must either be on the ground or on top of another container, and must support a container on top of it, if there exists one such container';
		END IF;

	END IF;

	RETURN NULL;
END;
$$
LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER on_stored_at_loc_modified
AFTER INSERT OR DELETE OR UPDATE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_consecutive_containers();


--Lifan: In current implementation, this would be rejected: inserting tier 2, removing tier 2 and tier 1. the queued tier-2 insertion check will find no tier-1 support and incorrectly reject the transaction.
--My proposed sol: BEGIN
--     IF EXISTS (
--         SELECT 1
--         FROM stored_at s
--         WHERE s.tier > 1
--           AND NOT has_matching_stored_at(
--               s.bay,
--               s.row,
--               s.tier - 1,
--               s.code
--           )
--     ) THEN
--         RAISE EXCEPTION
--             'Container in a yard must be on the ground or supported by another container';
--     END IF;

--     RETURN NULL;
-- END;
