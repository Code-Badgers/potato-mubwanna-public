# Issue #76 관광지 오디오 가이드 조회 API 검증

## 검증 범위

- `GET /api/audio-guides/spots/{spotId}` 응답 계약
- 한국관광공사 오디 `storySearchList` JSON 파싱
- 인코딩/디코딩 서비스 키의 이중 인코딩 방지
- 관광지명 정확 일치 및 한국어 음원 선택
- 최초 조회 시 저장 후 재조회에서 캐시 재사용
- 관광지/해설 미존재 404, 외부 연동 실패 503
- Flyway `V11__create_audio_guides.sql`과 JPA 스키마 및 복합 유니크 인덱스 일치

## 공식 명세 확인

- 데이터셋: [한국관광공사 관광지 오디오 가이드정보](https://www.data.go.kr/data/15101971/openapi.do)
- Base URL: `https://apis.data.go.kr/B551011/Odii`
- Operation: `GET /storySearchList`
- 필수값: `MobileOS`, `MobileApp`, `serviceKey`, `keyword`, `langCode`
- 사용 응답 필드: `stid`, `title`, `audioTitle`, `script`, `audioUrl`, `langCode`

## 자동 검증

### 오디오 기능 집중 테스트

```powershell
cd backend
.\gradlew.bat test --tests 'com.gamjamubwatna.audio.*'
```

결과: `BUILD SUCCESSFUL`

- 공식 Swagger 구조와 같은 JSON을 반환하는 로컬 HTTP 서버로 실제 `RestClient` 요청/파싱 검증
- 인코딩 서비스 키의 `%2F`, `%2B`가 `%252F`, `%252B`로 바뀌지 않는지 검증
- Spring 전체 컨텍스트에서 `HTTP 조회 -> 외부 응답 선택 -> DB 저장 -> 재조회` 검증
- 두 번째 조회에서는 오디 클라이언트가 다시 호출되지 않음을 검증

### 백엔드 전체 회귀 테스트

```powershell
cd backend
.\gradlew.bat test
```

결과: `BUILD SUCCESSFUL`, `134 tests`, 실패 `0`, 오류 `0`, 제외 `0`

### 변경 파일 검사

```powershell
git diff --check
```

결과: 공백 오류 없음. Windows 체크아웃의 CRLF 변환 안내만 출력됨.

## 실서비스 호출 상태

현재 실행 환경에는 `ODII_API_SERVICE_KEY`가 설정되어 있지 않아 공공데이터포털 실서비스 호출은 수행하지 않았다. 대신 공식 Swagger의 응답 구조를 사용한 로컬 HTTP 테스트로 요청 URI, 서비스 키 처리, JSON 역직렬화를 검증했다.

실서비스 확인 시 `backend/.env`에 승인된 키를 아래 이름으로만 추가한다. 키 값은 커밋하지 않는다.

```properties
ODII_API_SERVICE_KEY=<공공데이터포털에서 승인된 오디 서비스 키>
```

## 제외 범위

- Flutter 오디오 플레이어/관광지 상세 화면 연결
- 아직 구현되지 않은 방문 인증 성공 이벤트와 스탬프 이력 결합
- 원문 대본을 점순이 말투로 자동 변환하는 기능
