#!/usr/bin/env bash

set -Eeuo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <image-uri> <aws-region> <ecr-registry>" >&2
  exit 2
fi

image_uri="$1"
aws_region="$2"
ecr_registry="$3"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
env_file="${script_dir}/.env"
compose_file="${script_dir}/compose.prod.yml"
health_url="http://127.0.0.1/health"
compose=(docker compose --env-file "${env_file}" -f "${compose_file}")

if [[ ! -f "${env_file}" ]]; then
  echo "Missing production environment file: ${env_file}" >&2
  exit 1
fi

if [[ "${image_uri}" == *$'\n'* || "${image_uri}" == *$'\r'* ]]; then
  echo "Image URI must be a single line." >&2
  exit 2
fi

previous_image="$(sed -n 's/^BACKEND_IMAGE=//p' "${env_file}" | tail -n 1)"
deployment_started=false

set_backend_image() {
  local next_image="$1"
  sed -i '/^BACKEND_IMAGE=/d' "${env_file}"
  printf 'BACKEND_IMAGE=%s\n' "${next_image}" >> "${env_file}"
  chmod 600 "${env_file}"
}

rollback_on_error() {
  local deploy_status=$?
  trap - ERR

  if [[ "${deployment_started}" == true && -n "${previous_image}" && "${previous_image}" != "${image_uri}" ]]; then
    echo "Deployment failed; restoring the previous backend image."
    set +e
    set_backend_image "${previous_image}"
    "${compose[@]}" pull backend \
      && "${compose[@]}" up -d --no-build \
      && curl --fail --silent --show-error --retry 18 --retry-delay 5 --retry-all-errors "${health_url}"
    local rollback_status=$?
    set -e

    if [[ ${rollback_status} -ne 0 ]]; then
      echo "Automatic rollback also failed; inspect the Compose services immediately." >&2
    fi
  fi

  exit "${deploy_status}"
}

trap rollback_on_error ERR

aws ecr get-login-password --region "${aws_region}" \
  | docker login --username AWS --password-stdin "${ecr_registry}"

deployment_started=true
set_backend_image "${image_uri}"
"${compose[@]}" pull backend
"${compose[@]}" up -d --no-build
curl --fail --silent --show-error --retry 18 --retry-delay 5 --retry-all-errors "${health_url}"
"${compose[@]}" ps

trap - ERR
echo "Backend deployment completed successfully."
