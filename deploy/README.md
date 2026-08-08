# EC2 MVP Deployment

이 구성은 Ubuntu 24.04 EC2 한 대에서 PostGIS, Redis, Spring Boot, Nginx를 Docker Compose로 실행한다.
외부에는 Nginx의 80번 포트만 공개하며 데이터베이스, Redis, 백엔드 8080 포트는 Docker 내부 네트워크에서만 접근한다.

## 사전 조건

- Docker Engine 및 Docker Compose가 설치되어 있어야 한다.
- EC2 보안 그룹은 SSH 22번을 관리자 IP에만, HTTP 80번과 HTTPS 443번을 외부에 허용한다.
- EC2에는 최소 2GB 스왑을 설정한다.

## 최초 배포

```bash
cp deploy/.env.example deploy/.env
chmod 600 deploy/.env
```

`deploy/.env`의 비밀번호와 서명 키를 임의의 긴 값으로 교체하고 필요한 외부 API 키를 입력한다. 실제 값은 Git에 커밋하지 않는다.

```bash
cd deploy
docker compose --env-file .env -f compose.prod.yml config
docker compose --env-file .env -f compose.prod.yml up -d --build
docker compose --env-file .env -f compose.prod.yml ps
curl --fail http://localhost/health
```

정상 상태이면 외부에서 `http://<server-ip>/health`가 `UP` 응답을 반환한다.

## 로그와 재배포

```bash
cd deploy
docker compose --env-file .env -f compose.prod.yml logs --tail=200 backend
docker compose --env-file .env -f compose.prod.yml up -d --build
```

GitHub Actions 기반 SSM 배포를 설정한 환경은 `AWS_CD_SETUP.md`를 따른다. CD가 기록한 로컬 `BACKEND_IMAGE` 값을 유지한 채 서버에서 재기동하려면 다음 명령을 사용한다.

```bash
docker compose --env-file .env -f compose.prod.yml up -d --no-build
```

## 중지와 롤백

```bash
cd deploy
docker compose --env-file .env -f compose.prod.yml down
```

`down`은 컨테이너와 네트워크만 제거한다. PostgreSQL, Redis, 미션 업로드 데이터는 명명된 볼륨에 남는다. 운영 데이터를 지우므로 `down -v`는 사용하지 않는다.

## 운영 전 남은 작업

- 도메인을 고정 IP에 연결하고 443번 TLS를 적용한다.
- Firebase Admin을 활성화할 경우 서비스 계정 파일을 저장소 밖에 두고 읽기 전용으로 마운트한다.
- EC2 외부 스냅샷 또는 PostgreSQL 백업을 구성한다.
- `AWS_CD_SETUP.md`에 따라 GitHub OIDC, SSM, production environment 최초 설정을 완료한다.
