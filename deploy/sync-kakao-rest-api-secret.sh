#!/usr/bin/env bash

set -Eeuo pipefail

: "${KAKAO_REST_API_KEY:?Set production secret KAKAO_REST_API_KEY}"

PRODUCTION_SECRET_NAME='KAKAO_REST_API_KEY' \
PRODUCTION_SECRET_VALUE="${KAKAO_REST_API_KEY}" \
  exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync-production-secret.sh"
