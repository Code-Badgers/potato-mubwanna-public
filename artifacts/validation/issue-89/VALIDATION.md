# Issue #89 연관 관광지 빈 문자열 items 응답 검증

## 검증 범위

- 외부 연관 관광지 API가 조회 결과 없음 상태를 `items: ""`로 반환할 때 빈 목록으로 처리
- 배열 및 단일 객체 형태의 기존 응답 호환성 유지
- 비어 있지 않은 임의 문자열은 잘못된 외부 응답으로 계속 거부
- 실제 외부 빈 결과를 통한 Spring 추천 엔드포인트 확인

## 원인과 수정

외부 API는 추천 결과가 없을 때 `response.body.items`를 객체가 아닌 빈 문자열로 반환할 수 있다. 기존 응답 모델은 `RelatedTourismItems` 객체만 허용해 Jackson 역직렬화 단계에서 `InvalidFormatException`이 발생했고, 이후의 빈 결과 검사까지 도달하지 못한 채 503으로 변환됐다.

`RelatedTourismItems`에 문자열 전용 Jackson 생성자를 추가했다. 빈 문자열과 공백 문자열만 빈 목록으로 변환하며, 비어 있지 않은 문자열은 잘못된 응답으로 거부한다. 전역 Jackson 설정과 공개 API 응답 계약은 변경하지 않았다.

## 테스트 우선 확인

```powershell
cd backend
.\gradlew.bat test --tests '*RelatedTourismApiClientTest'
```

수정 전 결과: `6 tests completed, 1 failed`

- `returnsEmptyListWhenGatewayRepresentsItemsAsEmptyString`에서 실제와 같은 `InvalidFormatException` 재현
- 비어 있지 않은 문자열을 거부하는 테스트는 기존 오류 처리 경로로 통과

수정 후 결과: `BUILD SUCCESSFUL`

## 자동 검증

### 연관 관광지 기능 집중 테스트

```powershell
cd backend
.\gradlew.bat test `
  --tests '*SpotRecommendation*' `
  --tests '*RelatedTourismApiClientTest' `
  --tests '*GangwonSignguCodeResolverTest'
```

결과: `BUILD SUCCESSFUL`

### 백엔드 전체 회귀 테스트

```powershell
cd backend
.\gradlew.bat test
```

결과: `159 tests`, 실패 `0`, 오류 `0`, 제외 `0`

### 백엔드 빌드

```powershell
cd backend
.\gradlew.bat build
```

결과: `BUILD SUCCESSFUL`

## 실제 런타임 검증

- 승인된 공공데이터포털 Encoding 키를 Spring Boot 실행 프로세스에만 전달했다.
- 외부 API가 `정선 5일장` 조회에 실제로 `items: ""`를 반환하는 조건을 사용했다.
- 수정 전 동일 요청은 HTTP 503을 반환했다.
- 수정 후 `GET /api/spots/1/recommendations` 결과는 HTTP `200`, `success=true`, 추천 `0건`이었다.
- 실제 인증키는 코드, 문서, 환경 파일, Git 이력에 저장하지 않았다.

## 변경 파일

- `backend/src/main/java/com/gamjamubwatna/spot/infrastructure/RelatedTourismApiClient.java`
- `backend/src/test/java/com/gamjamubwatna/spot/infrastructure/RelatedTourismApiClientTest.java`
- `artifacts/validation/issue-89/VALIDATION.md`

## 제외 범위

- 서비스 키 인코딩 처리 변경
- 공개 추천 API Request/Response 스키마 변경
- 다른 외부 API 클라이언트의 Jackson 응답 정책 변경
