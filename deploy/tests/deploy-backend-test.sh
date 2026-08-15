#!/usr/bin/env bash

set -euo pipefail

deploy_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "${test_root}"' EXIT

cp "${deploy_dir}/deploy-backend.sh" "${test_root}/deploy-backend.sh"
cp "${deploy_dir}/compose.prod.yml" "${test_root}/compose.prod.yml"
cp "${deploy_dir}/.env.example" "${test_root}/.env"
sed -i 's|^BACKEND_IMAGE=.*|BACKEND_IMAGE=potato-mubwanna-backend:previous|' "${test_root}/.env"
export TEST_DEPLOY_ENV_FILE="${test_root}/.env"
export TEST_DOCKER_LOG="${test_root}/docker.log"

docker() {
  printf '%s\n' "$*" >> "${TEST_DOCKER_LOG}"

  if [[ "${1:-}" == "compose" ]]; then
    if [[ " $* " == *" up -d --no-build "* ]] \
      && grep -q '^BACKEND_IMAGE=potato-mubwanna-backend:broken$' "${TEST_DEPLOY_ENV_FILE}"; then
      return 1
    fi
    return 0
  fi

  if [[ "${1:-}" == "image" && "${2:-}" == "ls" ]]; then
    return 0
  fi

  return 0
}

curl() {
  printf 'curl %s\n' "$*" >> "${TEST_DOCKER_LOG}"
  return 0
}

export -f docker curl

bash "${test_root}/deploy-backend.sh" \
  potato-mubwanna-backend:next true
grep -q '^BACKEND_IMAGE=potato-mubwanna-backend:next$' "${test_root}/.env"
grep -q '^build .*--tag potato-mubwanna-backend:next ' "${TEST_DOCKER_LOG}"
grep -q 'restart nginx gateway' "${TEST_DOCKER_LOG}"
grep -q 'https://potato-mubwanna.duckdns.org/health' "${TEST_DOCKER_LOG}"

sed -i 's|^BACKEND_IMAGE=.*|BACKEND_IMAGE=potato-mubwanna-backend:previous|' "${test_root}/.env"
if bash "${test_root}/deploy-backend.sh" \
  potato-mubwanna-backend:broken true; then
  echo "Expected the simulated deployment to fail." >&2
  exit 1
fi
grep -q '^BACKEND_IMAGE=potato-mubwanna-backend:previous$' "${test_root}/.env"

: > "${TEST_DOCKER_LOG}"
bash "${test_root}/deploy-backend.sh" \
  potato-mubwanna-backend:previous false
if grep -q '^build ' "${TEST_DOCKER_LOG}"; then
  echo "Existing-image rollback must not rebuild the backend image." >&2
  exit 1
fi
grep -q '^image inspect potato-mubwanna-backend:previous$' "${TEST_DOCKER_LOG}"
grep -q 'restart nginx gateway' "${TEST_DOCKER_LOG}"

echo "Deployment script build, automatic rollback, and existing-image scenarios passed."
