#!/usr/bin/env bash

set -Eeuo pipefail

: "${TOUR_API_SERVICE_KEY:?Set production secret TOUR_API_SERVICE_KEY}"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for secret_name in RELATED_TOURISM_API_SERVICE_KEY CONGESTION_API_SERVICE_KEY; do
  PRODUCTION_SECRET_NAME="${secret_name}" \
  PRODUCTION_SECRET_VALUE="${TOUR_API_SERVICE_KEY}" \
    bash "${script_directory}/sync-production-secret.sh"
done
