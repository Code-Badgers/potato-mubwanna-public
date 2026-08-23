# Issue #389 관리자 공지 관리 API 검증

## 작업 요약

- 이슈: https://github.com/Code-Badgers/potato-mubwanna/issues/389
- 브랜치: `feat/389-admin-notice-api`
- 담당 영역: 관리자 공지 전체 목록·작성·수정·게시 상태 변경 API
- 제외 범위: 영구 삭제, 예약 게시, 관리자 화면, 다른 콘텐츠 관리
- 목표: Flyway seed 수정 없이 운영 공지를 안전하게 관리한다.

## 변경 파일

- `AdminNoticeController`: `/admin/notices` 관리자 endpoint 4개 추가
- 관리자 공지 request/response DTO: 입력 검증과 운영 상태 응답 정의
- `AdminNoticeService`: 전체 조회, 생성, 제목·내용 수정, 게시 상태 변경 처리
- `Notice`: 제목·내용 불변식, 내용 수정, idempotent 게시 전환과 timestamp 정책 추가
- `NoticeRepository`: 관리자용 `updatedAt DESC, id DESC` 목록 조회 추가
- `agents_docs/07_api_specification.md`: request/response 및 상태 전환 계약 반영
- notice 도메인·서비스·controller·통합 테스트 추가

## API 계약

- `GET /api/admin/notices`: 게시 여부와 관계없이 전체 조회
- `POST /api/admin/notices`: 공지 생성, 201 반환
- `PUT /api/admin/notices/{noticeId}`: 제목·내용 전체 교체
- `PATCH /api/admin/notices/{noticeId}/publication`: 게시·숨김 전환
- 공통: ADMIN 권한 필수, 입력 오류 400, 존재하지 않는 공지 404

## 진행 중 발생한 문제와 해결

1. 최초 국소 테스트에서 `AdminNoticeService`의 운영 생성자와 테스트용 생성자가 함께 있어 Spring이 생성자를 자동 선택하지 못했다.
2. 운영 생성자에 `@Autowired`를 명시해 Spring wiring과 고정 Clock 단위 테스트를 함께 유지했다.
3. 최초 controller slice 테스트는 실제 `SecurityConfig`를 포함하지 않아 기본 CSRF 규칙으로 쓰기 요청이 403이었고, 일반 USER의 관리자 GET은 200이었다.
4. `SecurityConfig`와 `JwtAuthenticationFilter`를 명시적으로 import해 실제 운영 권한·CSRF 정책으로 검증했다.

## 검증

- 최초 공지·관리자 접근 국소 테스트: 21개 중 11개 실패. 위 테스트 구성 문제를 수정했다.
- 공지·관리자 접근 국소 테스트 재실행: 통과
- `AdminNoticeIntegrationTest`: 게시·숨김 변경이 공개 공지 목록에 즉시 반영됨을 H2/Flyway 환경에서 확인
- `.\gradlew.bat test`: 447개 통과, 실패·오류·건너뜀 0개
- `.\gradlew.bat build`: 통과
- `git diff --check`: 공백 오류 없음. Windows LF/CRLF 안내만 출력됨.

## DB / 배포 영향

- 새 migration 없음. 기존 `notices` schema를 사용한다.
- 예약 게시를 지원하지 않으며 초안 생성 시 내부 `publishedAt`은 생성 시각으로 초기화한다.
- 숨김→게시 시 `publishedAt`이 현재 시각으로 바뀌고, 같은 상태 재요청은 timestamp를 유지한다.

## 남은 리스크

- 실제 관리자 로그인이 숫자 `ADMIN_USER_IDS`와 연결되려면 선행 PR #388이 먼저 병합되어야 한다.
- 이번 이슈에는 관리 화면이 없으므로 API 호출은 Swagger 또는 후속 Flutter 관리자 화면에서 사용한다.
- 영구 삭제와 예약 게시는 의도적으로 제외했다.

## 다음 작업

- PR #388 병합 후 이 PR을 최신 main에 맞춰 확인한다.
- Flutter 앱에 관리자 전용 공지 목록·작성·수정·게시 전환 화면을 추가한다.
