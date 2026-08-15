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

privacy_page="$(curl --fail --silent --show-error --retry 10 --retry-delay 1 \
  "http://127.0.0.1:${published_port}/privacy-policy")"

grep -q '<title>개인정보처리방침 | 감자무봤나</title>' <<< "${privacy_page}"
grep -q '시행일: 2026년 8월 15일' <<< "${privacy_page}"
grep -q 'privacy@example.com' <<< "${privacy_page}"
grep -q '010-0000-0000' <<< "${privacy_page}"
grep -q '만 14세 미만 아동의 개인정보와 개인위치정보를 수집하지 않습니다' <<< "${privacy_page}"

privacy_redirect_headers="$(curl --silent --output /dev/null --dump-header - \
  "http://127.0.0.1:${published_port}/privacy-policy/" | tr -d '\r')"
privacy_redirect_status="$(awk 'NR == 1 { print $2 }' <<< "${privacy_redirect_headers}")"
privacy_redirect_location="$(sed -n 's/^Location: //Ip' <<< "${privacy_redirect_headers}" | tail -n 1)"
test "${privacy_redirect_status}" = 308
test "${privacy_redirect_location}" = /privacy-policy

location_page="$(curl --fail --silent --show-error \
  "http://127.0.0.1:${published_port}/location-terms")"

grep -q '<title>위치기반서비스 이용약관 | 감자무봤나</title>' <<< "${location_page}"
grep -q '운영자 주소 입력' <<< "${location_page}"
grep -q '최소 6개월' <<< "${location_page}"
grep -q '원본 위도·경도' <<< "${location_page}"
grep -q 'privacy@example.com' <<< "${location_page}"
grep -q '010-0000-0000' <<< "${location_page}"
grep -q '제9조 이용 연령' <<< "${location_page}"
grep -q '만 14세 미만 아동의 개인위치정보를 수집하거나 이용하지 않습니다' <<< "${location_page}"

location_redirect_headers="$(curl --silent --output /dev/null --dump-header - \
  "http://127.0.0.1:${published_port}/location-terms/" | tr -d '\r')"
location_redirect_status="$(awk 'NR == 1 { print $2 }' <<< "${location_redirect_headers}")"
location_redirect_location="$(sed -n 's/^Location: //Ip' <<< "${location_redirect_headers}" | tail -n 1)"
test "${location_redirect_status}" = 308
test "${location_redirect_location}" = /location-terms

echo "Nginx legal pages and canonical redirects are valid."
