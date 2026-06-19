# AGENTS.md

이 저장소에서 Codex 에이전트는 작업 전에 반드시 `agents_docs/AGENTS.md`를 먼저 읽고 따른다. 이 파일은 루트 진입점이며, 세부 규칙은 `agents_docs/` 문서를 기준으로 한다.

## Required Reading

1. `agents_docs/AGENTS.md`
2. `agents_docs/CODEX_WORKFLOW.md`
3. 작업 유형에 맞는 설계/기술 문서

## Non-Negotiables

- 작업 전 `git status --short --branch`를 확인한다.
- 작업 전 GitHub Issue 번호와 작업 브랜치를 확인한다. 이슈가 없으면 먼저 이슈를 만들고, 브랜치명은 `<type>/<issue-number>-<clear-task-name>` 형식을 따른다.
- 기존 사용자 변경사항을 되돌리지 않는다.
- `main`에 직접 push하지 않는다.
- GitHub Issue 범위 밖 파일은 수정하지 않는다.
- 같은 파일을 다른 사람 또는 다른 에이전트가 작업 중이면 즉시 멈추고 조율한다.
- API 계약 변경은 구현 전에 `agents_docs/07_api_specification.md` 또는 작업 이슈에 request/response를 먼저 명시한다.
- 스테이징 전 `git diff`와 `git status --short`를 확인한다.
- 커밋 메시지는 `agents_docs/AGENTS.md`와 `agents_docs/NAMING_CONVENTIONS.md`의 컨벤션을 따른다.
- 작업 종료 시 `agents_docs/HANDOFF_TEMPLATE.md` 형식으로 변경, 검증, 리스크를 보고한다.

## Notion

Notion 연동이 준비된 경우 `agents_docs/NOTION_SYNC_GUIDE.md`를 따른다. 연동 전에는 동일한 항목을 수동으로 작업 페이지에 기록한다.
