# Issue 112 Validation

## 작업 목표

- 종료된 Gemini Code Assist Consumer와 Semgrep 정적 분석 워크플로를 대체한다.
- 별도 API 키 없이 GitHub Models가 PR diff를 검토하고 결과 댓글을 게시하도록 한다.

## 변경 파일

- `.github/workflows/pr-ai-review.yml`
- `.github/prompts/pr-review.prompt.yml`
- `.github/scripts/ai-review-core.mjs`
- `.github/scripts/prepare-ai-review.mjs`
- `.github/scripts/publish-ai-review.mjs`
- `.github/scripts/ai-review-core.test.mjs`
- `.github/workflows/pr-static-review.yml` 삭제
- `.semgrep.yml` 삭제

## 검증 계획

- Node 내장 테스트 러너로 입력 제한, AI 응답 검증, 댓글 렌더링을 확인한다.
- YAML 파서로 워크플로와 프롬프트 구문을 확인한다.
- PR 생성 후 `AI code review` GitHub Actions 실행과 리뷰 댓글 게시를 확인한다.

## 검증 결과

- `node --test .github/scripts/ai-review-core.test.mjs`
  - 입력 길이 제한, JSON 응답 검증, 댓글 링크 렌더링 테스트 4개 통과
- `npx --yes prettier@3.6.2 --check ...`
  - 워크플로 YAML, 프롬프트 YAML, JavaScript 파일 구문과 포맷 통과
- `actionlint 1.7.12 .github/workflows/pr-ai-review.yml`
  - GitHub Actions 문법 검증 통과
- `git diff --check`
  - 공백 오류 없음
- `actions/ai-inference` v2.1.1 소스 확인
  - `response-file` 출력이 모델 응답 원문을 UTF-8로 기록하는 것을 확인

## 검증 중 발생한 문제

- 로컬 Python에 `PyYAML`이 없어 첫 YAML 파싱 명령이 실패했다.
- 로컬에 Ruby가 없어 내장 YAML 파서를 대안으로 사용할 수 없었다.
- 별도 의존성을 저장소에 추가하지 않고 Prettier YAML 파서와 actionlint로 대체 검증했다.

## 잔여 리스크

- GitHub Models 무료 API는 요청 및 토큰 한도가 있으며 public preview 정책에 따라 변경될 수 있다.
- 8,000 입력 토큰 한도를 맞추기 위해 큰 PR은 앞부분의 diff만 검토한다.
- AI 결과는 오탐 또는 누락이 가능하므로 사람의 최종 리뷰를 대체하지 않는다.
