-- These are the queries that I have run on a fresh OSM import to
-- Generate a list of all supermarkets in an area.

-- This is the initial query that creates the table that holds the supermarkets
SELECT
  osm_id,"addr:housename","addr:housenumber", brand, name, operator, ref, way as geom
INTO 
  supermarkets
FROM 
  planet_osm_point 
WHERE 
  shop = 'supermarket';

-- This is an additional query that I used to convert  the building polygons
-- to point geometries. It then adds the rest of the supermarkets to the table.
INSERT INTO
  supermarkets
SELECT
  osm_id,"addr:housename","addr:housenumber", brand, name, operator, ref,
  ST_Centroid(way) as geom
FROM
  planet_osm_polygon
WHERE
  shop = 'supermarket';

-- This is a query that uses the boundary for Portland in the planet_osm_polygon table 
-- to determine how many supermarkets are in Portland.
WITH boundary AS (
  SELECT ST_Union(way) as geom
  FROM planet_osm_polygon
  WHERE name = 'Portland'
  AND boundary IS NOT NULL
)

SELECT name, count(*) FROM supermarkets, boundary WHERE ST_Within(
  supermarkets.geom,
  boundary.geom
)
GROUP BY supermarkets.name
ORDER BY count(*) DESC
