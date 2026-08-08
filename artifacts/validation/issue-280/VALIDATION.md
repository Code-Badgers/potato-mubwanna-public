# Issue 280 Validation

## 작업 요약

- 이슈: #280
- 브랜치: `feat/280-backend-cd`
- 담당 영역: 백엔드 CI와 AWS ECR·SSM 기반 운영 CD
- 제외 범위: AWS 리소스 직접 생성, 도메인/TLS, 모바일 앱 배포, DB 백업
- 목표: 장기 AWS 키와 EC2 SSH 키 없이 검증된 불변 이미지를 배포하고 실패 시 직전 이미지로 복구한다.

## 변경 파일

- `.github/workflows/backend-ci.yml`: PR과 `main`의 백엔드 테스트, Compose 검사, 컨테이너 빌드
- `.github/workflows/backend-deploy.yml`: OIDC 인증, ECR 이미지 게시, SSM 배포, 수동 롤백
- `deploy/deploy-backend.sh`: 서버 배포, 헬스체크, 직전 이미지 자동 복구
- `deploy/tests/deploy-backend-test.sh`: 배포 성공 및 자동 복구 시나리오 테스트
- `deploy/compose.prod.yml`: `BACKEND_IMAGE`로 불변 ECR 이미지 주입
- `deploy/.env.example`: 로컬 기본 백엔드 이미지 예시
- `deploy/AWS_CD_SETUP.md`: AWS 최소 권한과 GitHub production environment 설정 절차
- `deploy/README.md`: ECR 기반 재기동 절차와 최초 설정 문서 연결

## 공유 파일 / 계약 변경

- 공유 위험 파일: `.github/workflows/*`, `deploy/compose.prod.yml`
- API 계약 변경: 없음
- DB migration: 없음
- 환경 변수: `BACKEND_IMAGE` 추가, GitHub environment variables `AWS_REGION`, `AWS_ROLE_ARN`, `ECR_REPOSITORY`, `EC2_INSTANCE_ID` 추가
- 외부 API: GitHub Actions OIDC, Amazon ECR, AWS Systems Manager 사용

## 검증

### 백엔드 전체 테스트 및 빌드

```powershell
cd backend
.\gradlew.bat test build --no-daemon
```

- 결과: `BUILD SUCCESSFUL`
- 테스트, `bootJar`, 전체 `build` 통과

### Actions 및 셸 정적 검사

```powershell
docker run --rm -v "${PWD}:/repo" -w /repo rhysd/actionlint:latest
docker run --rm -v "${PWD}:/mnt" koalaman/shellcheck:stable deploy/deploy-backend.sh deploy/tests/deploy-backend-test.sh
docker run --rm -v "${PWD}:/repo" -w /repo bash:5.2 bash -n deploy/deploy-backend.sh
```

- 결과: 최종 실행 모두 성공
- GitHub Actions 문법과 표현식, Bash 문법, ShellCheck 검사 통과

### 배포 성공 및 자동 복구 테스트

```powershell
docker run --rm -v "${PWD}:/repo" -w /repo bash:5.2 bash deploy/tests/deploy-backend-test.sh
```

- 새 이미지로 정상 전환하는 시나리오 통과
- 새 이미지 기동 실패 시 직전 `BACKEND_IMAGE`로 복구하는 시나리오 통과

### Compose 정적 및 전체 스택 검증

```powershell
docker compose --env-file deploy/.env.example -f deploy/compose.prod.yml config --quiet
docker compose -p potato-mubwanna-issue-280 --env-file deploy/.env.example -f deploy/compose.prod.yml up -d --build
docker compose -p potato-mubwanna-issue-280 --env-file deploy/.env.example -f deploy/compose.prod.yml up -d --no-build
curl.exe --fail --silent http://127.0.0.1/health
```

- Compose 설정 해석 성공
- PostGIS, Redis, Spring Boot, Nginx 모두 `healthy`
- 이미지 재빌드 없는 CD 재기동 성공
- `/health` 응답: `{"status":"UP"}`
- 측정 메모리: 백엔드 약 400MiB, PostGIS 약 107MiB, Redis 약 6MiB, Nginx 약 14MiB

### 정리

```powershell
docker compose -p potato-mubwanna-issue-280 --env-file deploy/.env.example -f deploy/compose.prod.yml down -v
```

- 라벨로 검증 전용 프로젝트를 확인한 뒤 컨테이너, 네트워크, 임시 볼륨 제거
- 남은 issue-280 검증용 컨테이너와 볼륨 없음

## 실패 및 해결 기록

1. 최초 Actionlint에서 GitHub output 파일에 대한 반복 리다이렉션 경고 발생
   - 해결: 하나의 명령 그룹으로 묶어 단일 리다이렉션으로 수정
2. Ubuntu 24.04의 AWS CLI 설치를 배포판 패키지에 의존하도록 작성한 초안 발견
   - 해결: AWS 공식 CLI v2 설치 방식과 SSM Agent Snap 확인 절차로 문서 수정

## 실행하지 못한 검증

- 실제 ECR push, GitHub OIDC 역할 위임, 운영 EC2 SSM 명령은 AWS 리소스와 GitHub environment variables가 아직 생성되지 않아 실행하지 않음
- 최초 AWS 설정 후 `main`에서 수동 CD를 한 번 실행해 end-to-end 배포를 확인해야 함

## 남은 리스크

- 첫 배포에는 직전 `BACKEND_IMAGE`가 없으므로 자동 복구 대상이 없다. 최초 배포 전에 로컬 Compose 기동을 완료해야 한다.
- 자동 복구도 실패하면 Actions 로그와 SSM 명령 결과를 확인해 서버에서 수동 복구해야 한다.
- ECR lifecycle policy와 EC2 데이터 백업은 별도 설정이 필요하다.
- 도메인과 HTTPS는 원스토어 출시 전에 추가해야 한다.

## 다음 작업

- `deploy/AWS_CD_SETUP.md` 순서로 ECR, EC2 instance role, GitHub OIDC role, read-only Deploy Key를 생성한다.
- GitHub `production` environment에 네 변수를 등록하고 `main` 기준 수동 배포를 실행한다.
- 실제 `/health`와 SSM 명령 결과를 확인한 후 `backend-v0.1.0` 릴리스 태그 흐름을 검증한다.
