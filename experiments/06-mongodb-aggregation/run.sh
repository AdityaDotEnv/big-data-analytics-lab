#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../scripts/common.sh"
mongo_env
export LAB_DB_NAME="${LAB_DB_PREFIX}_aggregation"
mongosh "$MONGODB_URI" --quiet --file "$HERE/scripts/aggregation.mongodb.js"
