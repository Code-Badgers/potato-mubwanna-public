<div align="center">

# 🥔 감자무봤나

### 강원 18개 시·군의 29개 관광지를 패스포트 스탬프로 연결하는 위치 기반 로컬 관광 서비스

감자 무봤나? 관광지는 보고, 스탬프는 찍고, 감자는 모으고

</div>

---

## 1. 프로젝트 소개

<img width="1672" height="941" alt="ChatGPT Image 2026년 7월 12일 오후 09_15_54" src="https://github.com/user-attachments/assets/8a320d10-ea22-43b7-8a22-f805db54c3bd" />

**감자무봤나**는 강원특별자치도 18개 시·군의 관광지, 음식점, 카페, 체험 시설을  
강원도의 대표 지역 IP인 감자와 게임 요소로 연결한 위치 기반 관광 서비스입니다.

사용자는 지도에서 주변 관광지를 탐색하고, 실제 관광지에 방문해 디지털 스탬프를 획득하며,  
지역별 감자 캐릭터와 미션 보상을 수집할 수 있습니다.

---

## 2. 주요 기능

| 기능 | 설명 |
| --- | --- |
| 감자 지도 | 강원도 관광지와 감자 관련 장소 탐색 |
| 스탬프 랠리 | 29개 관광지 방문 및 패스포트 스탬프 수집 |
| 감자 도감 | 지역별 감자 캐릭터 수집과 성장 |
| 점순이 미션 | 위치·퀴즈·걸음·QR 기반 미션 |
| 보상함 | 쿠폰과 미션·스탬프 보상 관리 |
| 여행 기록 | 방문 장소와 획득 기록 조회 |
| 관리자 | 관광지, 스탬프, 미션, 보상 관리 |

---

## 3. 활용 API

한국관광공사 국문 관광정보 서비스<br/>
한국관광공사 관광지 오디오 가이드 정보<br/>
한국관광공사 관광지 집중률 방문자 추이 예측 정보<br/>
한국관광공사 관광지별 연관 관광지 정보<br/>
Kakao Login API<br/>
Kakao Maps API<br/>
Kakao Local API<br/>
Firebase Cloud Messaging<br/>

## 4. 기술 스택

<img width="1448" height="1086" alt="ChatGPT Image 2026년 7월 12일 오후 09_38_26" src="https://github.com/user-attachments/assets/5868d421-9fb9-4ce2-9c73-4aeb837195e6" />

### Backend

| 분류 | 기술 |
| --- | --- |
| Language | Java 21 |
| Framework | Spring Boot 3.5.0 |
| Security | Spring Security, JWT |
| ORM | Spring Data JPA, QueryDSL 의존성 |
| Database | PostgreSQL |
| Migration | Flyway |
| Cache | Redis 의존성 및 연결 설정 |
| API Docs | Springdoc OpenAPI / Swagger UI |
| Build | Gradle 8.14.3 Wrapper |

### Frontend

| 분류 | 기술 |
| --- | --- |
| Framework | Flutter |
| Map | Kakao Maps JavaScript SDK, Android/iOS Native SDK Bridge |
| Login | Kakao Flutter SDK |
| Local Storage | Flutter Secure Storage, SharedPreferences |
| Push | Firebase Messaging 의존성 |
