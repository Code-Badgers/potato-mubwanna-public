# Issue 282 Validation

## 작업 요약

- 이슈: #282
- 브랜치: `refactor/282-ec2-direct-build-cd`
- 담당 영역: ECR 없는 SSM·EC2 직접 빌드 백엔드 CD
- 제외 범위: API/DB 변경, 도메인/TLS, EC2 스펙 변경, 다른 컨테이너 저장소 도입
- 목표: 추가 컨테이너 저장소 없이 Git SHA 기반 배포, 자동 복구, 수동 롤백을 유지한다.

## 변경 파일

- `.gitattributes`: 배포 Bash 스크립트의 LF 줄바꿈 강제
- `.github/workflows/backend-deploy.yml`: ECR build/push/pull과 관련 변수를 제거하고 SSM으로 EC2 직접 빌드 실행
- `deploy/deploy-backend.sh`: 로컬 이미지 빌드, Compose 교체, 자동 복구, 오래된 이미지 정리
- `deploy/tests/deploy-backend-test.sh`: 직접 빌드, 자동 복구, 기존 이미지 수동 롤백 시나리오
- `deploy/AWS_CD_SETUP.md`: ECR와 서버 AWS CLI 요구 없이 SSM 최소 권한 설정으로 개정
- `deploy/README.md`: 로컬 이미지 기반 재기동 절차로 개정

## 공유 파일 / 계약 변경

- 공유 위험 파일: `.github/workflows/backend-deploy.yml`, `.gitattributes`
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: GitHub production variable `ECR_REPOSITORY` 제거, `AWS_REGION`, `AWS_ROLE_ARN`, `EC2_INSTANCE_ID` 유지
- 외부 API: Amazon ECR 제거, GitHub Actions OIDC와 AWS Systems Manager 유지

## 검증

### 백엔드 전체 테스트 및 빌드

```powershell
cd backend
.\gradlew.bat test build --no-daemon
```

- 결과: `BUILD SUCCESSFUL` (1분 23초)
- 테스트, `bootJar`, 전체 `build` 통과

### Actions와 Bash 정적 검사

```powershell
docker run --rm -v "${PWD}:/repo" -w /repo rhysd/actionlint:latest
docker run --rm -v "${PWD}:/mnt" koalaman/shellcheck:stable deploy/deploy-backend.sh deploy/tests/deploy-backend-test.sh
docker compose --env-file deploy/.env.example -f deploy/compose.prod.yml config --quiet
git diff --check
```

- 결과: 최종 실행 모두 성공
- `.gitattributes` 확인 결과 두 Bash 스크립트 모두 `text: set`, `eol: lf`

### 배포 스크립트 시나리오

```powershell
docker run --rm -v "${PWD}:/repo" -w /repo bash:5.2 bash deploy/tests/deploy-backend-test.sh
```

- 새 `sha-*` 로컬 이미지 직접 빌드 경로 통과
- 새 이미지 기동 실패 시 직전 `BACKEND_IMAGE` 자동 복구 경로 통과
- 기존 로컬 이미지 태그를 지정한 수동 롤백에서 재빌드하지 않는 경로 통과

### 실제 Docker 직접 빌드와 전체 스택

```powershell
docker build --file backend/Dockerfile --tag potato-mubwanna-backend:sha-issue282 backend
$env:BACKEND_IMAGE='potato-mubwanna-backend:sha-issue282'
docker compose -p potato-mubwanna-issue-282 --env-file deploy/.env.example -f deploy/compose.prod.yml up -d --no-build
curl.exe --fail --silent http://127.0.0.1/health
```

- 로컬 SHA 태그 이미지 빌드 성공
- PostGIS, Redis, Spring Boot, Nginx 모두 `healthy`
- `/health` 응답: `{"status":"UP"}`
- 측정 메모리: 백엔드 약 455MiB, PostGIS 약 105MiB, Redis 약 6MiB, Nginx 약 14MiB

### 정리

```powershell
docker compose -p potato-mubwanna-issue-282 --env-file deploy/.env.example -f deploy/compose.prod.yml down -v
docker image rm potato-mubwanna-backend:sha-issue282
```

- 라벨과 이미지 태그로 검증 전용 대상 확인 후 컨테이너, 네트워크, 임시 볼륨, 테스트 이미지 제거
- 남은 issue-282 검증용 컨테이너와 볼륨 없음

## 실패 및 해결 기록

1. 최초 ShellCheck와 Bash 실행에서 배포 스크립트의 CRLF 줄바꿈 오류 발생
   - 원인: Windows 저장소 설정 `core.autocrlf=true`가 Linux 실행용 `.sh` 파일을 CRLF로 checkout
   - 해결: `.gitattributes`에 배포 스크립트의 `eol=lf` 규칙을 추가하고 파일을 LF로 정규화
2. ECR 제거 초안에 `docker compose pull backend`가 한 줄 남아 로컬 이미지 대신 외부 registry를 조회할 위험 확인
   - 해결: pull 명령을 제거하고 `docker image inspect`와 `up -d --no-build`만 사용

## 실행하지 못한 검증

- 실제 GitHub OIDC 역할 위임과 운영 EC2 SSM 명령은 AWS IAM·GitHub production environment 최초 설정 전이라 실행하지 않음
- 로컬 Docker 빌드는 캐시가 적용되었으므로 t3.small의 실제 최초 빌드 시간과 CPU 사용량을 나타내지 않음

## 남은 리스크

- ECR 방식보다 EC2 배포 중 CPU와 메모리 사용량이 높고 배포 시간이 길다.
- 최초 배포에서 직전 로컬 이미지가 없다면 자동 복구할 대상이 없다.
- CD는 디스크 보호를 위해 현재와 직전 백엔드 이미지만 유지하므로 더 오래된 버전은 해당 Git ref에서 다시 빌드해야 한다.
- 실제 운영 EC2에서 첫 배포 시 메모리, 스왑, 디스크와 헬스체크를 함께 확인해야 한다.

## 다음 작업

- `deploy/AWS_CD_SETUP.md` 순서로 EC2 instance role, GitHub OIDC role, read-only Deploy Key를 설정한다.
- GitHub `production` environment에 `AWS_REGION`, `AWS_ROLE_ARN`, `EC2_INSTANCE_ID`를 등록한다.
- `main` 기준 수동 CD를 한 번 실행하고 SSM 결과와 운영 `/health`를 확인한다.
