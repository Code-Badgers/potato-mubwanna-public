# Issue #86 연관 관광지 Decoding 인증키 인코딩 검증

## 검증 범위

- 공공데이터포털에서 제공하는 Decoding 인증키의 예약 문자를 쿼리 컴포넌트로 안전하게 인코딩
- 포털의 Encoding 인증키는 `%`를 다시 인코딩하지 않는 기존 동작 유지
- 연관 관광지 기능 집중 테스트, 백엔드 전체 테스트와 빌드 확인
- 승인된 Decoding 키로 실제 공공데이터 API 및 Spring 추천 엔드포인트 호출

## 원인과 수정

기존 구현은 Decoding 키에도 일반 쿼리 파라미터 인코딩인 `UriUtils.encodeQueryParam`을 사용했다. 이 메서드는 `+`와 `/`를 그대로 남기므로 서비스 키가 서버에서 다른 값으로 해석돼 인증 오류가 발생했다.

이미 `%`가 포함된 Encoding 키는 그대로 유지하고, Decoding 키만 `UriUtils.encode`로 URI 컴포넌트 전체를 인코딩하도록 변경했다. 따라서 예시 키의 `+`, `/`, `=`는 각각 `%2B`, `%2F`, `%3D`가 된다.

## 테스트 우선 확인

수정 전에 Decoding 키 모양의 더미 값 `decoded+service/key==`를 사용한 회귀 테스트를 추가했다.

```powershell
cd backend
.\gradlew.bat test --tests '*RelatedTourismApiClientTest'
```

수정 전 결과: `5 tests completed, 1 failed`

수정 후 결과: `BUILD SUCCESSFUL`

실제 키는 테스트 코드나 저장소 파일에 사용하지 않았다.

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

결과: `158 tests`, 실패 `0`, 오류 `0`, 제외 `0`

### 백엔드 빌드

```powershell
cd backend
.\gradlew.bat build
```

결과: `BUILD SUCCESSFUL`

## 실제 런타임 검증

- 승인된 공공데이터포털 Decoding 키를 실행 프로세스 환경 변수로만 전달했다.
- 동일한 키를 URI 컴포넌트로 인코딩해 외부 `searchKeyword1`을 직접 호출한 결과 `resultCode=0000`, 50건을 반환했다.
- 로컬 PostgreSQL에 런타임 전용 `뮤지엄산`과 외부 추천 결과에 포함된 관광지 한 곳을 준비했다.
- 같은 Decoding 키로 Spring Boot를 실행하고 `GET /api/spots/2/recommendations`를 호출했다.
- 결과: HTTP `200`, `success=true`, 로컬 관광지와 매핑된 추천 `1건` 반환.
- 키 값은 코드, 문서, 환경 파일, Git 이력에 저장하지 않았다.

## 확인된 별도 리스크

외부 추천 결과가 없을 때 공급자가 `items`를 객체가 아닌 빈 문자열로 반환하는 경우가 있다. 현재 클라이언트는 이 응답을 역직렬화하지 못해 503으로 변환한다. 이는 인증키 인코딩과 독립적인 응답 호환성 문제이므로 이번 이슈 범위에는 포함하지 않았다.

## 변경 파일

- `backend/src/main/java/com/gamjamubwatna/spot/infrastructure/RelatedTourismApiClient.java`
- `backend/src/test/java/com/gamjamubwatna/spot/infrastructure/RelatedTourismApiClientTest.java`
- `artifacts/validation/issue-86/VALIDATION.md`

## 제외 범위

- 다른 공공데이터 클라이언트의 서비스 키 처리 변경
- 연관 관광지 API 응답 모델과 추천 매핑 규칙 변경
- 인증키 저장 또는 배포 환경 구성 변경
