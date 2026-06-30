# 랠리북 진행률과 다음 보상 연동 설계

## 목표

로그인한 사용자가 강원특별자치도 18개 시군의 스탬프 획득 현황과 다음 보상까지 남은 개수를 실제 API 데이터로 확인할 수 있게 한다. 현재 Flutter 랠리북 화면에 하드코딩된 `8 / 18` 진행률과 `10개` 보상 기준을 제거한다.

## 결정한 접근

### 채택: 조회 API 분리

- `GET /stamps/me`: 18개 시군 스탬프와 사용자 획득 상태를 반환한다.
- `GET /stamps/rewards/check`: 현재 획득 수와 다음 보상 기준을 반환한다.
- Flutter는 두 API를 하나의 랠리북 화면 모델로 조합한다.

이 방식은 최신 `agents_docs/07_api_specification.md`와 기존 `ApiPaths` 계약을 그대로 사용한다. 향후 보상 정책이 바뀌어도 스탬프 목록 응답을 변경하지 않아도 된다.

### 검토했지만 채택하지 않은 접근

1. 단일 `/stamps/me` 응답에 다음 보상까지 포함
   - 네트워크 호출은 하나지만 기존 API 책임이 섞이고 보상 정책 변경이 스탬프 목록 계약에 영향을 준다.
2. Flutter 정적 데이터를 유지하고 백엔드만 준비
   - 사용자에게 보이는 값이 계속 실제 데이터와 다르므로 이번 작업의 목표를 충족하지 못한다.

## 범위

### 포함

- 18개 시군 스탬프 기준 데이터
- 사용자별 스탬프 획득 관계
- 내 스탬프 목록과 진행률 조회
- 다음 보상 기준 조회
- Flutter 랠리북의 API 연동
- 인증 상태 전환, 로딩, 오류, 재시도 처리
- 백엔드와 Flutter 자동화 테스트

### 제외

- `POST /stamps/verify` 방문 인증
- 방문 성공 후 실제 스탬프 지급
- 보상 수령과 쿠폰 발급
- 팀 B의 지도, 감자, 미션 파일
- 외부 관광 API, 오디오 가이드, 추천 동선

## 데이터 모델

### `stamps`

- `stamp_id`: PK
- `city_name`: 시군명, 유일값
- `stamp_name`: 화면에 표시할 지역 스탬프 이름
- `stamp_image`: 선택값
- `display_order`: 18개 시군 정렬 순서, 유일값
- `created_at`, `updated_at`

Flyway migration에서 18개 시군 데이터를 고정 순서로 삽입한다. 운영에서 관광지 데이터를 다시 수집해도 랠리북 기준 목록은 사라지지 않는다.

### `user_stamps`

- `user_stamp_id`: PK
- `user_id`: `users` FK
- `stamp_id`: `stamps` FK
- `tourist_spot_id`: `tourist_spots` FK
- `acquired_at`
- `UNIQUE(user_id, stamp_id)`: 같은 사용자의 동일 시군 스탬프 중복 지급 방지

이번 작업은 조회만 구현하므로 `user_stamps` 생성 로직은 추가하지 않는다. Team B 방문 인증이 구현될 때 동일 테이블과 유일 제약을 사용한다.

## API 계약

애플리케이션 컨트롤러 경로는 기존 코드 규칙에 따라 `/stamps/...`를 사용한다. 배포 환경의 `/api` 접두사는 프록시 또는 기본 URL에서 처리한다.

### `GET /stamps/me`

성공 응답:

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "totalCount": 18,
    "acquiredCount": 1,
    "stamps": [
      {
        "stampId": 1,
        "cityName": "강릉시",
        "stampName": "하지감자",
        "stampImage": null,
        "acquired": true,
        "acquiredAt": "2026-06-30T00:00:00Z"
      }
    ]
  }
}
```

획득하지 않은 스탬프는 `acquired=false`, `acquiredAt=null`로 반환한다. 사용자 획득 데이터가 없어도 18개 기준 목록과 `acquiredCount=0`을 반환한다.

### `GET /stamps/rewards/check`

보상 기준은 `agents_docs/03_information_architecture.md`의 6개, 12개, 18개를 사용한다.

```json
{
  "success": true,
  "message": "요청이 성공했습니다.",
  "data": {
    "acquiredCount": 8,
    "nextTargetCount": 12,
    "remainingCount": 4,
    "completed": false
  }
}
```

- 0~5개: 다음 기준 6개
- 6~11개: 다음 기준 12개
- 12~17개: 다음 기준 18개
- 18개: `nextTargetCount=null`, `remainingCount=0`, `completed=true`

두 API는 인증이 필요하다. 누락되거나 유효하지 않은 토큰은 기존 Security Filter Chain이 공통 401 응답으로 처리한다.

## 백엔드 구조

- `Stamp`, `UserStamp`: JPA 도메인 엔티티
- `StampRepository`, `UserStampRepository`: 정렬된 기준 목록과 사용자 획득 데이터 조회
- `StampQueryService`: 목록 조합, 획득 수 계산, 다음 보상 정책 계산
- `StampController`: 인증 사용자 ID를 검증하고 공통 `AuthApiResponse`로 반환
- 응답 DTO는 목록과 보상 상태를 분리한다.

보상 기준은 별도 설정 시스템을 만들지 않고 서비스의 불변 목록 `6, 12, 18`로 둔다. 이번 MVP 범위에서 관리자 정책 편집 기능은 필요하지 않다.

## Flutter 구조

- `RallybookStamp`, `RallybookProgress`, `NextStampReward`: 불변 도메인 모델
- `StampRepository`: Dio를 통해 두 조회 API 호출 및 JSON 파싱
- `stampBookProvider`: `authControllerProvider`의 인증 상태를 구독하는 `autoDispose` FutureProvider
- `StampBookScreen`: 정적 목록을 제거하고 Provider의 loading, data, error 상태를 렌더링

로그아웃 상태에서는 API를 호출하지 않는다. 사용자 A 로그인, 로그아웃, 사용자 B 로그인 순서에서 Provider가 새 데이터를 요청해 이전 랠리북이 남지 않게 한다.

기존 화면의 색상, 그리드, 진행률 카드, 다음 보상 카드 배치는 유지한다. 완료 상태에서는 다음 보상 카드에 `18개 시군 랠리를 모두 완주했어요.`를 표시한다.

## 오류 처리

- 401: 기존 인증 복구 흐름에 맡기고 화면에는 일반 오류 상태를 표시한다.
- 네트워크 또는 파싱 오류: 랠리북 본문에 오류 문구와 `다시 시도` 버튼을 표시한다.
- 빈 사용자 획득 데이터: 오류가 아니며 0/18 정상 상태로 표시한다.
- 기준 스탬프가 18개가 아닌 경우: API가 실제 `totalCount`를 반환하되 백엔드 통합 테스트에서 migration 기준 18개를 고정한다.

## 테스트

### 백엔드

- Flyway migration 후 18개 스탬프가 존재한다.
- 획득 데이터가 없는 사용자는 0/18과 다음 기준 6을 받는다.
- 일부 획득 사용자는 정렬된 18개 목록, 획득 시각, 다음 기준을 받는다.
- 6, 12, 18 경계에서 다음 보상 계산이 정확하다.
- 인증된 컨트롤러 요청은 공통 응답 형식을 사용한다.
- 인증되지 않은 요청은 401이다.

### Flutter

- API 응답을 도메인 모델로 파싱한다.
- 랠리북 화면이 진행률, 18개 시군, 다음 보상을 실제 데이터로 표시한다.
- 로딩, 오류, 재시도, 완주 상태를 표시한다.
- 로그아웃 상태에서는 호출하지 않는다.
- 사용자 A → 로그아웃 → 사용자 B 전환 시 다시 조회한다.

## 성공 기준

- 로그인한 사용자가 실제 API 기반 랠리북을 확인한다.
- 18개 시군과 6·12·18 보상 기준이 문서, API, 화면에서 일치한다.
- 팀 B 파일을 수정하지 않는다.
- 백엔드 전체 테스트, Flutter 분석, 랠리북 집중 테스트, Debug APK 빌드를 통과한다.
