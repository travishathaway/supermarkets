-- Create a new table called "sw_portland_buildings" from the
-- planet_osm_polygon table and the polygon you drew with QGIS
SELECT
	*
INTO 
	sw_portland_buildings
FROM 
	planet_osm_polygon
WHERE
	ST_Contains(
		(SELECT wkb_geometry FROM sw_portland LIMIT 1),
		way
	) 
AND
	building IS NOT NULL;

-- Add some additional columns to the freshly created table
SELECT AddGeometryColumn('public', 'sw_portland_buildings', 'nearest_super_geom', 3857, 'POINT', 2);
SELECT AddGeometryColumn('public', 'sw_portland_buildings', 'way_point', 3857, 'POINT', 2);
ALTER TABLE sw_portland_buildings ADD COLUMN nearest_super_walk_duration FLOAT;
ALTER TABLE sw_portland_buildings ADD COLUMN nearest_super_walk_distance FLOAT;
ALTER TABLE sw_portland_buildings ADD COLUMN nearest_super_auto_duration FLOAT;
ALTER TABLE sw_portland_buildings ADD COLUMN nearest_super_auto_distance FLOAT;

-- Get the nearest (as the crow flies) supermarket point, and add it to
-- the table.
UPDATE
	sw_portland_buildings
SET
	nearest_super_geom = (
		select s.geom from supermarkets s
		order by ST_Distance(s.geom, way)
		limit 1
	)
WHERE
	"building" is null or "building" in (
		'detached', 'apartments', 'bungalow',
		'house', 'residential', 'yes'
	)
	AND "way_area" < 500;

-- Add centroid point on the table for heat map generation
UPDATE sw_portland_buildings SET way_point = ST_Centroid(way);


