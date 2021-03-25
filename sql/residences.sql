-- This file contains the various queries used to create list of residences
-- which will be used to create routes to supermarkets.

-- Kiel

-- Adds a new table called residences. These are alll the buildings which are in
-- `landuse = 'residential'` polygons.
WITH boundary AS (
  SELECT ST_Union(way) as way
  FROM planet_osm_polygon
  WHERE landuse = 'residential'
)

SELECT 
  planet_osm_polygon.*
INTO
  residences
FROM
  planet_osm_polygon, boundary
WHERE
  ST_Within(
    planet_osm_polygon.way,
    boundary.way
  )
AND
  building IS NOT NULL;

-- Add the
SELECT AddGeometryColumn('public', 'residences', 'geom_point', 3857, 'POINT', 2);

UPDATE residences SET geom_point = ST_Centroid(way);

-- Portland

SELECT 
    * 
INTO 
    residences 
FROM 
    planet_osm_polygon
WHERE
    "building" in ('apartments', 'detached', 'dormitory', 'residential', 'house');
