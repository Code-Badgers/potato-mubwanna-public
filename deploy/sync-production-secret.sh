#!/usr/bin/env bash

set -Eeuo pipefail

: "${AWS_REGION:?AWS_REGION is required}"
: "${EC2_INSTANCE_ID:?EC2_INSTANCE_ID is required}"
: "${PRODUCTION_SECRET_NAME:?PRODUCTION_SECRET_NAME is required}"
: "${PRODUCTION_SECRET_VALUE:?PRODUCTION_SECRET_VALUE is required}"

case "${PRODUCTION_SECRET_NAME}" in
  KAKAO_REST_API_KEY|TOUR_API_SERVICE_KEY|GOOGLE_PLACES_API_KEY|ODII_API_SERVICE_KEY|RELATED_TOURISM_API_SERVICE_KEY|CONGESTION_API_SERVICE_KEY|FIREBASE_SERVICE_ACCOUNT_BASE64) ;;
  *)
    echo "Unsupported production secret name: ${PRODUCTION_SECRET_NAME}" >&2
    exit 1
    ;;
esac

case "${PRODUCTION_SECRET_VALUE}" in
  *$'\r'*|*$'\n'*)
    echo "${PRODUCTION_SECRET_NAME} must be a single line." >&2
    exit 1
    ;;
esac

for command_name in aws jq openssl; do
  command -v "${command_name}" > /dev/null || {
    echo "Required command is missing: ${command_name}" >&2
    exit 1
  }
done

runner_directory="$(mktemp -d)"
exchange_id="$(openssl rand -hex 16)"
production_repository_directory="${PRODUCTION_REPOSITORY_DIRECTORY:-/opt/potato-mubwanna}"
remote_private_key="/tmp/potato-production-secret-${exchange_id}.pem"
remote_public_key="/tmp/potato-production-secret-${exchange_id}.pub"
remote_ciphertext="/tmp/potato-production-secret-${exchange_id}.bin"
remote_secret="/tmp/potato-production-secret-${exchange_id}.secret"
remote_env_file="${production_repository_directory}/deploy/.env"
remote_next_env="${remote_env_file}.next-${exchange_id}"

cleanup_runner() {
  rm -rf "${runner_directory}"
}
trap cleanup_runner EXIT

send_command() {
  local comment="$1"
  local parameters_path="$2"

  aws ssm send-command \
    --region "${AWS_REGION}" \
    --instance-ids "${EC2_INSTANCE_ID}" \
    --document-name AWS-RunShellScript \
    --comment "${comment}" \
    --parameters "file://${parameters_path}" \
    --query 'Command.CommandId' \
    --output text
}

wait_for_command() {
  local command_id="$1"
  local result_path="$2"
  local deadline=$((SECONDS + 180))
  local status="Pending"

  while (( SECONDS < deadline )); do
    status="$(aws ssm get-command-invocation \
      --region "${AWS_REGION}" \
      --command-id "${command_id}" \
      --instance-id "${EC2_INSTANCE_ID}" \
      --query 'Status' \
      --output text 2>/dev/null || true)"
    case "${status}" in
      Success|Cancelled|Failed|TimedOut)
        break
        ;;
    esac
    sleep 3
  done

  aws ssm get-command-invocation \
    --region "${AWS_REGION}" \
    --command-id "${command_id}" \
    --instance-id "${EC2_INSTANCE_ID}" \
    --no-cli-pager \
    --output json > "${result_path}"

  if [[ "$(jq -r '.Status' "${result_path}")" != "Success" ]]; then
    jq -r '.StandardErrorContent' "${result_path}" >&2
    return 1
  fi
}

public_key_parameters="${runner_directory}/public-key-parameters.json"
public_key_result="${runner_directory}/public-key-result.json"
public_key_path="${runner_directory}/public-key.pem"

jq -n \
  --arg private_key "${remote_private_key}" \
  --arg public_key "${remote_public_key}" \
  '{commands: [
    "set -eu",
    "umask 077",
    ("openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out " + ($private_key | @sh) + " 2>/dev/null"),
    ("openssl pkey -in " + ($private_key | @sh) + " -pubout -out " + ($public_key | @sh)),
    ("cat " + ($public_key | @sh))
  ]}' > "${public_key_parameters}"

public_key_command_id="$(send_command "Prepare encrypted production secret exchange" "${public_key_parameters}")"
wait_for_command "${public_key_command_id}" "${public_key_result}"
jq -r '.StandardOutputContent' "${public_key_result}" > "${public_key_path}"
grep -q -- '-----BEGIN PUBLIC KEY-----' "${public_key_path}"

ciphertext_path="${runner_directory}/ciphertext.bin"
printf '%s' "${PRODUCTION_SECRET_VALUE}" | openssl pkeyutl \
  -encrypt \
  -pubin \
  -inkey "${public_key_path}" \
  -pkeyopt rsa_padding_mode:oaep \
  -out "${ciphertext_path}"
ciphertext_base64="$(openssl base64 -A -in "${ciphertext_path}")"

secret_parameters="${runner_directory}/secret-parameters.json"
secret_result="${runner_directory}/secret-result.json"

jq -n \
  --arg private_key "${remote_private_key}" \
  --arg public_key "${remote_public_key}" \
  --arg ciphertext_path "${remote_ciphertext}" \
  --arg secret_path "${remote_secret}" \
  --arg env_file "${remote_env_file}" \
  --arg next_env "${remote_next_env}" \
  --arg secret_name "${PRODUCTION_SECRET_NAME}" \
  --arg ciphertext "${ciphertext_base64}" \
  '{commands: [
    "set -eu",
    "umask 077",
    ("private_key=" + ($private_key | @sh)),
    ("public_key=" + ($public_key | @sh)),
    ("ciphertext_path=" + ($ciphertext_path | @sh)),
    ("secret_path=" + ($secret_path | @sh)),
    ("env_file=" + ($env_file | @sh)),
    ("next_env=" + ($next_env | @sh)),
    ("secret_name=" + ($secret_name | @sh)),
    "cleanup() { rm -f \"${private_key}\" \"${public_key}\" \"${ciphertext_path}\" \"${secret_path}\" \"${next_env}\"; }",
    "trap cleanup EXIT",
    ("printf %s " + ($ciphertext | @sh) + " | openssl base64 -d -A -out \"${ciphertext_path}\""),
    "openssl pkeyutl -decrypt -inkey \"${private_key}\" -pkeyopt rsa_padding_mode:oaep -in \"${ciphertext_path}\" -out \"${secret_path}\"",
    "test -s \"${secret_path}\"",
    "test -f \"${env_file}\"",
    "secret_value=\"$(cat \"${secret_path}\")\"",
    "grep -v \"^${secret_name}=\" \"${env_file}\" > \"${next_env}\" || true",
    "printf \"%s=%s\\n\" \"${secret_name}\" \"${secret_value}\" >> \"${next_env}\"",
    "env_owner=\"$(stat -c %u:%g \"${env_file}\" 2>/dev/null || stat -f %u:%g \"${env_file}\")\"",
    "env_mode=\"$(stat -c %a \"${env_file}\" 2>/dev/null || stat -f %Lp \"${env_file}\")\"",
    "chown \"${env_owner}\" \"${next_env}\"",
    "chmod \"${env_mode}\" \"${next_env}\"",
    "mv \"${next_env}\" \"${env_file}\"",
    "unset secret_value",
    "echo \"${secret_name}_SYNCED\""
  ]}' > "${secret_parameters}"

secret_command_id="$(send_command "Sync encrypted ${PRODUCTION_SECRET_NAME}" "${secret_parameters}")"
wait_for_command "${secret_command_id}" "${secret_result}"
jq -r '.StandardOutputContent' "${secret_result}"
