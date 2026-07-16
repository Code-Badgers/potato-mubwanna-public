# Issue #81 연관 관광지 추천 API 검증

## 검증 범위

- `GET /api/spots/{spotId}/recommendations` 응답 계약
- 한국관광공사 연관 관광지 API `searchKeyword1` 요청 및 최상위 `response` 래퍼 JSON 파싱
- 인코딩/디코딩 서비스 키의 이중 인코딩 방지
- 강원특별자치도 18개 시군구 코드 변환
- 기준 관광지명과 시군구 정확 일치, 외부 추천 순위 정렬 및 중복 제거
- 로컬 활성 관광지 매핑, 현재 관광지 제외, 최대 3개 반환
- 관광지/지원 시군구 미존재 404, 외부 연동 실패 503

## 공식 명세 확인

- 데이터셋: [한국관광공사 연관 관광지 정보](https://www.data.go.kr/data/15128560/openapi.do)
- 서비스 URL 변경 공지: [TourAPI 서비스 도메인 변경 안내](https://www.data.go.kr/bbs/ntc/selectNotice.do?originId=NOTICE_0000000004109)
- Base URL: `https://apis.data.go.kr/B551011/TarRlteTarService1`
- Operation: `GET /searchKeyword1`
- 필수값: `serviceKey`, `pageNo`, `numOfRows`, `MobileOS`, `MobileApp`, `baseYm`, `areaCd`, `signguCd`, `keyword`
- 사용 응답 필드: `tAtsNm`, `signguCd`, `rlteTatsNm`, `rlteRank`
- 기준 연월: `202504` (환경 변수로 변경 가능)

## 사전 차단 이슈

작업 시작 시 `main`의 Flyway 마이그레이션 버전 충돌 때문에 Spring 통합 테스트를 실행할 수 없었다. Issue #82, PR #83에서 충돌을 복구하고 병합한 뒤 Issue #81 구현과 전체 검증을 진행했다.

## 자동 검증

### 연관 관광지 기능 집중 테스트

```powershell
cd backend
.\gradlew.bat test --tests '*SpotRecommendation*' --tests '*RelatedTourismApiClientTest' --tests '*GangwonSignguCodeResolverTest'
```

결과: `BUILD SUCCESSFUL`

- 공식 응답의 최상위 `response` 래퍼를 반환하는 로컬 HTTP 서버로 실제 `RestClient` 요청/파싱 검증
- 인코딩 서비스 키가 이중 인코딩되지 않는지 검증
- 단일 `item` 객체 응답과 API 오류 응답 처리 검증
- 외부 순위 정렬, 중복 제거, 활성 관광지 매핑, 최대 3개 제한 검증
- Spring 전체 컨텍스트에서 HTTP 요청부터 외부 응답 및 DB 조회까지 통합 검증

### 백엔드 전체 회귀 테스트

```powershell
cd backend
.\gradlew.bat test
```

결과: `BUILD SUCCESSFUL`, `157 tests`, 실패 `0`, 오류 `0`, 제외 `0`

리뷰 반영 후 첫 전체 테스트 재실행은 앞서 실행 중이던 Gradle 프로세스가 `build/test-results/test/binary/output.bin`을 잠가 정리 단계에서 실패했다. `.\gradlew.bat --stop`으로 잔류 데몬을 종료한 뒤 같은 전체 테스트를 다시 실행해 정상 통과했다.

### 백엔드 빌드

```powershell
cd backend
.\gradlew.bat build
```

결과: `BUILD SUCCESSFUL`

### 변경 파일 검사

```powershell
git diff --check
```

결과: 공백 오류 없음. Windows 체크아웃의 CRLF 변환 안내만 출력됨.

## 실서비스 호출 상태

현재 실행 환경에는 `RELATED_TOURISM_API_SERVICE_KEY`가 설정되어 있지 않아 공공데이터포털 실서비스 호출은 수행하지 않았다. 대신 공식 응답 구조를 사용하는 로컬 HTTP 테스트로 요청 URI, 서비스 키 처리, JSON 역직렬화를 검증했다.

실서비스 확인 시 `backend/.env`에 승인된 키를 아래 이름으로만 추가한다. 키 값은 커밋하지 않는다.

```properties
RELATED_TOURISM_API_SERVICE_KEY=<공공데이터포털에서 승인된 연관 관광지 API 키>
```

## 동작 제약과 남은 리스크

- 외부 추천 결과 중 로컬 DB의 활성 관광지명과 정확히 일치하는 항목만 반환한다. 외부에만 존재하는 관광지는 제외된다.
- 데이터 제공 기준 연월이 갱신되면 `RELATED_TOURISM_API_BASE_YM`도 함께 변경해야 한다.
- 방문 이력이나 미완료 스탬프를 이용한 개인화는 이번 이슈 범위에 포함하지 않았다.
- Flutter 관광지 상세 화면 연결과 방문 인증 결과 연계는 후속 작업이다.

## 변경 파일

- `backend/src/main/java/com/gamjamubwatna/spot/api`: 추천 API 컨트롤러와 응답 계약
- `backend/src/main/java/com/gamjamubwatna/spot/application`: 추천 매핑 서비스, 시군구 코드 변환, 예외
- `backend/src/main/java/com/gamjamubwatna/spot/infrastructure`: 외부 연관 관광지 API 클라이언트
- `backend/src/main/java/com/gamjamubwatna/spot/domain/TouristSpotRepository.java`: 활성 관광지명 일괄 조회
- `backend/src/main/resources/application.yml`, `backend/.env.example`: 외부 API 설정
- `backend/src/test/java/com/gamjamubwatna/spot`: 단위, 컨트롤러, 외부 클라이언트, 통합 테스트

## 제외 범위

- Flutter 화면과 추천 API 연동
- 사용자별 스탬프 완성도 기반 추천
- 외부 관광지의 추가 수집 또는 DB 저장
