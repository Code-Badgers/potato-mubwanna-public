#!/usr/bin/env bash

set -Eeuo pipefail

: "${FIREBASE_SERVICE_ACCOUNT_BASE64:?Set production secret FIREBASE_SERVICE_ACCOUNT_BASE64}"

PRODUCTION_SECRET_NAME='FIREBASE_SERVICE_ACCOUNT_BASE64' \
PRODUCTION_SECRET_VALUE="${FIREBASE_SERVICE_ACCOUNT_BASE64}" \
  exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync-production-secret.sh"
