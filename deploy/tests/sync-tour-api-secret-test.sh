#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
deploy_dir="$(cd "${script_dir}/.." && pwd)"
test_directory="$(mktemp -d)"
mock_bin="${test_directory}/bin"
mock_state="${test_directory}/aws-state"
production_directory="${test_directory}/production"
service_key='dummy%2Fencoded%2Bkey%3D'
congestion_service_key='dummy-dedicated-congestion-key'
google_places_key='dummy-google-places-key'
kakao_rest_key='dummy-kakao-rest-key'
odii_service_key='dummy-odii-service-key'
firebase_service_account_base64="$(printf '%4096s' '' | tr ' ' A)"

cleanup() {
  rm -rf "${test_directory}"
}
trap cleanup EXIT

mkdir -p "${mock_bin}" "${mock_state}" "${production_directory}/deploy"
cat > "${production_directory}/deploy/.env" <<'EOF'
PUBLIC_DOMAIN=example.test
UNCHANGED_VALUE=keep-me
TOUR_API_SERVICE_KEY=old-value
CONGESTION_API_SERVICE_KEY=existing-congestion-key
GOOGLE_PLACES_API_KEY=old-google-value
KAKAO_REST_API_KEY=old-kakao-value
ODII_API_SERVICE_KEY=old-odii-value
FIREBASE_ADMIN_ENABLED=false
FIREBASE_PROJECT_ID=
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
KAKAO_REST_API_KEY="${kakao_rest_key}" \
bash "${deploy_dir}/sync-kakao-rest-api-secret.sh"

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
TOUR_API_SERVICE_KEY="${service_key}" \
CONGESTION_API_SERVICE_KEY='' \
bash "${deploy_dir}/sync-tour-derived-api-secrets.sh"

grep -q '^CONGESTION_API_SERVICE_KEY=existing-congestion-key$' "${production_directory}/deploy/.env"

PATH="${mock_bin}:${PATH}" \
MOCK_AWS_STATE_DIRECTORY="${mock_state}" \
PRODUCTION_REPOSITORY_DIRECTORY="${production_directory}" \
AWS_REGION='ap-northeast-2' \
EC2_INSTANCE_ID='i-test' \
TOUR_API_SERVICE_KEY="${service_key}" \
CONGESTION_API_SERVICE_KEY="${congestion_service_key}" \
bash "${deploy_dir}/sync-tour-derived-api-secrets.sh"

PATH="${mock_bin}:${PATH}" \
MOCK_AWS_STATE_DIRECTORY="${mock_state}" \
PRODUCTION_REPOSITORY_DIRECTORY="${production_directory}" \
AWS_REGION='ap-northeast-2' \
EC2_INSTANCE_ID='i-test' \
GOOGLE_PLACES_API_KEY="${google_places_key}" \
bash "${deploy_dir}/sync-google-places-secret.sh"

PATH="${mock_bin}:${PATH}" \
MOCK_AWS_STATE_DIRECTORY="${mock_state}" \
PRODUCTION_REPOSITORY_DIRECTORY="${production_directory}" \
AWS_REGION='ap-northeast-2' \
EC2_INSTANCE_ID='i-test' \
ODII_API_SERVICE_KEY="${odii_service_key}" \
bash "${deploy_dir}/sync-odii-api-secret.sh"

PATH="${mock_bin}:${PATH}" \
MOCK_AWS_STATE_DIRECTORY="${mock_state}" \
PRODUCTION_REPOSITORY_DIRECTORY="${production_directory}" \
AWS_REGION='ap-northeast-2' \
EC2_INSTANCE_ID='i-test' \
FIREBASE_ADMIN_ENABLED='true' \
FIREBASE_PROJECT_ID='potato-mubwanna-prod' \
bash "${deploy_dir}/sync-firebase-production-config.sh"

PATH="${mock_bin}:${PATH}" \
MOCK_AWS_STATE_DIRECTORY="${mock_state}" \
PRODUCTION_REPOSITORY_DIRECTORY="${production_directory}" \
AWS_REGION='ap-northeast-2' \
EC2_INSTANCE_ID='i-test' \
FIREBASE_SERVICE_ACCOUNT_BASE64="${firebase_service_account_base64}" \
bash "${deploy_dir}/sync-firebase-service-account-secret.sh"

grep -q '^PUBLIC_DOMAIN=example.test$' "${production_directory}/deploy/.env"
grep -q '^UNCHANGED_VALUE=keep-me$' "${production_directory}/deploy/.env"
grep -q "^KAKAO_REST_API_KEY=${kakao_rest_key}$" "${production_directory}/deploy/.env"
test "$(grep -c '^KAKAO_REST_API_KEY=' "${production_directory}/deploy/.env")" -eq 1
grep -q "^TOUR_API_SERVICE_KEY=${service_key}$" "${production_directory}/deploy/.env"
test "$(grep -c '^TOUR_API_SERVICE_KEY=' "${production_directory}/deploy/.env")" -eq 1
grep -q "^RELATED_TOURISM_API_SERVICE_KEY=${service_key}$" "${production_directory}/deploy/.env"
test "$(grep -c '^RELATED_TOURISM_API_SERVICE_KEY=' "${production_directory}/deploy/.env")" -eq 1
grep -q "^CONGESTION_API_SERVICE_KEY=${congestion_service_key}$" "${production_directory}/deploy/.env"
test "$(grep -c '^CONGESTION_API_SERVICE_KEY=' "${production_directory}/deploy/.env")" -eq 1
grep -q "^GOOGLE_PLACES_API_KEY=${google_places_key}$" "${production_directory}/deploy/.env"
test "$(grep -c '^GOOGLE_PLACES_API_KEY=' "${production_directory}/deploy/.env")" -eq 1
grep -q "^ODII_API_SERVICE_KEY=${odii_service_key}$" "${production_directory}/deploy/.env"
test "$(grep -c '^ODII_API_SERVICE_KEY=' "${production_directory}/deploy/.env")" -eq 1
grep -q "^FIREBASE_SERVICE_ACCOUNT_BASE64=${firebase_service_account_base64}$" "${production_directory}/deploy/.env"
test "$(grep -c '^FIREBASE_SERVICE_ACCOUNT_BASE64=' "${production_directory}/deploy/.env")" -eq 1
grep -q '^FIREBASE_ADMIN_ENABLED=true$' "${production_directory}/deploy/.env"
grep -q '^FIREBASE_PROJECT_ID=potato-mubwanna-prod$' "${production_directory}/deploy/.env"
if [[ "$(uname -s)" == "Linux" ]]; then
  test "$(stat -c '%a' "${production_directory}/deploy/.env")" = '600'
fi

if grep -R -F "${service_key}" "${mock_state}" > /dev/null; then
  echo 'Plaintext TourAPI key leaked into SSM command records.' >&2
  exit 1
fi

if grep -R -F "${congestion_service_key}" "${mock_state}" > /dev/null; then
  echo 'Plaintext congestion API key leaked into SSM command records.' >&2
  exit 1
fi

if grep -R -F "${google_places_key}" "${mock_state}" > /dev/null; then
  echo 'Plaintext Google Places key leaked into SSM command records.' >&2
  exit 1
fi

if grep -R -F "${kakao_rest_key}" "${mock_state}" > /dev/null; then
  echo 'Plaintext Kakao REST API key leaked into SSM command records.' >&2
  exit 1
fi

if grep -R -F "${odii_service_key}" "${mock_state}" > /dev/null; then
  echo 'Plaintext ODII API key leaked into SSM command records.' >&2
  exit 1
fi

if grep -R -F "${firebase_service_account_base64}" "${mock_state}" > /dev/null; then
  echo 'Plaintext Firebase service account leaked into SSM command records.' >&2
  exit 1
fi

echo 'Kakao REST, TourAPI-related services, dedicated congestion key, Google Places, ODII, Firebase secret, and Firebase config sync scenarios passed.'
