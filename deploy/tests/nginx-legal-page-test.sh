#!/usr/bin/env bash

set -euo pipefail

deploy_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
container_name="potato-mubwanna-nginx-legal-${RANDOM}"

cleanup() {
  docker rm --force "${container_name}" > /dev/null 2>&1 || true
}
trap cleanup EXIT

MSYS_NO_PATHCONV=1 docker run --detach --rm \
  --name "${container_name}" \
  --add-host backend:127.0.0.1 \
  --publish 127.0.0.1::80 \
  --mount "type=bind,source=${deploy_dir}/nginx/default.conf,target=/etc/nginx/conf.d/default.conf,readonly" \
  --mount "type=bind,source=${deploy_dir}/legal,target=/usr/share/nginx/html/legal,readonly" \
  nginx:1.28-alpine > /dev/null

published_port="$(docker port "${container_name}" 80/tcp | sed -n 's/.*://p' | tail -n 1)"
test -n "${published_port}"

page="$(curl --fail --silent --show-error --retry 10 --retry-delay 1 \
  "http://127.0.0.1:${published_port}/privacy-policy")"

grep -q '<title>개인정보처리방침 | 감자무봤나</title>' <<< "${page}"
grep -q '시행일: 2026년 8월 15일' <<< "${page}"
grep -q 'privacy@example.com' <<< "${page}"
grep -q '010-0000-0000' <<< "${page}"

redirect_status="$(curl --silent --output /dev/null --write-out '%{http_code}' \
  "http://127.0.0.1:${published_port}/privacy-policy/")"
test "${redirect_status}" = 308

echo "Nginx privacy policy page and canonical redirect are valid."
