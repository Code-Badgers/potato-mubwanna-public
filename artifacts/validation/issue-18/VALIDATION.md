# Issue 18 Validation

## 작업 목표

- 두 명 이상이 에이전트 코딩을 병행할 때 Issue, 브랜치, API 계약, 공유 파일, 검증, 인계 규칙을 놓치지 않도록 문서와 GitHub 템플릿을 보강한다.

## 진행 과정

- GitHub Issue #18을 생성했다.
- 작업 브랜치를 `docs/18-agent-collaboration-guardrails`로 맞췄다.
- 루트 `AGENTS.md`, `agents_docs/AGENTS.md`, `agents_docs/CODEX_WORKFLOW.md`, `agents_docs/11_team_work_split.md`, `agents_docs/HANDOFF_TEMPLATE.md`에 다중 에이전트 협업 가드레일을 추가했다.
- Issue 템플릿과 PR 템플릿에 담당자, 브랜치, 제외 범위, 공유 위험 파일, API 계약, Windows 호환 파일명, 비밀값 확인 항목을 추가했다.

## 발생한 문제와 해결

- 작업 시작 시 Issue 번호 없이 임시 브랜치를 먼저 만들었다.
- 사용자의 지시에 따라 GitHub Issue #18을 생성한 뒤 브랜치를 `docs/18-agent-collaboration-guardrails`로 변경했다.
- Gemini Code Assist 리뷰에서 bug/feature 템플릿의 비밀값 체크 누락, PR 템플릿의 검증 산출물 업로드 문구, handoff 템플릿의 외부 API 항목 누락을 지적했다.
- 리뷰 피드백을 확인한 뒤 네 항목 모두 현재 문서 정책과 충돌하지 않는 작은 정합성 수정으로 판단해 반영했다.

## 변경 파일 요약

- `AGENTS.md`: 루트 진입점의 필수 협업 규칙 보강.
- `agents_docs/AGENTS.md`: 다중 에이전트 협업 절대 규칙 추가.
- `agents_docs/CODEX_WORKFLOW.md`: 시작, 범위 제어, PR, handoff 절차 보강.
- `agents_docs/11_team_work_split.md`: 작업 선점, 공유 위험 파일, API 계약 규칙 보강.
- `agents_docs/HANDOFF_TEMPLATE.md`: 이어받기와 계약 변경 기록 항목 추가.
- `.github/ISSUE_TEMPLATE/*.md`: Issue 작성 시 협업 가드레일 확인 항목 추가.
- `.github/pull_request_template.md`: PR 제출 전 협업/계약/검증 체크리스트 보강.
- Gemini Code Assist 리뷰 반영: bug/feature 템플릿 비밀값 체크 추가, PR 템플릿 업로드 문구 조정, handoff 외부 API 항목 추가.
- `artifacts/validation/issue-18/VALIDATION.md`: 이 검증 기록.

## 실행한 명령

```powershell
git status --short --branch
git remote get-url origin
git branch -m docs/18-agent-collaboration-guardrails
git diff -- AGENTS.md agents_docs/AGENTS.md agents_docs/CODEX_WORKFLOW.md agents_docs/11_team_work_split.md agents_docs/HANDOFF_TEMPLATE.md .github/ISSUE_TEMPLATE/task-template.md .github/ISSUE_TEMPLATE/feature-template.md .github/ISSUE_TEMPLATE/bug-template.md .github/pull_request_template.md
git status --short
rg -n "TBD|TODO|FIXME|<issue-number>|공유 위험 파일|Windows 금지|API 계약|Issue가 없으면|같은 파일" AGENTS.md agents_docs .github
gh pr view 19 --json comments,reviews,files
gh api repos/Code-Badgers/potato-mubwanna/pulls/19/comments --paginate
```

## 결과

- 변경 파일은 협업 문서, GitHub 템플릿, 검증 산출물로 제한됐다.
- Markdown 내 미완성 placeholder나 TODO는 새로 추가하지 않았다.
- 코드 변경이 없으므로 프론트엔드/백엔드 테스트와 빌드는 실행하지 않았다.

## 남은 리스크

- 이번 작업은 문서와 템플릿 기반 가드레일이며, CI나 Git hook으로 기계적으로 차단하지는 않는다.
- 자동 검사는 별도 이슈에서 Windows 금지 파일명, PR 템플릿 체크, 문서 삭제 등을 대상으로 추가할 수 있다.

## 후속 작업

- 필요하면 별도 이슈로 GitHub Actions 기반 협업 규칙 자동 검사를 추가한다.
