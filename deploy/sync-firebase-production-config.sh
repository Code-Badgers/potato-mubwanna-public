#!/usr/bin/env bash

set -Eeuo pipefail

: "${AWS_REGION:?AWS_REGION is required}"
: "${EC2_INSTANCE_ID:?EC2_INSTANCE_ID is required}"
: "${FIREBASE_ADMIN_ENABLED:?Set production variable FIREBASE_ADMIN_ENABLED}"
: "${FIREBASE_PROJECT_ID:?Set production variable FIREBASE_PROJECT_ID}"

if [[ "${FIREBASE_ADMIN_ENABLED}" != 'true' ]]; then
  echo 'FIREBASE_ADMIN_ENABLED must be true for the production Firebase deployment.' >&2
  exit 1
fi

if [[ "${FIREBASE_PROJECT_ID}" != 'potato-mubwanna-prod' ]]; then
  echo 'FIREBASE_PROJECT_ID must be potato-mubwanna-prod for the production Firebase deployment.' >&2
  exit 1
fi

for value_name in FIREBASE_ADMIN_ENABLED FIREBASE_PROJECT_ID; do
  value="${!value_name}"
  case "${value}" in
    *$'\r'*|*$'\n'*)
      echo "${value_name} must be a single line." >&2
      exit 1
      ;;
  esac
done

for command_name in aws jq; do
  command -v "${command_name}" > /dev/null || {
    echo "Required command is missing: ${command_name}" >&2
    exit 1
  }
done

runner_directory="$(mktemp -d)"
exchange_id="$(date +%s)-$$"
production_repository_directory="${PRODUCTION_REPOSITORY_DIRECTORY:-/opt/potato-mubwanna}"
remote_env_file="${production_repository_directory}/deploy/.env"
remote_next_env="${remote_env_file}.next-firebase-${exchange_id}"

cleanup_runner() {
  rm -rf "${runner_directory}"
}
trap cleanup_runner EXIT

send_command() {
  local parameters_path="$1"

  aws ssm send-command \
    --region "${AWS_REGION}" \
    --instance-ids "${EC2_INSTANCE_ID}" \
    --document-name AWS-RunShellScript \
    --comment 'Apply Firebase production configuration' \
    --parameters "file://${parameters_path}" \
    --query 'Command.CommandId' \
    --output text
}

wait_for_command() {
  local command_id="$1"
  local result_path="$2"
  local deadline=$((SECONDS + 180))
  local status='Pending'

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

  if [[ "$(jq -r '.Status' "${result_path}")" != 'Success' ]]; then
    jq -r '.StandardErrorContent' "${result_path}" >&2
    return 1
  fi
}

config_parameters="${runner_directory}/config-parameters.json"
config_result="${runner_directory}/config-result.json"

jq -n \
  --arg env_file "${remote_env_file}" \
  --arg next_env "${remote_next_env}" \
  --arg firebase_admin_enabled "${FIREBASE_ADMIN_ENABLED}" \
  --arg firebase_project_id "${FIREBASE_PROJECT_ID}" \
  '{commands: [
    "set -eu",
    "umask 077",
    ("env_file=" + ($env_file | @sh)),
    ("next_env=" + ($next_env | @sh)),
    ("firebase_admin_enabled=" + ($firebase_admin_enabled | @sh)),
    ("firebase_project_id=" + ($firebase_project_id | @sh)),
    "test -f \"${env_file}\"",
    "test \"$(grep -c \"^FIREBASE_ADMIN_ENABLED=\" \"${env_file}\")\" -eq 1",
    "test \"$(grep -c \"^FIREBASE_PROJECT_ID=\" \"${env_file}\")\" -eq 1",
    "env_owner=\"$(stat -c %u:%g \"${env_file}\" 2>/dev/null || stat -f %u:%g \"${env_file}\")\"",
    "env_mode=\"$(stat -c %a \"${env_file}\" 2>/dev/null || stat -f %Lp \"${env_file}\")\"",
    "cp \"${env_file}\" \"${next_env}\"",
    "sed -i.bak \"s|^FIREBASE_ADMIN_ENABLED=.*|FIREBASE_ADMIN_ENABLED=${firebase_admin_enabled}|\" \"${next_env}\"",
    "sed -i.bak \"s|^FIREBASE_PROJECT_ID=.*|FIREBASE_PROJECT_ID=${firebase_project_id}|\" \"${next_env}\"",
    "rm -f \"${next_env}.bak\"",
    "chown \"${env_owner}\" \"${next_env}\"",
    "chmod \"${env_mode}\" \"${next_env}\"",
    "mv \"${next_env}\" \"${env_file}\"",
    "echo FIREBASE_PRODUCTION_CONFIG_SYNCED"
  ]}' > "${config_parameters}"

config_command_id="$(send_command "${config_parameters}")"
wait_for_command "${config_command_id}" "${config_result}"
jq -r '.StandardOutputContent' "${config_result}"
