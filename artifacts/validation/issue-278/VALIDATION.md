# Issue 278 Validation

## 작업 요약

- 이슈: #278
- 브랜치: `feat/278-ec2-mvp-deployment`
- 담당 영역: EC2 단일 호스트 MVP 배포 구성
- 제외 범위: 도메인/TLS, RDS 전환, Firebase 서비스 계정 연결, GitHub Actions 자동 배포
- 목표: 최신 `main`의 백엔드를 PostGIS, Redis, Nginx와 함께 재현 가능하게 기동한다.

## 변경 파일

- `backend/Dockerfile`: Java 21 멀티스테이지 빌드와 비관리자 런타임 사용자
- `backend/.dockerignore`: 로컬 빌드 및 비밀 파일 제외
- `deploy/compose.prod.yml`: PostGIS, Redis, 백엔드, Nginx 운영 스택
- `deploy/nginx/default.conf`: `/api/` 프록시와 `/health` 헬스체크
- `deploy/.env.example`: 비밀값 없는 운영 환경변수 예시
- `deploy/README.md`: 최초 배포, 재배포, 로그, 중지 절차

## 공유 파일 / 계약 변경

- 공유 위험 파일: 없음
- API 계약 변경: 없음
- DB migration: 기존 V1~V28을 그대로 사용하며 변경 없음
- 환경 변수: `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`, `COUPON_QR_SECRET`과 기존 외부 API 키를 Compose에 연결
- 외부 API: 계약 변경 없음

## 검증

### 백엔드 테스트 및 빌드

```powershell
cd backend
.\gradlew.bat test build
```

- 결과: `BUILD SUCCESSFUL`
- 테스트, `bootJar`, 전체 `build` 통과

### Compose 정적 검증

```powershell
cd deploy
docker compose --env-file .env.example -f compose.prod.yml config --quiet
```

- 결과: 성공
- 필수 환경변수와 서비스 의존성 해석 통과

### 전체 스택 기동

```powershell
docker compose -p potato-mubwanna-issue-278 --env-file .env.example -f compose.prod.yml up -d --build
docker compose -p potato-mubwanna-issue-278 --env-file .env.example -f compose.prod.yml ps
```

- PostGIS: healthy
- Redis: healthy
- Spring Boot: healthy
- Nginx: healthy
- 외부 공개 포트: Nginx 80만 공개
- 내부 전용 포트: 백엔드 8080, PostgreSQL 5432, Redis 6379

### API 및 데이터 검증

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1/health'
Invoke-RestMethod -Uri 'http://127.0.0.1/api/actuator/health'
```

- 결과: 두 요청 모두 `{"status":"UP"}`
- Flyway: V1~V28 총 28개 migration 적용 성공
- 미션 업로드 볼륨: 비관리자 백엔드 사용자로 파일 생성/삭제 성공

### 리소스 사용량

- Spring Boot: 약 409MiB / 768MiB
- PostgreSQL/PostGIS: 약 77MiB / 512MiB
- Redis: 약 4MiB / 128MiB
- Nginx: 약 13MiB / 64MiB
- EC2 t3.small의 2GB 메모리와 2GB 스왑 구성을 기준으로 기동 여유 확인

### 정리

```powershell
docker compose -p potato-mubwanna-issue-278 --env-file .env.example -f compose.prod.yml down -v
```

- 검증 전용 프로젝트의 컨테이너, 네트워크, 빈 볼륨만 제거
- 남은 검증용 컨테이너/볼륨 없음

## 실패 및 해결 기록

1. 최초 Docker 빌드에서 Windows CRLF가 적용된 `gradlew`를 Linux가 실행하지 못함
   - 증상: `./gradlew: not found`
   - 해결: Docker 빌드 단계에서 `gradlew` 줄바꿈을 LF로 정규화
2. 최초 Nginx 헬스체크에서 `localhost`가 IPv6로 해석되어 연결 거부
   - 증상: `wget: can't connect to remote host: Connection refused`
   - 해결: 헬스체크 대상을 `127.0.0.1`로 명시
3. 미션 업로드 명명 볼륨의 비관리자 쓰기 권한 위험 확인
   - 해결: 이미지에 업로드 디렉터리를 미리 만들고 런타임 사용자 소유로 지정한 뒤 실제 쓰기 검증

## 남은 리스크

- 현재 구성은 HTTP 80만 제공한다. 원스토어 출시용 앱 연결 전 도메인과 HTTPS 443 적용이 필요하다.
- PostgreSQL과 업로드 파일이 단일 EC2 볼륨에 있으므로 스냅샷 또는 외부 백업이 필요하다.
- Firebase Admin은 기본 비활성이다. 푸시 기능 운영 전 서비스 계정 파일을 저장소 밖에서 읽기 전용으로 연결해야 한다.
- `t3.small`은 MVP 초기 트래픽 기준이다. 실제 메모리, CPU 크레딧, 응답시간을 모니터링해 증설을 판단한다.

## 다음 작업

```bash
git clone --branch feat/278-ec2-mvp-deployment <repository-url> potato-mubwanna
cd potato-mubwanna
cp deploy/.env.example deploy/.env
chmod 600 deploy/.env
```

- 실제 비밀값을 `deploy/.env`에 입력한 뒤 Compose로 기동한다.
- 도메인과 TLS 적용은 별도 이슈로 진행한다.
