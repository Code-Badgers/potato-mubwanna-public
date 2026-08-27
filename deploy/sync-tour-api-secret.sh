#!/usr/bin/env bash

set -Eeuo pipefail

: "${TOUR_API_SERVICE_KEY:?Set production secret TOUR_API_SERVICE_KEY}"

PRODUCTION_SECRET_NAME='TOUR_API_SERVICE_KEY' \
PRODUCTION_SECRET_VALUE="${TOUR_API_SERVICE_KEY}" \
  exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync-production-secret.sh"
