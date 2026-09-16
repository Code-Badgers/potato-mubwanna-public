#!/usr/bin/env bash

set -Eeuo pipefail

: "${TOUR_API_SERVICE_KEY:?Set production secret TOUR_API_SERVICE_KEY}"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PRODUCTION_SECRET_NAME='RELATED_TOURISM_API_SERVICE_KEY' \
PRODUCTION_SECRET_VALUE="${TOUR_API_SERVICE_KEY}" \
  bash "${script_directory}/sync-production-secret.sh"

# 전용 승인 키가 GitHub에 없으면 EC2에 이미 설정된 혼잡도 키를 덮어쓰지 않는다.
if [[ -n "${CONGESTION_API_SERVICE_KEY:-}" ]]; then
  PRODUCTION_SECRET_NAME='CONGESTION_API_SERVICE_KEY' \
  PRODUCTION_SECRET_VALUE="${CONGESTION_API_SERVICE_KEY}" \
    bash "${script_directory}/sync-production-secret.sh"
else
  echo 'CONGESTION_API_SERVICE_KEY secret not configured; preserving EC2 value.'
fi
