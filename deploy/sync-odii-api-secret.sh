#!/usr/bin/env bash

set -Eeuo pipefail

: "${ODII_API_SERVICE_KEY:?Set production secret ODII_API_SERVICE_KEY}"

PRODUCTION_SECRET_NAME='ODII_API_SERVICE_KEY' \
PRODUCTION_SECRET_VALUE="${ODII_API_SERVICE_KEY}" \
  exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync-production-secret.sh"
