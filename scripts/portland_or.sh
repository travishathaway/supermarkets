#! /bin/bash
#
# Usage:
#   portland.sh <database> <port> <procs>
#
# Description:
#   This script downloads the planet OSM for Portland, OR
#
# Key terms:
#   bounding box is "minlon, minlat, maxlon, maxlat"

set -e

PBF_FILE='oregon-latest.osm.pbf'
URL="http://download.geofabrik.de/north-america/us/$PBF_FILE"
BOUNDING_BOX='-122.9088,45.4412,-122.3840,45.6451'

temp_dir=$(mktemp -d)

cd "$temp_dir" && curl "$URL" -O

osm2pgsql -a -d "$1" -P "$2" \
    --number-processes "$3" \
    --bbox "$BOUNDING_BOX" \
    $PBF_FILE
