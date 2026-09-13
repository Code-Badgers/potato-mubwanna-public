#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
frontend_dir="$(cd "${script_dir}/.." && pwd)"
release_env="${1:-${frontend_dir}/.env.release}"
expected_api_url="https://potato-mubwanna.duckdns.org/api"
expected_signer_sha256="b5f5a6730ef76204ad1d36a2f59e4fe8224cfb5be963a937dca2ca412f5e68ec"
expected_kakao_key_hash="ZaC6hYKddo+HBQm4AX7uvreD/Iw="

cleanup_secrets() {
  unset ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_PASSWORD KAKAO_NATIVE_APP_KEY
  unset keystore_password kakao_native_key
}
trap cleanup_secrets EXIT

read_env_value() {
  local name="$1"
  local value

  value="$(sed -n "s/^${name}=//p" "${release_env}" | tail -n 1 | tr -d '\r')"
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "${value}"
}

find_apksigner() {
  local sdk_root candidate

  if [[ -n "${APKSIGNER_PATH:-}" && -f "${APKSIGNER_PATH}" ]]; then
    printf '%s' "${APKSIGNER_PATH}"
    return
  fi
  if command -v apksigner >/dev/null 2>&1; then
    command -v apksigner
    return
  fi

  for sdk_root in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" "${HOME:-}/Library/Android/sdk"; do
    [[ -d "${sdk_root}/build-tools" ]] || continue
    candidate="$(find "${sdk_root}/build-tools" -type f -name apksigner -print | sort | tail -n 1)"
    if [[ -n "${candidate}" ]]; then
      printf '%s' "${candidate}"
      return
    fi
  done

  echo "apksigner를 찾지 못했습니다. APKSIGNER_PATH를 지정해 주세요." >&2
  return 1
}

if [[ ! -f "${release_env}" ]]; then
  echo "릴리스 환경 파일을 찾지 못했습니다: ${release_env}" >&2
  echo "frontend/.env.release.example을 복사해 비밀값을 채워 주세요." >&2
  exit 1
fi
release_env="$(cd "$(dirname "${release_env}")" && pwd)/$(basename "${release_env}")"

if [[ -z "${ANDROID_KEYSTORE_PATH:-}" || ! -f "${ANDROID_KEYSTORE_PATH}" ]]; then
  echo "ANDROID_KEYSTORE_PATH가 실제 키스토어 파일을 가리켜야 합니다." >&2
  exit 1
fi
ANDROID_KEYSTORE_PATH="$(cd "$(dirname "${ANDROID_KEYSTORE_PATH}")" && pwd)/$(basename "${ANDROID_KEYSTORE_PATH}")"
export ANDROID_KEYSTORE_PATH

export ANDROID_KEY_ALIAS="${ANDROID_KEY_ALIAS:-potato-mubwanna-release}"
release_api_url="$(read_env_value API_BASE_URL)"
if [[ "${release_api_url}" != "${expected_api_url}" ]]; then
  echo "운영 API 주소가 기대값과 다릅니다: ${release_api_url}" >&2
  exit 1
fi

kakao_native_key="$(read_env_value KAKAO_NATIVE_APP_KEY)"
if [[ -z "${kakao_native_key}" ]]; then
  echo "KAKAO_NATIVE_APP_KEY가 비어 있습니다." >&2
  exit 1
fi
export KAKAO_NATIVE_APP_KEY="${kakao_native_key}"

if [[ -z "${ANDROID_KEYSTORE_PASSWORD:-}" ]]; then
  printf '키스토어 비밀번호 입력: '
  IFS= read -r -s keystore_password
  printf '\n'
  export ANDROID_KEYSTORE_PASSWORD="${keystore_password}"
fi
export ANDROID_KEY_PASSWORD="${ANDROID_KEY_PASSWORD:-${ANDROID_KEYSTORE_PASSWORD}}"

keytool_output="$(keytool -J-Duser.language=en -list -v \
  -keystore "${ANDROID_KEYSTORE_PATH}" \
  -alias "${ANDROID_KEY_ALIAS}" \
  -storepass:env ANDROID_KEYSTORE_PASSWORD 2>/dev/null)" || {
    echo "키스토어 비밀번호 또는 별칭이 맞지 않습니다." >&2
    exit 1
  }

keystore_signer="$(printf '%s\n' "${keytool_output}" \
  | sed -n 's/^[[:space:]]*SHA256: //p' \
  | tr -d ':' \
  | tr '[:upper:]' '[:lower:]' \
  | head -n 1)"
if [[ "${keystore_signer}" != "${expected_signer_sha256}" ]]; then
  echo "선택한 키스토어가 감자무봤나 운영 서명키와 다릅니다." >&2
  exit 1
fi
echo "운영 서명키를 확인했습니다."

cd "${frontend_dir}"
flutter build apk --release --dart-define-from-file="${release_env}"

built_apk="${frontend_dir}/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "${built_apk}" ]]; then
  echo "빌드 결과 APK를 찾을 수 없습니다." >&2
  exit 1
fi

apksigner_path="$(find_apksigner)"
"${apksigner_path}" verify --verbose --print-certs "${built_apk}" >/dev/null
built_signer="$("${apksigner_path}" verify --print-certs "${built_apk}" \
  | sed -n 's/^Signer #1 certificate SHA-256 digest: //p' \
  | head -n 1)"
if [[ "${built_signer}" != "${expected_signer_sha256}" ]]; then
  echo "새 APK가 감자무봤나 운영 서명키로 서명되지 않았습니다." >&2
  exit 1
fi

built_sha1="$("${apksigner_path}" verify --print-certs "${built_apk}" \
  | sed -n 's/^Signer #1 certificate SHA-1 digest: //p' \
  | head -n 1)"
built_kakao_key_hash="$(printf '%s' "${built_sha1}" | xxd -r -p | openssl base64)"
if [[ "${built_kakao_key_hash}" != "${expected_kakao_key_hash}" ]]; then
  echo "새 APK의 카카오 출시 키 해시가 등록된 운영값과 다릅니다." >&2
  exit 1
fi

api_match_count="$(unzip -p "${built_apk}" lib/arm64-v8a/libapp.so \
  | strings \
  | grep -Fc "${expected_api_url}" || true)"
localhost_match_count="$(unzip -p "${built_apk}" lib/arm64-v8a/libapp.so \
  | strings \
  | grep -Fc 'http://localhost:8080/api' || true)"

if [[ "${api_match_count:-0}" -lt 1 ]]; then
  echo "새 APK에서 운영 API 주소를 찾지 못했습니다." >&2
  exit 1
fi
if [[ "${localhost_match_count:-0}" -ne 0 ]]; then
  echo "새 APK에 localhost API 주소가 남아 있습니다." >&2
  exit 1
fi

echo "APK 빌드와 자동 검증을 통과했습니다."
echo "결과 파일: ${built_apk}"
shasum -a 256 "${built_apk}"
