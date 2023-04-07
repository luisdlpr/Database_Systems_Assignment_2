-- COMP3311 23T1 Ass2 ... SQL helper Views/Functions
-- Add any views or functions you need into this file
-- Note: it must load without error into a freshly created Movies database
-- Note: you must submit this file even if you add nothing to it

-- The `dbpop()` function is provided for you in the dump file
-- This is provided in case you accidentally delete it

DROP TYPE IF EXISTS Population_Record CASCADE;
CREATE TYPE Population_Record AS (
	Tablename Text,
	Ntuples   Integer
);

CREATE OR REPLACE FUNCTION DBpop() RETURNS SETOF Population_Record
AS $$
DECLARE
    rec Record;
    qry Text;
    res Population_Record;
    num Integer;
BEGIN
    FOR rec IN SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename LOOP
        qry := 'SELECT count(*) FROM ' || quote_ident(rec.tablename);

        execute qry INTO num;

        res.tablename := rec.tablename;
        res.ntuples   := num;

        RETURN NEXT res;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--
-- Example Views/Functions
-- These Views/Functions may or may not be useful to you.
-- You may modify or delete them as you see fit.
--

-- `Move_Learning_Info`
-- The `Learnable_Moves` table is a relation between Pokemon, Moves, Games and Requirements.
-- As it just consists of foreign keys, it is not very easy to read.
-- This view makes it easier to read by displaying the names of the Pokemon, Moves and Games instead of their IDs.
CREATE OR REPLACE VIEW Move_Learning_Info(Pokemon, Move, Game, Requirement) AS
SELECT
    P.Name,
    M.Name,
    G.Name,
    R.Assertion
FROM
    Learnable_Moves AS L
    JOIN
    Pokemon         AS P ON Learnt_By   = P.ID
    JOIN
    Games           AS G ON Learnt_In   = G.ID
    JOIN
    Moves           AS M ON Learns      = M.ID
    JOIN
    Requirements    AS R ON Learnt_When = R.ID
;

-- `Super_Effective`
-- This function takes a type name and
-- returns a set of all types that it is super effective against (multiplier > 100)
-- eg Water is super effective against Fire, so `Super_Effective('Water')` will return `Fire` (amongst others)
CREATE OR REPLACE FUNCTION Super_Effective(_Type Text) RETURNS SETOF Text
AS $$
SELECT
    B.Name
FROM
    Types              AS A
    JOIN
    Type_Effectiveness AS E ON A.ID = E.Attacking
    JOIN
    Types              AS B ON B.ID = E.Defending
WHERE
    A.Name = _Type
    AND
    E.Multiplier > 100
$$ LANGUAGE SQL;

--
-- Your Views/Functions Below Here
-- Remember This file must load into a clean Pokemon database in one pass without any error
-- NOTICEs are fine, but ERRORs are not
-- Views/Functions must be defined in the correct order (dependencies first)
-- eg if my_supper_clever_function() depends on my_other_function() then my_other_function() must be defined first
-- Your Views/Functions Below Here
--
CREATE OR REPLACE VIEW Knowable_Abilities_By_Name(Known_By, Known_By_Name, Knows, Hidden) AS
SELECT a.Known_By, p.name, a.Knows, a.Hidden
FROM Knowable_Abilities a
INNER JOIN (
  SELECT name, id
  FROM Pokemon
) AS p ON p.id = a.Known_By;

CREATE OR REPLACE FUNCTION scaled_density(m Meters, k Kilograms, s Numeric) RETURNS Numeric
AS $$
DECLARE
    Volume Numeric;
BEGIN
    Volume := (4.0 / 3.0) * PI() * POWER(m / 2.0, 3.0);
    RETURN (k / Volume)*0.001*(s / 100.0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW sum_density_by_location(count_density, sum_Density, Location_ID) AS
SELECT count(scaled_density(p.average_height, p.average_weight, e.rarity)), 
        sum(scaled_density(p.average_height, p.average_weight, e.rarity)), e.occurs_at
FROM Pokemon AS p
INNER JOIN (
    SELECT *
    FROM Encounters
) AS e ON p.id = e.occurs_with
INNER JOIN (
    SELECT *
    FROM Locations
) AS l ON l.id = e.occurs_at
GROUP BY e.occurs_at;

-- create or replace view test(name, height, weight, rarity, d, e) as
-- SELECT p.name, p.average_height, p.average_weight, e.rarity, scaled_density(p.average_height, p.average_weight, e.rarity), e.occurs_at
-- FROM Pokemon AS p
-- INNER JOIN (
--     SELECT *
--     FROM pokedex
-- ) AS e ON p.id = e.national_id
-- INNER JOIN (
--     SELECT *
--     FROM Locations
-- ) AS l ON l.id = e.occurs_at;



CREATE OR REPLACE VIEW locations_in_region(name, id, region) AS
SELECT DISTINCT l.name, l.id, g.region
FROM Locations as l
INNER JOIN (
    SELECT id, name, region
    FROM Games
) AS g ON l.appears_in = g.id;

-- CREATE OR REPLACE VIEW sum_density_by_location(name, count_density, sum_density, region) AS
-- SELECT l.name, d.count_density, d.sum_density, l.region
-- FROM locations_in_region AS l
-- LEFT JOIN (
--   SELECT *
--   FROM sum_density_by_location
-- ) AS d ON d.location_id = l.id;

CREATE OR REPLACE FUNCTION pokemon_type_names(type_id Numeric) RETURNS Text
AS $$
DECLARE
  name Text;
BEGIN
  SELECT t.name FROM Types AS t WHERE t.id = type_id LIMIT 1 INTO name;
  RETURN Name;
END;
$$ LANGUAGE plpgsql
  
