# Codex Workflow

이 문서는 두 명 이상이 Codex로 같은 저장소를 작업할 때 따르는 운영 절차다. 세부 구현 규칙은 `AGENTS.md`, 기술 문서, 가까운 코드 패턴을 우선한다.

## 1. Start

1. `agents_docs/AGENTS.md`, 이 문서, 관련 기능 문서를 읽는다.
2. `git status --short --branch`로 브랜치와 변경사항을 확인한다.
3. GitHub Issue 또는 Notion 작업 페이지에서 목표, 범위, 제외 범위를 확인한다.
4. 관련 코드, 테스트, API 계약, 화면 문서를 먼저 읽는다.
5. `main`에서 직접 작업하지 않고 `<type>/<issue-number>-<clear-task-name>` 브랜치에서 작업한다.

## 2. Scope Control

- 한 작업은 하나의 Issue 범위로 제한한다.
- 같은 파일을 다른 사람이 작업 중이면 변경 전에 중단하고 조율한다.
- 프론트와 백엔드를 모두 크게 바꾸는 경우 가능한 한 커밋을 분리한다.
- API 계약 변경은 구현 전에 `agents_docs/07_api_specification.md` 또는 작업 페이지에 먼저 명시한다.
- 비밀값, 실제 API 키, 개인 토큰은 코드와 Notion에 평문으로 남기지 않는다.

## 3. Implementation

- 기존 패키지 구조와 네이밍을 따른다.
- 불필요한 리팩터, 전체 포맷 변경, 메타데이터 변경은 피한다.
- 예외, 인증, DB 제약, 순서 의존 로직처럼 의도가 숨은 부분에는 짧게 이유 주석을 남긴다.
- 화면 작업은 로딩, 빈 상태, 에러, disabled 상태를 함께 고려한다.
- 백엔드 API 작업은 request/response DTO, validation, 테스트, 문서를 함께 맞춘다.

## 4. Validation

가장 가까운 검증부터 실행한다.

```text
Frontend:
flutter analyze
flutter test

Backend:
.\gradlew.bat test
.\gradlew.bat build
```

도구가 없거나 환경이 부족해 실행하지 못하면, 실패 원인과 남은 리스크를 작업 요약에 남긴다.

## 5. Commit And Push

1. `git diff`로 변경을 확인한다.
2. `git status --short`로 의도한 파일만 변경되었는지 확인한다.
3. 관련 파일만 스테이징한다.
4. 커밋 메시지는 `NAMING_CONVENTIONS.md`의 형식을 따른다.
5. 현재 브랜치가 `main`이 아닌지 확인한다.
6. 검증이 실패한 상태에서는 push하지 않는다.
7. push 후 PR을 열고 `.github/pull_request_template.md`를 채운다.

## 6. Handoff

작업이 끝나거나 중단될 때는 다음 항목을 남긴다.

- 변경한 핵심 파일
- 실행한 검증 명령과 결과
- 생성한 산출물 위치
- 남은 리스크
- 다음 작업자가 이어서 할 일

자세한 형식은 `agents_docs/HANDOFF_TEMPLATE.md`를 사용한다.
