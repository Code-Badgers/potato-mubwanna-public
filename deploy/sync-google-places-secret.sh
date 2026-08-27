#!/usr/bin/env bash

set -Eeuo pipefail

: "${GOOGLE_PLACES_API_KEY:?Set production secret GOOGLE_PLACES_API_KEY}"

PRODUCTION_SECRET_NAME='GOOGLE_PLACES_API_KEY' \
PRODUCTION_SECRET_VALUE="${GOOGLE_PLACES_API_KEY}" \
  exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync-production-secret.sh"
