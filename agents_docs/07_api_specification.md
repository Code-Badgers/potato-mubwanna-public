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

### 2.2 내 활동 요약 조회

```http
GET /api/users/me/activity-summary
Authorization: Bearer {accessToken}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "totalSteps": 256842,
    "stampCount": 12,
    "ownedPotatoCount": 7
  }
}
```

- `totalSteps`는 서버의 `user_daily_activities`에 동기화된 걸음 수 합계다.
- 활동, 스탬프 또는 감자 데이터가 없으면 해당 값은 `0`이다.
- 인증 사용자와 연결된 계정이 없으면 `401 Unauthorized`를 반환한다.

### 2.3 내 여행 기록 조회

```http
GET /api/users/me/visits
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": [
    {
      "visitId": 1,
      "spotId": 10,
      "spotName": "정선 5일장",
      "category": "POTATO_MARKET",
      "cityName": "정선군",
      "address": "강원특별자치도 정선군...",
      "imageUrl": "https://...",
      "visitedAt": "2026-07-27T12:00:00Z"
    }
  ]
}
```

- `data`는 `visitedAt` 내림차순으로 정렬한다.
- 방문 기록이 없으면 빈 배열을 반환한다.
- 방문 기록은 방문 인증 시 저장된 `user_visits`를 기준으로 한다.

### 2.4 내 푸시 토큰 등록/갱신

```http
POST /api/users/me/push-tokens
Authorization: Bearer {accessToken}
Content-Type: application/json
```

Request:

```json
{
  "token": "fcm-registration-token",
  "platform": "ANDROID",
  "previousToken": "previous-fcm-registration-token"
}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "registered": true,
    "platform": "ANDROID",
    "registeredAt": "2026-07-31T03:30:00Z"
  }
}
```

- `platform`은 `ANDROID`, `IOS`, `WEB` 중 하나다.
- `previousToken`은 FCM token refresh 때만 보내는 선택값이다. 현재 사용자가 소유한 이전 토큰만 삭제한다.
- 같은 `token`을 다시 등록하면 사용자, platform, 갱신 시각을 최신 값으로 idempotent upsert한다.
- registration token 원문은 서버 로그에 남기지 않는다.

### 2.5 내 푸시 토큰 삭제

```http
DELETE /api/users/me/push-tokens
Authorization: Bearer {accessToken}
Content-Type: application/json
```

Request:

```json
{
  "token": "fcm-registration-token"
}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": null
}
```

- 로그아웃과 알림 동의 철회는 인증 토큰을 지우기 전에 이 endpoint를 호출한다.
- 이미 삭제됐거나 현재 사용자 소유가 아닌 token 삭제 요청도 idempotent success로 처리한다.
- 회원 탈퇴 시 사용자 token은 FK cascade로 삭제한다.
- 서버 발송에서 FCM이 registration token을 무효로 판정하면 해당 token을 즉시 삭제하고, 장기간 갱신되지 않은 token은 다음 등록 시 정리한다.

### 2.6 푸시 알림 라우팅 payload

FCM data payload는 다음 목적지만 허용한다.

| `destination` | 앱 이동 경로 | `destinationId` |
| --- | --- | --- |
| `MISSIONS` | `/main/missions` | 사용하지 않음 |
| `COUPONS` | `/coupons` | 사용하지 않음 |
| `STAMPS` | `/main/stamps` | 사용하지 않음 |
| `MAP` | `/main/map` | 사용하지 않음 |
| `SPOT` | `/spots/{spotId}` | 양의 정수 `spotId` 필수 |

- 앱은 foreground message를 인앱 알림으로 표시하고, 알림 탭과 종료 상태의 initial message를 동일한 whitelist resolver로 처리한다.
- 알 수 없는 `destination` 또는 유효하지 않은 `destinationId`는 화면 이동 없이 무시한다.
- Firebase client 설정이 없거나 서버의 `FIREBASE_ADMIN_ENABLED=false`인 환경은 push 기능만 비활성화하며 앱/서버 시작은 계속한다.

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
      "stampEnabled": true,
      "menuItems": []
    },
    {
      "id": 3,
      "name": "감자밭",
      "category": "POTATO_CAFE",
      "latitude": 37.9256574,
      "longitude": 127.7500695,
      "address": "강원특별자치도 춘천시 신북읍 신샘밭로 674",
      "cityName": "춘천시",
      "congestionLevel": "NORMAL",
      "stampEnabled": true,
      "menuItems": [
        {
          "name": "감자빵",
          "priceWon": 3300,
          "priceNote": null,
          "verifiedOn": "2026-08-03"
        }
      ]
    }
  ]
}
```

처리 규칙:

- `menuItems`는 활성 메뉴를 `displayOrder`, 메뉴 ID 순으로 정렬해 장소별 최대 3개 반환한다.
- 고정 가격이 확인된 메뉴는 `priceWon`에 0 이상의 원화 정수를 반환하고 `priceNote`는 `null`이다.
- 고정 가격이 없는 메뉴는 `priceWon=null`과 비어 있지 않은 `priceNote`를 반환한다.
- `verifiedOn`은 저장된 가격을 공개 출처에서 마지막으로 확인한 날짜다.
- 확인 가능한 메뉴가 없는 장소는 `menuItems=[]`를 반환하며 임의 메뉴나 가격을 생성하지 않는다.
- 초기 큐레이션 가격은 2026-08-03 Kakao 장소 페이지에서 확인했으며 출처 URL은 서버 DB에 함께 저장한다.

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

### 3.8 내 동선 추천 경로 조회

로그인한 사용자가 지도에서 저장한 감자 스팟을 가까운 순서의 추천 동선으로 조회한다. 프론트 지도 Polyline 렌더링과 추천 동선 바텀시트에 사용한다.

```http
GET /api/me/favorite-spots/route
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "routeName": "나만의 감자 동선",
    "totalDistanceKm": 18.4,
    "estimatedMinutes": 65,
    "waypoints": [
      {
        "order": 1,
        "spotId": 1,
        "name": "정선 5일장",
        "category": "POTATO_TOUR",
        "latitude": 37.3801,
        "longitude": 128.6609,
        "distanceFromPreviousKm": 0
      }
    ],
    "polyline": [
      {
        "latitude": 37.3801,
        "longitude": 128.6609
      }
    ]
  }
}
```

### 3.9 연관 관광지 추천

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
POST /api/visits/verify
```

Request:

```json
{
  "spotId": 1,
  "latitude": 37.3801,
  "longitude": 128.6609
}
```

Response:

```json
{
  "success": true,
  "message": "방문 인증이 완료되었습니다.",
  "data": {
    "spotId": 1,
    "verified": true,
    "distanceMeters": 23.5,
    "verificationRadiusMeter": 100,
    "stampIssued": true,
    "potatoAcquired": true,
    "acquiredPotato": {
      "potatoId": 3,
      "code": "POTATO_GOLDEN_GANGWON",
      "name": "황금감자",
      "region": "강원특별자치도",
      "rarity": "EPIC",
      "alreadyOwned": false
    },
    "missionAvailable": true,
    "unlockedMission": {
      "missionId": 1004,
      "title": "정선 5일장 곤드레 퀴즈",
      "type": "QUIZ",
      "spotName": "정선 5일장",
      "cityName": "정선군",
      "rewardType": "ITEM",
      "rewardLabel": "황금감자 성장 아이템"
    }
  }
}
```

Notes:

- `missionAvailable`은 기존 클라이언트 호환을 위해 유지한다.
- `unlockedMission`은 방문 인증한 관광지와 연결된 활성 미션이 있고 사용자가 아직 완료하지 않은 경우에만 내려준다.
- `unlockedMission`이 `null`이면 프론트는 기존처럼 미션 CTA를 숨기거나 일반 미션 목록 진입으로 처리한다.

Error:

| HTTP Status | 조건 |
| --- | --- |
| 400 | 좌표 누락, 좌표 범위 오류, 방문 인증 반경 초과 |
| 401 | 인증 정보 없음 또는 잘못된 사용자 principal |
| 404 | 존재하지 않거나 비활성화된 감자 스팟 |
| 409 | 이미 방문 인증한 감자 스팟 |

### 4.3 내 다음 목표 관광지 조회

```http
GET /api/stamps/me/next-targets
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": [
    {
      "spotId": 101,
      "spotName": "정선 5일장",
      "cityName": "정선군",
      "category": "POTATO_MARKET",
      "address": "강원특별자치도 정선군...",
      "imageUrl": "https://..."
    }
  ]
}
```

처리 규칙:

- 사용자가 이미 스탬프를 획득한 시군은 제외한다.
- 미획득 시군을 스탬프 `displayOrder` 순으로 확인한다.
- 각 시군에서 `active=true`, `stampEnabled=true`인 관광지를 이름순으로 1곳 선택한다.
- 최대 3곳을 반환하며, 후보가 없거나 18개 시군 랠리를 완주한 경우 빈 배열을 반환한다.
- 인증 정보가 없거나 JWT 사용자를 찾을 수 없으면 `401 Unauthorized`를 반환한다.

### 4.4 랠리북 관광지 카탈로그 조회

강원 18개 시군 랠리북에 노출하도록 선별한 관광지와 공식 좌표를 조회한다.

```http
GET /api/stamps/rallybook-spots
Authorization: Bearer {accessToken}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": [
    {
      "spotId": 101,
      "spotName": "남이섬",
      "cityName": "춘천시",
      "category": "POTATO_TOUR",
      "latitude": 37.7962651,
      "longitude": 127.5254892,
      "address": "강원특별자치도 춘천시 남이섬길 1 남이섬",
      "imageUrl": "https://..."
    }
  ]
}
```

처리 규칙:

- `active=true`, `stampEnabled=true`, `rallybookFeatured=true`인 관광지만 반환한다.
- 시군 스탬프 `displayOrder`, 관광지 이름, 관광지 ID 순으로 정렬한다.
- 좌표는 `tourist_spots`에 저장된 한국관광공사 TourAPI 공식 위도·경도를 그대로 반환한다.
- 정선 5일장과 아리랑시장은 같은 공식 TourAPI 콘텐츠이므로 한 관광지로 반환한다.
- 인증 정보가 없거나 JWT 사용자를 찾을 수 없으면 `401 Unauthorized`를 반환한다.

### 4.5 보상 가능 여부 확인

```http
GET /api/stamps/rewards/check
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "acquiredCount": 12,
    "nextTargetCount": 18,
    "remainingCount": 6,
    "completed": false,
    "claimable": true,
    "claimableTargetCount": 6
  }
}
```

- 보상 기준은 6개, 12개, 18개다.
- `nextTargetCount`는 현재 획득 수보다 큰 다음 기준이며 기존 조회 의미를 유지한다.
- `claimableTargetCount`는 달성했지만 아직 수령하지 않은 가장 낮은 기준이다. 없으면 `null`이다.
- `claimable`은 `claimableTargetCount`가 있을 때 `true`다.
- 18개를 모두 획득해 `completed=true`여도 미수령 보상이 있으면 `claimable=true`일 수 있다.

### 4.6 스탬프 보상 수령

```http
POST /api/stamps/rewards/claim
```

Request:

```json
{
  "targetCount": 6
}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "targetCount": 6,
    "rewardHistoryId": 10,
    "userCouponId": 21,
    "couponName": "강원 감자 제휴점 3,000원 할인권",
    "expiresAt": "2026-08-16T00:00:00Z"
  }
}
```

처리 규칙:

- `targetCount`는 6, 12, 18 중 하나여야 한다.
- 획득 스탬프 수가 기준 이상일 때만 해당 보상을 수령할 수 있다.
- 달성한 각 기준 보상은 독립적으로 수령할 수 있으며, 낮은 기준부터 순서대로 수령할 필요는 없다.
- 한 사용자는 각 기준 보상을 한 번만 수령할 수 있다.
- 수령 성공 시 `RewardHistory`의 `sourceType`은 `STAMP`, `sourceId`는 기준 개수로 저장한다.
- 보상 이력과 사용자 쿠폰은 한 트랜잭션에서 생성하며, 동시 요청에서도 하나만 발급한다.
- 지원하지 않는 기준은 `400 Bad Request`, 조건 미달·이미 수령·동시 중복은 `409 Conflict`를 반환한다.
- 인증 정보가 없으면 `401 Unauthorized`, 정책 쿠폰이 누락되면 `500 Internal Server Error`를 반환한다.

MVP 쿠폰 정책:

| 기준 | 쿠폰 코드 | 쿠폰명 | 혜택 | 유효기간 |
| --- | --- | --- | --- | --- |
| 6개 | `CP_STAMP_6_LOCAL_3000` | 강원 감자 제휴점 3,000원 할인권 | 3,000원 | 발급 후 30일 |
| 12개 | `CP_STAMP_12_LOCAL_5000` | 강원 감자 제휴점 5,000원 할인권 | 5,000원 | 발급 후 30일 |
| 18개 | `CP_STAMP_18_COMPLETE_10000` | 강원 감자 랠리 완주 10,000원 할인권 | 10,000원 | 발급 후 30일 |

---

## 5. Potato API

### 5.1 전체 감자 목록 조회

```http
GET /api/potatoes
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "totalCount": 5,
    "items": [
      {
        "potatoId": 1,
        "code": "POTATO_HAJI_GANGNEUNG",
        "name": "하지감자",
        "region": "강릉시",
        "rarity": "COMMON",
        "description": "강릉 여행길에서 처음 만나기 좋은 기본 감자입니다.",
        "acquisitionHint": "강릉 감자 스팟 방문 인증",
        "imageUrl": null,
        "growthGoalDistance": 3000.0
      }
    ]
  }
}
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
  "data": {
    "totalCount": 5,
    "acquiredCount": 1,
    "items": [
      {
        "potatoId": 1,
        "code": "POTATO_HAJI_GANGNEUNG",
        "name": "하지감자",
        "region": "강릉시",
        "rarity": "COMMON",
        "description": "강릉 여행길에서 처음 만나기 좋은 기본 감자입니다.",
        "acquisitionHint": "강릉 감자 스팟 방문 인증",
        "imageUrl": null,
        "acquired": true,
        "acquiredAt": "2026-07-01T00:00:00Z",
        "level": 2,
        "growthDistance": 1500.0,
        "growthGoalDistance": 3000.0,
        "representative": true
      }
    ]
  }
}
```

### 5.3 감자 상세 조회

```http
GET /api/potatoes/{potatoId}
```

### 5.4 대표 감자 변경

```http
PATCH /api/potatoes/me/representative
```

Request:

```json
{
  "potatoId": 2
}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "potatoId": 2,
    "representative": true
  }
}
```

처리 규칙:

- 로그인한 사용자가 이미 획득한 감자만 대표 감자로 설정할 수 있다.
- 같은 감자를 다시 대표 감자로 설정해도 성공 응답을 반환한다.
- 성공 시 기존 대표 감자는 해제하고 요청한 감자만 대표 감자로 유지한다.
- 미획득 감자이거나 존재하지 않는 감자를 요청하면 `400 Bad Request`를 반환한다.
- 인증 정보가 없거나 사용자 정보가 유효하지 않으면 `401 Unauthorized`를 반환한다.

### 5.5 내 감자 성장 요약 조회

```http
GET /api/potatoes/me/growth-summary
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "todaySteps": 7842,
    "dailyStepGoal": 10000,
    "weeklyDistanceKm": 28.4,
    "monthlyDistanceKm": 116.8,
    "remainingDistanceKmForRepresentative": 1.8
  }
}
```

처리 규칙:

- 로그인 사용자의 감자 도감 홈 상단 `오늘의 감자걸음` 카드에 필요한 수치를 내려준다.
- 저장된 일일 활동 집계값을 우선 반환한다.
- 저장된 활동 집계가 없으면 오늘, 주간, 월간 통계를 `0`으로 반환한다.
- `todaySteps`는 당일 걸음 수, `dailyStepGoal`은 당일 목표 걸음 수다.
- `weeklyDistanceKm`, `monthlyDistanceKm`는 주간/월간 누적 이동거리다.
- `remainingDistanceKmForRepresentative`는 대표 감자의 다음 성장 목표까지 남은 거리다.
- 대표 감자가 없거나 성장 목표를 계산할 수 없으면 `remainingDistanceKmForRepresentative`는 `0.0`을 반환한다.
- 인증 정보가 없거나 사용자 정보가 유효하지 않으면 `401 Unauthorized`를 반환한다.

### 5.6 내 일일 걸음 수 동기화

```http
PUT /api/potatoes/me/activity/daily
```

Request:

```json
{
  "activityDate": "2026-07-21",
  "steps": 8420,
  "distanceMeters": 5894.0,
  "source": "HEALTH_CONNECT"
}
```

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "activityDate": "2026-07-21",
    "steps": 8420,
    "distanceMeters": 5894.0,
    "source": "HEALTH_CONNECT",
    "syncedAt": "2026-07-21T12:00:00Z",
    "growthResult": {
      "potatoId": 2,
      "potatoName": "곤드레감자",
      "previousLevel": 2,
      "currentLevel": 3,
      "leveledUp": true,
      "fullyGrown": false
    }
  }
}
```

처리 규칙:

- 로그인 사용자의 HealthKit 또는 Health Connect 일일 활동 집계를 서버에 저장한다.
- `activityDate`는 사용자 로컬 기준 날짜다.
- `source`는 `HEALTH_KIT`, `HEALTH_CONNECT`, `MANUAL`, `UNKNOWN` 중 하나다.
- 같은 사용자, 날짜, 출처 조합은 새 row를 만들지 않고 저장된 최대 걸음 수와 이동 거리를 유지한다.
- 최초 동기화는 요청 이동 거리 전체를, 재동기화는 저장된 최대 이동 거리보다 증가한 차이만 대표 감자 성장에 반영한다.
- 동일하거나 감소한 스냅샷은 성장량을 중복 지급하거나 회수하지 않는다.
- `growthResult`는 이번 요청의 양의 거리 증가분이 성장 전 대표 감자에 실제 반영된 경우에만 반환한다.
- 대표 감자가 없거나 이미 완전히 성장했거나 거리 증가분이 없으면 `growthResult`는 `null`이다.
- `leveledUp`은 현재 레벨이 이전 레벨보다 높을 때, `fullyGrown`은 이번 반영 후 레벨 5에 도달했을 때 `true`다.
- `steps`와 `distanceMeters`는 음수일 수 없다.
- `steps`가 비정상적으로 크거나 `distanceMeters`가 비정상적으로 크면 `400 Bad Request`를 반환한다.
- 인증 정보가 없거나 사용자 정보가 유효하지 않으면 `401 Unauthorized`를 반환한다.

### 5.7 감자 성장 처리

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
  "type": "QR_SCAN",
  "answer": null,
  "stepCount": null,
  "uploadKey": null,
  "qrCode": "gamjamubwatna://mission/qr/MISSION_SOKCHO_ONNURI_QR"
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
- `VISIT`: 사용자의 저장된 방문 인증 기록이 미션 장소와 일치하는지 검증한다.
- `VISIT_AND_STEP`: 요청의 `stepCount`를 신뢰하지 않고 서버에 동기화된 당일 HealthKit/Health Connect 걸음 수를 검증한다. 장소형 미션은 해당 장소의 방문 인증 기록도 함께 확인한다.
- `STAMP`: 미션 기간에 서버가 발급한 스탬프 수가 목표 이상인지 검증한다.
- `COLLECTION`: 미션 기간에 서버에 저장된 서로 다른 방문 시군 수가 목표 이상인지 검증한다.
- `PHOTO`: `uploadKey`가 로그인 사용자와 해당 미션에 발급된 key인지, 실제 저장 파일이 존재하는지 검증한다.
- `PHOTO_OCR`: `uploadKey`로 저장된 이미지를 읽고 OCR 판독 결과에 미션 정책 키워드가 포함되는지 검증한다.
- `QR_SCAN`: `qrCode` 존재 여부와 미션별 정책 QR payload의 정확한 일치 여부를 검증한다. 스캔값의 앞뒤 공백은 서버에서 제거한 뒤 비교한다.
- 인증 성공 시 서버가 중복 완료 여부를 확인하고 미션 완료와 보상 응답을 함께 처리한다.
- 검증 입력 없이 완료하는 `POST /api/missions/{missionId}/complete` endpoint는 제공하지 않는다.

QR 미션 payload 예시:

| 미션 코드 | QR payload |
| --- | --- |
| `MISSION_PYEONGCHANG_QR` | `gamjamubwatna://mission/qr/MISSION_PYEONGCHANG_QR` |
| `MISSION_SOKCHO_ONNURI_QR` | `gamjamubwatna://mission/qr/MISSION_SOKCHO_ONNURI_QR` |
| `MISSION_CHEORWON_GOSEOKJEONG_QR` | `gamjamubwatna://mission/qr/MISSION_CHEORWON_GOSEOKJEONG_QR` |
| `MISSION_HOENGSEONG_HANWOO_QR` | `gamjamubwatna://mission/qr/MISSION_HOENGSEONG_HANWOO_QR` |
| `MISSION_HWACHEON_SANCHEONEO_QR` | `gamjamubwatna://mission/qr/MISSION_HWACHEON_SANCHEONEO_QR` |

#### 6.3.1 반복/이벤트 미션 기간 계약

- 모든 기간 경계는 `Asia/Seoul`을 기준으로 계산한다.
- `DAILY` 미션은 당일 00:00 이상 다음 날 00:00 미만의 기록만 진행도와 인증에 사용한다.
- `WEEKLY` 미션은 월요일 00:00 이상 다음 월요일 00:00 미만의 기록만 진행도와 인증에 사용한다.
- `EVENT` 미션은 `startsAt` 이상 `endsAt` 미만일 때만 활성화한다. 기간이 설정되지 않았거나 현재 시각이 기간 밖이면 목록/상세 응답의 `active`는 `false`, `status`는 `LOCKED`이며 인증 요청은 거부한다.
- `JUMSOONI` 미션은 기존처럼 전체 기간에 한 번만 완료할 수 있다.
- 완료 기록은 `completionPeriod`, 보상 이력은 `sourcePeriod`를 함께 저장한다. 같은 기간에는 각각 한 번만 생성하고, 다음 기간에는 다시 완료와 보상을 받을 수 있다.
- 목록/상세 응답은 현재 기간의 `periodStartsAt`, `periodEndsAt`을 반환한다. 전체 기간 미션과 기간이 설정되지 않은 이벤트 미션은 두 값이 `null`이다.
- 반복 미션의 `progress`는 현재 기간 기록만 집계하며, 이전 기간의 완료와 진행 기록은 현재 응답에 포함하지 않는다.

### 6.4 미션 사진 업로드 키 발급

```http
POST /api/mission-uploads
Content-Type: multipart/form-data
```

Request:

| 이름 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| missionId | Long | Y | 사진/OCR 인증을 수행할 미션 ID |
| file | MultipartFile | Y | 카메라 촬영 또는 갤러리 선택 이미지 |

Response:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "uploadKey": "mission-uploads/1/1002/20260729T073000Z-9f1c2a3b.jpg",
    "fileName": "receipt.jpg",
    "contentType": "image/jpeg",
    "size": 245120,
    "expiresAt": "2026-07-29T08:30:00Z"
  }
}
```

Error:

| HTTP Status | 조건 |
| --- | --- |
| 400 | 파일 누락, 빈 파일, 이미지가 아닌 Content-Type, 최대 크기 초과 |
| 401 | 인증 정보 없음 또는 잘못된 사용자 principal |
| 404 | 존재하지 않는 미션 |

Notes:

- 로컬 개발 기본값은 서버 로컬 디스크(`local-runtime/mission-uploads`)에 파일을 저장하고 저장된 object key를 `uploadKey`로 반환한다.
- `uploadKey`는 이후 `POST /api/missions/{missionId}/verify`의 `uploadKey`로 전달한다.
- 운영 환경에서 S3 또는 호환 오브젝트 스토리지로 전환할 경우 storage 구현체와 환경변수를 별도 이슈에서 확장한다.
- 현재 로컬 OCR adapter는 운영 OCR 엔진 연결 전까지 파일 bytes에 포함된 텍스트를 판독 결과로 사용한다.
- 실제 OCR SaaS 또는 온디바이스 OCR 엔진 연결은 후속 이슈에서 진행한다.

Environment:

| 이름 | 기본값 | 설명 |
| --- | --- | --- |
| `MISSION_UPLOAD_STORAGE_TYPE` | `local` | 업로드 저장소 타입. 현재 구현 기준은 `local` |
| `MISSION_UPLOAD_LOCAL_DIR` | `local-runtime/mission-uploads` | 로컬 개발용 이미지 저장 루트 디렉터리 |

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
