#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
deploy_dir="$(cd "${script_dir}/.." && pwd)"
test_directory="$(mktemp -d)"
mock_bin="${test_directory}/bin"
mock_state="${test_directory}/aws-state"
production_directory="${test_directory}/production"
service_key='dummy%2Fencoded%2Bkey%3D'
google_places_key='dummy-google-places-key'

cleanup() {
  rm -rf "${test_directory}"
}
trap cleanup EXIT

mkdir -p "${mock_bin}" "${mock_state}" "${production_directory}/deploy"
cat > "${production_directory}/deploy/.env" <<'EOF'
PUBLIC_DOMAIN=example.test
UNCHANGED_VALUE=keep-me
TOUR_API_SERVICE_KEY=old-value
GOOGLE_PLACES_API_KEY=old-google-value
EOF
chmod 600 "${production_directory}/deploy/.env"

cat > "${mock_bin}/aws" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

state_directory="${MOCK_AWS_STATE_DIRECTORY:?}"
service="${1:-}"
operation="${2:-}"
shift 2

if [[ "${service}/${operation}" == "ssm/send-command" ]]; then
  parameters=""
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--parameters" ]]; then
      parameters="$2"
      shift 2
      continue
    fi
    shift
  done

  counter_path="${state_directory}/counter"
  counter=0
  if [[ -f "${counter_path}" ]]; then
    counter="$(cat "${counter_path}")"
  fi
  counter=$((counter + 1))
  printf '%s' "${counter}" > "${counter_path}"
  command_id="mock-${counter}"
  command_path="${state_directory}/${command_id}.sh"
  stdout_path="${state_directory}/${command_id}.stdout"
  stderr_path="${state_directory}/${command_id}.stderr"
  result_path="${state_directory}/${command_id}.json"

  jq -r '.commands[]' "${parameters#file://}" > "${command_path}"
  if bash "${command_path}" > "${stdout_path}" 2> "${stderr_path}"; then
    status="Success"
  else
    status="Failed"
  fi
  jq -n \
    --arg status "${status}" \
    --rawfile stdout "${stdout_path}" \
    --rawfile stderr "${stderr_path}" \
    '{Status: $status, StandardOutputContent: $stdout, StandardErrorContent: $stderr}' \
    > "${result_path}"
  printf '%s\n' "${command_id}"
  exit 0
fi

if [[ "${service}/${operation}" == "ssm/get-command-invocation" ]]; then
  command_id=""
  query=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --command-id)
        command_id="$2"
        shift 2
        ;;
      --query)
        query="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  result_path="${state_directory}/${command_id}.json"
  if [[ "${query}" == "Status" ]]; then
    jq -r '.Status' "${result_path}"
  else
    cat "${result_path}"
  fi
  exit 0
fi

echo "Unexpected mock AWS command: ${service}/${operation}" >&2
exit 2
EOF
chmod +x "${mock_bin}/aws"

PATH="${mock_bin}:${PATH}" \
MOCK_AWS_STATE_DIRECTORY="${mock_state}" \
PRODUCTION_REPOSITORY_DIRECTORY="${production_directory}" \
AWS_REGION='ap-northeast-2' \
EC2_INSTANCE_ID='i-test' \
TOUR_API_SERVICE_KEY="${service_key}" \
bash "${deploy_dir}/sync-tour-api-secret.sh"

PATH="${mock_bin}:${PATH}" \
MOCK_AWS_STATE_DIRECTORY="${mock_state}" \
PRODUCTION_REPOSITORY_DIRECTORY="${production_directory}" \
AWS_REGION='ap-northeast-2' \
EC2_INSTANCE_ID='i-test' \
GOOGLE_PLACES_API_KEY="${google_places_key}" \
bash "${deploy_dir}/sync-google-places-secret.sh"

grep -q '^PUBLIC_DOMAIN=example.test$' "${production_directory}/deploy/.env"
grep -q '^UNCHANGED_VALUE=keep-me$' "${production_directory}/deploy/.env"
grep -q "^TOUR_API_SERVICE_KEY=${service_key}$" "${production_directory}/deploy/.env"
test "$(grep -c '^TOUR_API_SERVICE_KEY=' "${production_directory}/deploy/.env")" -eq 1
grep -q "^GOOGLE_PLACES_API_KEY=${google_places_key}$" "${production_directory}/deploy/.env"
test "$(grep -c '^GOOGLE_PLACES_API_KEY=' "${production_directory}/deploy/.env")" -eq 1
if [[ "$(uname -s)" == "Linux" ]]; then
  test "$(stat -c '%a' "${production_directory}/deploy/.env")" = '600'
fi

if grep -R -F "${service_key}" "${mock_state}" > /dev/null; then
  echo 'Plaintext TourAPI key leaked into SSM command records.' >&2
  exit 1
fi

if grep -R -F "${google_places_key}" "${mock_state}" > /dev/null; then
  echo 'Plaintext Google Places key leaked into SSM command records.' >&2
  exit 1
fi

echo 'TourAPI and Google Places encrypted SSM secret sync scenarios passed.'
