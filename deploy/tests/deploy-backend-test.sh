#!/usr/bin/env bash

set -euo pipefail

deploy_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "${test_root}"' EXIT

cp "${deploy_dir}/deploy-backend.sh" "${test_root}/deploy-backend.sh"
cp "${deploy_dir}/compose.prod.yml" "${test_root}/compose.prod.yml"
cp "${deploy_dir}/.env.example" "${test_root}/.env"
sed -i 's|^BACKEND_IMAGE=.*|BACKEND_IMAGE=registry.example/backend:previous|' "${test_root}/.env"
export TEST_DEPLOY_ENV_FILE="${test_root}/.env"

aws() {
  printf 'test-password\n'
}

docker() {
  if [[ "${1:-}" == "login" ]]; then
    cat > /dev/null
    return 0
  fi

  if [[ "${1:-}" == "compose" ]]; then
    if [[ " $* " == *" up -d --no-build "* ]] \
      && grep -q '^BACKEND_IMAGE=registry.example/backend:broken$' "${TEST_DEPLOY_ENV_FILE}"; then
      return 1
    fi
    return 0
  fi

  return 1
}

curl() {
  return 0
}

export -f aws docker curl

bash "${test_root}/deploy-backend.sh" \
  registry.example/backend:next ap-northeast-2 registry.example
grep -q '^BACKEND_IMAGE=registry.example/backend:next$' "${test_root}/.env"

sed -i 's|^BACKEND_IMAGE=.*|BACKEND_IMAGE=registry.example/backend:previous|' "${test_root}/.env"
if bash "${test_root}/deploy-backend.sh" \
  registry.example/backend:broken ap-northeast-2 registry.example; then
  echo "Expected the simulated deployment to fail." >&2
  exit 1
fi
grep -q '^BACKEND_IMAGE=registry.example/backend:previous$' "${test_root}/.env"

echo "Deployment script success and rollback scenarios passed."
