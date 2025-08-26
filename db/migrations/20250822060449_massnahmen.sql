-- migrate:up
create table massnahmen(
    id uuid primary key default gen_random_uuid(),
    flaechen_id uuid not null references flaechen(id),
    name text not null,
    geometry geometry(point, 25833),
    angelegt_am date not null default now()
);

-- Trigger function: assign flaechen_id if missing and check containment
CREATE OR REPLACE FUNCTION check_massnahme_within_flaeche()
RETURNS trigger AS $$
DECLARE
    target_flaeche_id uuid;
BEGIN
    -- If flaechen_id is NULL, try to determine it based on geometry
    IF NEW.flaechen_id IS NULL THEN
        SELECT id INTO target_flaeche_id
        FROM flaechen
        WHERE ST_Within(NEW.geometry, geometry)
        LIMIT 1;

        IF target_flaeche_id IS NULL THEN
            RAISE EXCEPTION 'Massnahme liegt in keiner bekannten Fläche.';
        END IF;

        NEW.flaechen_id := target_flaeche_id;
    END IF;

    -- Check if the point lies within the given polygon
    IF NOT ST_Within(NEW.geometry, (SELECT f.geometry FROM flaechen f WHERE f.id = NEW.flaechen_id)) THEN
        RAISE EXCEPTION 'Massnahme (id=%) muss innerhalb der zugehörigen Fläche (id=%) liegen.', NEW.id, NEW.flaechen_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Attach trigger to table
CREATE TRIGGER trg_massnahme_within_flaeche
BEFORE INSERT OR UPDATE ON massnahmen
FOR EACH ROW
EXECUTE FUNCTION check_massnahme_within_flaeche();

CREATE OR REPLACE FUNCTION update_flaeche_art()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- On insert, set art to 'Potenzialfläche'
        UPDATE flaechen
        SET art = 'Potenzialfläche'
        WHERE id = NEW.flaechen_id;
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        -- On delete, check if there are any remaining related massnahmen
        IF NOT EXISTS (
            SELECT 1 FROM massnahmen WHERE flaechen_id = OLD.flaechen_id
        ) THEN
            UPDATE flaechen
            SET art = 'Denkfläche'
            WHERE id = OLD.flaechen_id;
        END IF;
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_massnahme_art
AFTER INSERT OR DELETE ON massnahmen
FOR EACH ROW
EXECUTE FUNCTION update_flaeche_art();
-- migrate:down
drop table massnahmen;
