"""
This is a short-n-dirty script that calculates the
distances between two points using a local instance
the Vahalla routing server

There was a nice technique I picked up for splitting a list in batches
from SO:
    - https://stackoverflow.com/questions/1624883/alternative-way-to-split-a-list-into-groups-of-n
"""
import sys
from pprint import pprint
import json
from functools import wraps
from typing import List, Tuple
from collections import defaultdict
from itertools import zip_longest

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
                return_val = f(cursor, connection, *args, **kwargs)
            finally:
                # Close connection
                connection.commit()
                connection.close()
            
            return return_val
        return wrapper
    return wrap


def update_row_batch(cursor, rows: List[Tuple]):
    values_placeholder = ','.join(['(%s, %s, %s)'] * len(rows))
    flat_rows = [val for r in rows for val in r]
    sql = f"""
        UPDATE 
            sw_portland_buildings as s
        SET 
            nearest_super_auto_distance = c.distance,
            nearest_super_auto_duration = c.duration
        FROM
            (VALUES
                {values_placeholder}
            ) AS c(osm_id, duration, distance)
        WHERE
            s.osm_id = c.osm_id
    """
    cursor.execute(sql, flat_rows)


def get_poi_groups(cursor) -> defaultdict:
    poi_groups = defaultdict(list)

    for row in cursor.fetchall():
        osm_id, way_area, start_json, end_json = row
        start_json = json.loads(start_json)
        end_json = json.loads(end_json)
        poi_groups[(end_json['coordinates'][1], end_json['coordinates'][0])].append(
            (osm_id, way_area, start_json['coordinates'][1], start_json['coordinates'][0])
        )

    return poi_groups


def get_matrix_request(
        poi: Tuple[float, float],
        batch: List[Tuple[int, float, float, float]],
        costing: str = 'auto'
) -> dict:
    """
    This returns the JSON serializable object that we pass to the matrix API.

    Example:
    {"sources": [
        {"lat":40.744014,"lon":-73.990508},
        {"lat":40.739735,"lon":-73.979713},
        {"lat":40.752522,"lon":-73.985015},
        {"lat":40.750117,"lon":-73.983704},
        {"lat":40.750552,"lon":-73.993519}
    ],
    "targets": [
        {"lat":40.750552,"lon":-73.993519}
    ],
    "costing":"pedestrian"}
    """
    sources = [{'lat': x[2], 'lon': x[3]} for x in batch if x]
    targets = [{'lat': poi[0], 'lon': poi[1]}]
    return {
        'sources': sources,
        'targets': targets,
        'costing': costing
    }


def parse_batch_response(batch: List[Tuple], json_data: dict) -> List[Tuple]:
    """
    Parse the response from the matrix API and return in a format suitable
    to adding to our database.

    Example:
        [(1, 333, 0.47), ...]  # [(osm_id, time, distance), ...]
    """
    rows = []
    for bat, data in zip(batch, json_data['sources_to_targets']):
        if len(data) > 0:
            data = data[0]
            rows.append((bat[0], data['time'], data['distance']))

    return rows


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
        nearest_super_auto_duration IS NULL
"""

API_ENDPOINT = 'http://localhost:8002/route'
MATRIX_ENDPOINT = 'http://localhost:8002/sources_to_targets'


@psycopg2_cur(PSQL_CONN)
def main_batch(cursor, conn):
    """
    This is the function that processes the distances between points
    in batches. It runs faster but does not return the any information
    about the route except for distance and time.
    """
    cursor.execute(READ_SQL)
    poi_groups = get_poi_groups(cursor)
    batch_size = 50

    for poi, group in tqdm(poi_groups.items(), unit='batch'):
        batches = zip_longest(*(iter(group), ) * batch_size)

        for bat in batches:
            data = get_matrix_request(poi, bat, 'pedestrian')
            resp = requests.post(MATRIX_ENDPOINT, json=data)
            try:
                resp.raise_for_status()
            except requests.HTTPError as exc:
                sys.stderr.write(str(exc) + '\n')
                continue
            rows = parse_batch_response(bat, resp.json())
            update_row_batch(cursor, rows)
            conn.commit()


@psycopg2_cur(PSQL_CONN)
def main(cursor, connection):
    """
    This is a function that is used for retrieving individual routes.
    It takes longer to process but has the added benefit of returning
    a route along with the response.
    """
    cursor.execute(READ_SQL)

    for row in tqdm(cursor.fetchall(), unit='row'):
        osm_id, way_area, start_json, end_json = row
        start_json = json.loads(start_json)
        end_json = json.loads(end_json)
        json_data = {
            "locations": [
                {
                    "lat": start_json['coordinates'][1],
                    "lon": start_json['coordinates'][0]
                },
                {
                    "lat": end_json['coordinates'][1],
                    "lon": end_json['coordinates'][0]
                }
            ],
            "costing": "pedestrian",
            "directions_options": {
                "units": "kilometers"
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
                ''', (summary['length'], summary['time'], osm_id)
            )
        except (KeyError, IndexError):
            continue


if __name__ == '__main__':
    main_batch()
