#!/usr/bin/env bash

set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <local-image> <build-image:true|false>" >&2
  exit 2
fi

image_uri="$1"
build_image="$2"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_dir="$(cd "${script_dir}/.." && pwd)"
env_file="${script_dir}/.env"
compose_file="${script_dir}/compose.prod.yml"
compose=(docker compose --env-file "${env_file}" -f "${compose_file}")

if [[ ! -f "${env_file}" ]]; then
  echo "Missing production environment file: ${env_file}" >&2
  exit 1
fi

public_domain="$(sed -n 's/^PUBLIC_DOMAIN=//p' "${env_file}" | tail -n 1)"
if [[ ! "${public_domain}" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$ || "${public_domain}" != *.* ]]; then
  echo "Invalid or missing PUBLIC_DOMAIN in ${env_file}." >&2
  exit 1
fi
health_url="https://${public_domain}/health"

if [[ ! "${image_uri}" =~ ^potato-mubwanna-backend:[A-Za-z0-9_][A-Za-z0-9._-]{0,127}$ ]]; then
  echo "Invalid local backend image: ${image_uri}" >&2
  exit 2
fi

if [[ "${build_image}" != true && "${build_image}" != false ]]; then
  echo "build-image must be true or false." >&2
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
    docker image inspect "${previous_image}" > /dev/null 2>&1 \
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

if [[ "${build_image}" == true ]]; then
  docker build \
    --file "${repository_dir}/backend/Dockerfile" \
    --tag "${image_uri}" \
    "${repository_dir}/backend"
else
  docker image inspect "${image_uri}" > /dev/null
fi

deployment_started=true
set_backend_image "${image_uri}"
"${compose[@]}" up -d --no-build
curl --fail --silent --show-error --retry 18 --retry-delay 5 --retry-all-errors "${health_url}"
"${compose[@]}" ps

while IFS= read -r candidate_image; do
  if [[ -n "${candidate_image}" && "${candidate_image}" != "${image_uri}" && "${candidate_image}" != "${previous_image}" ]]; then
    docker image rm "${candidate_image}" > /dev/null 2>&1 || true
  fi
done < <(docker image ls potato-mubwanna-backend --format '{{.Repository}}:{{.Tag}}')
docker image prune --force > /dev/null || true

trap - ERR
echo "Backend deployment completed successfully."
