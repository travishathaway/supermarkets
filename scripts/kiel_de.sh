#! /bin/bash
#
# Usage:
#   kiel_de.sh <database> <port> <procs>
#
# Description:
#   This script downloads the planet OSM for Kiel, DE
#
# Key terms:
#   bounding box is "minlon, minlat, maxlon, maxlat"

set -e

PBF_FILE='schleswig-holstein-latest.osm.pbf'
URL="http://download.geofabrik.de/europe/germany/$PBF_FILE"
BOUNDING_BOX='10.0252,54.2468,10.2678,54.4511'

temp_dir=$(mktemp -d)

cd "$temp_dir" && curl "$URL" -O

osm2pgsql -c -d "$1" -P "$2" \
    --number-processes "$3" \
    --bbox "$BOUNDING_BOX" \
    $PBF_FILE
