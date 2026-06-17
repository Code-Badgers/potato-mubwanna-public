# 감자무봤나 (Potato Mubwatna)

## 01_project_overview

### 서비스 소개

감자무봤나는 강원특별자치도 18개 시군 관광지를 대상으로 하는 위치기반 관광 스탬프 랠리 서비스이다.

사용자는 관광지를 방문하여 디지털 스탬프를 수집하고, 지역별 감자 캐릭터를 획득하며, 쿠폰 및 보상을 받을 수 있다.

본 서비스는 한국관광공사 OpenAPI를 활용하여 관광지 정보, 오디오 가이드, 관광객 집중도 데이터를 활용한다.

---

## 개발 목표

### MVP 목표

1. 회원가입 및 로그인
2. 감자 지도
3. GPS 기반 방문 인증
4. 디지털 스탬프 랠리
5. 감자 성장 / 감자 도감
6. 점순이 미션
7. 마이페이지 보상함
8. 관리자 기능

---

## 핵심 컨셉

### 감자 지도

강원도 관광지 정보를 감자 아이콘으로 표현

### 스탬프 랠리

18개 시군 관광지 방문 시 스탬프 획득

### 감자

대표 감자 설정, 걸음 기반 성장, 지역별 감자 캐릭터 수집

### 점순이 미션

위치 기반 퀘스트 제공

### 마이페이지 보상함

쿠폰 및 아이템 지급

---

## 기술 스택

Frontend:

- Flutter
- Riverpod
- GoRouter
- Dio
- Kakao Map
- Firebase Messaging

Backend:

- Spring Boot 3.5.x
- Spring Security
- JWT
- JPA
- QueryDSL
- PostgreSQL
- PostGIS
- Redis

Infrastructure:

- Docker
- AWS
- S3
- GitHub Actions

---

## 프로젝트 구조

frontend/
backend/
docs/

Monorepo 구조를 사용한다.

---

## 참고 문서

02_tech_stack.md
03_information_architecture.md
04_user_flow.md
05_functional_specification.md
06_database_erd.md
07_api_specification.md
08_frontend_architecture.md
09_backend_architecture.md

위 문서를 기준으로 개발한다.
