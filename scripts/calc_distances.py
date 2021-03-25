"""
This is a short-n-dirty script that calculates the
distances between two points using a local instance
the Vahalla routing server
"""
from pprint import pprint
import json
from functools import wraps

import requests
import psycopg2
from tqdm import tqdm

PSQL_CONN = {
    'host': '127.0.0.1',
    'port': '5432',
    'user': 'thath',
    'password': 'thath',
    'dbname': 'portland_osm_2021_01_22'
}


def psycopg2_cur(conn_info):
    """Wrap function to setup and tear down a Postgres connection while 
    providing a cursor object to make queries with.
    """
    def wrap(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            try:
                # Setup postgres connection
                connection = psycopg2.connect(**conn_info)
                cursor = connection.cursor()
                # Call function passing in cursor
                return_val = f(cursor, *args, **kwargs)
            finally:
                # Close connection
                connection.commit()
                connection.close()
            
            return return_val
        return wrapper
    return wrap


READ_SQL = """
    SELECT 
        osm_id, way_area, 
        ST_AsGeoJson(ST_Transform(ST_Centroid(way), 4326)) as start,
        ST_AsGeoJson(ST_Transform(nearest_super_geom, 4326)) as end
    FROM
        sw_portland_buildings
    WHERE
        nearest_super_geom IS NOT NULL
    AND
        nearest_super_walk_duration IS NULL
"""

API_ENDPOINT = 'http://localhost:8002/route'


@psycopg2_cur(PSQL_CONN)
def main(cursor):
    cursor.execute(READ_SQL)

    for row in tqdm(cursor.fetchall(), unit='row'):
        osm_id, way_area, start_json, end_json = row
        start_json = json.loads(start_json)
        end_json = json.loads(end_json)
        json_data = {
            "locations":[
                {
                    "lat":start_json['coordinates'][1],
                    "lon":start_json['coordinates'][0]
                },
                {
                    "lat":end_json['coordinates'][1],
                    "lon":end_json['coordinates'][0]
                }
            ],
            "costing":"pedestrian",
            "directions_options": {
                "units":"kilometers"
            }
        }
        resp = requests.post(API_ENDPOINT, json=json_data)

        try:
            resp.raise_for_status()
        except requests.HTTPError:
            continue

        try:
            summary = resp.json()['trip']['legs'][0]['summary']
            cursor.execute('''
                UPDATE 
                    sw_portland_buildings 
                SET 
                    nearest_super_walk_distance = %s,
                    nearest_super_walk_duration = %s
                WHERE
                    osm_id = %s
                ''', 
                (summary['length'], summary['time'], osm_id)
            )
        except (KeyError, IndexError):
            continue


if __name__ == '__main__':
    main()