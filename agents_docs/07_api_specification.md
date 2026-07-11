# 07_api_specification.md

# API 명세서

## 공통 규칙

Base URL:

```txt
/api
```

공통 응답:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {}
}
```

공통 에러 응답:

```json
{
  "success": false,
  "message": "에러 메시지",
  "code": "ERROR_CODE"
}
```

인증 방식:

```http
Authorization: Bearer {accessToken}
```

---

## 1. Auth API

### 1.1 카카오 로그인

```http
POST /api/auth/kakao
```

Request:

```json
{
  "accessToken": "kakao-access-token"
}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "accessToken": "jwt-access-token",
    "refreshToken": "jwt-refresh-token",
    "user": {
      "id": 1,
      "email": "user@email.com",
      "nickname": "감자러버",
      "profileImage": "https://..."
    }
  }
}
```

### 1.2 애플 로그인

```http
POST /api/auth/apple
```

Request:

```json
{
  "identityToken": "apple-identity-token"
}
```

### 1.3 토큰 재발급

```http
POST /api/auth/refresh
```

Request:

```json
{
  "refreshToken": "refresh-token"
}
```

### 1.4 로그아웃

```http
POST /api/auth/logout
```

### 1.5 회원 탈퇴

```http
DELETE /api/users/me
```

---

## 2. User API

### 2.1 내 정보 조회

```http
GET /api/users/me
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "id": 1,
    "email": "user@email.com",
    "nickname": "감자러버",
    "profileImage": "https://...",
    "stampCount": 5,
    "potatoCount": 3,
    "couponCount": 2
  }
}
```

### 2.2 내 여행 기록 조회

```http
GET /api/users/me/visits
```

---

## 3. Tourist Spot / Map API

### 3.1 관광지 목록 조회

```http
GET /api/spots
```

Query Params:

| 이름            | 타입   | 필수 | 설명                                       |
| --------------- | ------ | ---- | ------------------------------------------ |
| category        | String | N    | POTATO_TOUR, POTATO_EXPERIENCE, POTATO_RESTAURANT, POTATO_CAFE, POTATO_SNACK, POTATO_MARKET, POTATO_BREWERY, POTATO_SHOP |
| cityName        | String | N    | 강릉시, 평창군 등                          |
| congestionLevel | String | N    | LOW, NORMAL, HIGH                          |

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": [
    {
      "id": 1,
      "name": "정선 5일장",
      "category": "POTATO_TOUR",
      "latitude": 37.3801,
      "longitude": 128.6609,
      "address": "강원특별자치도 정선군...",
      "cityName": "정선군",
      "congestionLevel": "LOW",
      "stampEnabled": true
    }
  ]
}
```

### 3.2 주변 관광지 조회

```http
GET /api/spots/nearby
```

Query Params:

| 이름     | 타입    | 필수 | 설명            |
| -------- | ------- | ---- | --------------- |
| lat      | Double  | Y    | 사용자 위도     |
| lng      | Double  | Y    | 사용자 경도     |
| radius   | Integer | Y    | 검색 반경 meter |
| category | String  | N    | 카테고리        |

### 3.3 관광지 상세 조회

```http
GET /api/spots/{spotId}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "id": 1,
    "contentId": "1234567",
    "name": "정선 5일장",
    "category": "POTATO_TOUR",
    "latitude": 37.3801,
    "longitude": 128.6609,
    "address": "강원특별자치도 정선군...",
    "imageUrl": "https://...",
    "cityName": "정선군",
    "potatoTags": "감자,감자전",
    "congestionLevel": "LOW",
    "verificationRadiusMeter": 100,
    "stampEnabled": true
  }
}
```

### 3.4 관광지 혼잡도 조회

```http
GET /api/spots/{spotId}/congestion
```

### 3.5 내 동선 즐겨찾기 목록 조회

로그인한 사용자가 지도에서 저장한 감자 스팟 목록을 조회한다. 지도 탭의 즐겨찾기 표시와 추후 나만의 동선 생성에 사용한다.

```http
GET /api/me/favorite-spots
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": [
    {
      "spotId": 1,
      "name": "정선 5일장",
      "category": "POTATO_TOUR",
      "latitude": 37.3801,
      "longitude": 128.6609,
      "createdAt": "2026-06-21T10:00:00Z"
    }
  ]
}
```

### 3.6 내 동선 즐겨찾기 추가

```http
POST /api/me/favorite-spots/{spotId}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "spotId": 1,
    "favorite": true
  }
}
```

### 3.7 내 동선 즐겨찾기 삭제

```http
DELETE /api/me/favorite-spots/{spotId}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "spotId": 1,
    "favorite": false
  }
}
```

### 3.8 연관 관광지 추천

```http
GET /api/spots/{spotId}/recommendations
```

---

## 4. Stamp API

### 4.1 내 스탬프 목록 조회

```http
GET /api/stamps/me
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "totalCount": 18,
    "acquiredCount": 5,
    "stamps": [
      {
        "stampId": 1,
        "cityName": "강릉시",
        "stampName": "강릉 하지감자 스탬프",
        "stampImage": "https://...",
        "acquired": true,
        "acquiredAt": "2026-06-04T12:00:00"
      }
    ]
  }
}
```

### 4.2 GPS 방문 인증

```http
POST /api/stamps/verify
```

Request:

```json
{
  "touristSpotId": 1,
  "lat": 37.3801,
  "lng": 128.6609
}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "verified": true,
    "stampAcquired": true,
    "stamp": {
      "id": 1,
      "cityName": "정선군",
      "stampName": "정선 곤드레감자 스탬프"
    },
    "potatoAcquired": true,
    "potato": {
      "id": 3,
      "name": "곤드레감자",
      "rarity": "RARE"
    }
  }
}
```

### 4.3 보상 가능 여부 확인

```http
GET /api/stamps/rewards/check
```

### 4.4 스탬프 보상 수령

```http
POST /api/stamps/rewards/claim
```

---

## 5. Potato API

### 5.1 전체 감자 목록 조회

```http
GET /api/potatoes
```

### 5.2 내 감자 도감 조회

```http
GET /api/potatoes/me
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": [
    {
      "potatoId": 1,
      "name": "하지감자",
      "region": "강릉시",
      "rarity": "NORMAL",
      "imageUrl": "https://...",
      "acquired": true,
      "level": 2,
      "distance": 1500.0
    }
  ]
}
```

### 5.3 감자 상세 조회

```http
GET /api/potatoes/{potatoId}
```

### 5.4 감자 성장 처리

```http
POST /api/potatoes/{potatoId}/grow
```

Request:

```json
{
  "distance": 500.0
}
```

---

## 6. Mission API

### 6.1 주변 미션 조회

```http
GET /api/missions/nearby
```

Query Params:

| 이름   | 타입    | 필수 | 설명        |
| ------ | ------- | ---- | ----------- |
| lat    | Double  | Y    | 사용자 위도 |
| lng    | Double  | Y    | 사용자 경도 |
| radius | Integer | Y    | 검색 반경   |

### 6.2 미션 상세 조회

```http
GET /api/missions/{missionId}
```

### 6.3 미션 인증 및 완료 처리

```http
POST /api/missions/{missionId}/verify
```

Request:

```json
{
  "type": "QUIZ",
  "answer": "곤드레감자",
  "stepCount": null,
  "uploadKey": null,
  "qrCode": null
}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "missionId": 1004,
    "verified": true,
    "completed": true,
    "completedAt": "2026-07-01T00:00:00Z",
    "rewardType": "ITEM",
    "rewardLabel": "황금감자 성장 아이템"
  }
}
```

Validation failure:

```json
{
  "success": false,
  "message": "정답이 틀렸습니다. 다시 풀어주세요.",
  "code": "MISSION_VERIFICATION_FAILED"
}
```

Notes:

- `QUIZ`: `answer`를 검증한다.
- `VISIT_AND_STEP`: `stepCount`가 미션 목표 걸음 수 이상인지 검증한다.
- `PHOTO`, `PHOTO_OCR`: `uploadKey` 존재 여부를 검증한다. 실제 OCR 검증은 후속 연동에서 강화한다.
- `QR_SCAN`: `qrCode` 존재 여부를 검증한다. 실제 QR 코드 매칭은 후속 연동에서 강화한다.
- 인증 성공 시 서버가 중복 완료 여부를 확인하고 미션 완료와 보상 응답을 함께 처리한다.

---

## 7. Coupon API

### 7.1 내 쿠폰 목록 조회

```http
GET /api/coupons/me
```

### 7.2 쿠폰 상세 조회

```http
GET /api/coupons/{userCouponId}
```

### 7.3 쿠폰 사용 처리

```http
POST /api/coupons/{userCouponId}/use
```

### 7.4 보상 히스토리 조회

```http
GET /api/rewards/history
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "rewards": [
      {
        "rewardHistoryId": 1,
        "rewardType": "POTATO",
        "rewardName": "수미감자 씨앗",
        "sourceType": "MISSION",
        "sourceId": 1001,
        "createdAt": "2026-07-11T09:00:00Z"
      }
    ]
  }
}
```

Notes:

- 로그인 사용자의 보상 지급 이력을 `createdAt` 내림차순으로 반환한다.
- 보상 이력이 없으면 `rewards`는 빈 배열이다.
- 인증 정보가 없거나 JWT 사용자가 존재하지 않으면 `401 Unauthorized`를 반환한다.

---

## 8. Audio Guide API

### 8.1 관광지 오디오 가이드 조회

```http
GET /api/audio-guides/spots/{spotId}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "id": 1,
    "title": "정선 5일장 이야기",
    "audioUrl": "https://...",
    "script": "정선 5일장은...",
    "characterScript": "점순이: 여가 정선 5일장이래요!"
  }
}
```

---

## 9. Admin API

### 9.1 관광지 등록

```http
POST /api/admin/spots
```

### 9.2 관광지 수정

```http
PUT /api/admin/spots/{spotId}
```

### 9.3 관광지 삭제

```http
DELETE /api/admin/spots/{spotId}
```

### 9.4 감자 캐릭터 등록

```http
POST /api/admin/potatoes
```

### 9.5 미션 등록

```http
POST /api/admin/missions
```

### 9.6 쿠폰 등록

```http
POST /api/admin/coupons
```

---

# 08_frontend_architecture.md

# Frontend Architecture

## 1. 기술 스택

- Flutter
- Dart
- Riverpod
- GoRouter
- Dio
- Kakao Map
- Flutter Secure Storage
- Firebase Messaging
- Freezed
- Json Serializable

## 2. 패키지 구조

```txt
lib/
 ├─ main.dart
 ├─ app/
 │   ├─ app.dart
 │   ├─ router/
 │   │   └─ app_router.dart
 │   └─ theme/
 │       ├─ app_colors.dart
 │       ├─ app_text_styles.dart
 │       └─ app_theme.dart
 │
 ├─ core/
 │   ├─ constants/
 │   ├─ network/
 │   │   ├─ dio_client.dart
 │   │   ├─ api_response.dart
 │   │   └─ api_exception.dart
 │   ├─ storage/
 │   │   └─ secure_storage.dart
 │   ├─ location/
 │   │   └─ location_service.dart
 │   └─ permissions/
 │       └─ permission_service.dart
 │
 ├─ features/
 │   ├─ auth/
 │   │   ├─ data/
 │   │   ├─ domain/
 │   │   └─ presentation/
 │   │
 │   ├─ map/
 │   │   ├─ data/
 │   │   ├─ domain/
 │   │   └─ presentation/
 │   │
 │   ├─ spot/
 │   │   ├─ data/
 │   │   ├─ domain/
 │   │   └─ presentation/
 │   │
 │   ├─ stamp/
 │   │   ├─ data/
 │   │   ├─ domain/
 │   │   └─ presentation/
 │   │
 │   ├─ potato/
 │   │   ├─ data/
 │   │   ├─ domain/
 │   │   └─ presentation/
 │   │
 │   ├─ mission/
 │   │   ├─ data/
 │   │   ├─ domain/
 │   │   └─ presentation/
 │   │
 │   ├─ coupon/
 │   │   ├─ data/
 │   │   ├─ domain/
 │   │   └─ presentation/
 │   │
 │   └─ mypage/
 │       ├─ data/
 │       ├─ domain/
 │       └─ presentation/
```

## 3. Feature 내부 구조

```txt
feature/
 ├─ data/
 │   ├─ datasource/
 │   ├─ dto/
 │   └─ repository_impl/
 ├─ domain/
 │   ├─ entity/
 │   ├─ repository/
 │   └─ usecase/
 └─ presentation/
     ├─ screen/
     ├─ widget/
     └─ provider/
```

## 4. 주요 화면

### 4.1 OnboardingScreen

- 서비스 소개
- 위치 권한 안내
- 푸시 권한 안내
- 로그인 화면 이동

### 4.2 LoginScreen

- 카카오 로그인
- 애플 로그인
- 로그인 실패 처리

### 4.3 MapScreen

- 카카오맵 표시
- 현재 위치 표시
- 감자 스팟 마커 표시
- 카테고리 필터
- 주변 관광지 조회
- 미션 팝업 표시

### 4.4 SpotDetailScreen

- 관광지 상세 정보
- 혼잡도 표시
- 방문 인증 버튼
- 오디오 가이드
- 다음 목적지 추천

### 4.5 StampBookScreen

- 18개 시군 스탬프 현황
- 수집률 표시
- 보상 수령 버튼

### 4.6 PotatoCollectionScreen

- 감자 탭
- 대표 감자
- 오늘의 감자걸음
- 감자 성장
- 감자 도감
- 획득 / 미획득 감자 표시
- 감자 상세 화면 이동

### 4.7 MissionScreen

- 점순이 미션
- 일일 미션
- 주간 미션
- 이벤트 미션
- 미션 보상

### 4.8 MyPageScreen

- 내 정보
- 보상함
- 보유 쿠폰 목록
- QR 코드 표시
- 여행 기록
- 알림 설정
- 위치 권한 설정
- 로그아웃
- 회원 탈퇴

## 5. 라우팅 설계

```txt
/onboarding
/login
/main
/main/map
/main/stamps
/main/potatoes
/main/missions
/main/mypage
/spots/:spotId
/potatoes/:potatoId
/missions/:missionId
/coupons/:couponId
```

## 6. 상태관리 기준

Riverpod을 사용한다.

- AuthProvider
- LocationProvider
- SpotProvider
- StampProvider
- PotatoProvider
- MissionProvider
- CouponProvider
- MyPageProvider

## 7. 네트워크 규칙

- Dio 사용
- JWT Access Token 자동 첨부
- 401 발생 시 Refresh Token으로 재발급
- 재발급 실패 시 로그인 화면 이동
- API 응답은 공통 ApiResponse로 파싱

## 8. 지도 구현 기준

- Kakao Map 기반 구현
- 현재 위치 마커 표시
- 관광지 마커는 감자 아이콘 사용
- 카테고리별 마커 필터링
- 마커 클릭 시 관광지 상세로 이동
- 방문 인증은 서버 API에서 최종 검증한다

## 9. 위치 권한 기준

- 최초 실행 시 위치 권한 안내
- 방문 인증 시 위치 권한 필수
- 권한 거부 시 설정 화면 이동 안내
- 클라이언트 위치는 참고값이며, 최종 인증은 서버에서 처리한다

## 10. MVP 구현 우선순위

1. 온보딩
2. 로그인
3. 지도
4. 관광지 상세
5. GPS 방문 인증
6. 스탬프북
7. 감자
8. 미션
9. 마이페이지 / 보상함
