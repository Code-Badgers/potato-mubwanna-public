# Issue #107 검증 기록

## 작업 요약

- 이슈: #107 `chore: 무료 PR 정적 리뷰 자동화 도입`
- 브랜치: `feat/107-semgrep-pr-review`
- 목표: Gemini Code Assist 종료 후에도 비공개 저장소의 PR 신규 코드를 무료로 자동 검사하고 인라인 피드백을 제공한다.
- 적용안: Semgrep Community Edition + reviewdog + GitHub Actions
- 제외 범위: 유료 AI 리뷰, Semgrep SaaS 계정 생성, 조직 secret 등록, branch protection 변경

## 대안 검토

### 선택: Semgrep CE + reviewdog

- 별도 SaaS 계정, LLM API key, 유료 구독이 필요 없다.
- 소스 분석은 GitHub Actions runner 안에서 수행하고 Semgrep metrics는 끈다.
- reviewdog가 SARIF finding 중 PR 신규 라인에 해당하는 결과만 리뷰로 게시한다.
- Java와 Dart용 저장소 규칙을 같은 저장소에서 버전 관리할 수 있다.

### 선택하지 않은 후보

- CodeRabbit Free: 공개/비공개 저장소 연결은 가능하지만 무료 플랜의 GitHub PR 기능은 요약만 제공하고 전체 PR 리뷰는 Pro 기능이다.
  - https://docs.coderabbit.ai/management/plans
- Qodo Merge: 14일 체험 이후 유지되는 영구 무료 플랜이 없다.
  - https://www.qodo.ai/pricing/
- GitHub Copilot Free: Copilot code review를 포함하지 않는다.
  - https://docs.github.com/en/copilot/concepts/agents/code-review
- Semgrep AppSec Platform Free: 비공개 저장소 10개, 최근 90일 기여자 10명까지 무료이고 AI 기능을 제공한다. 현재 저장소는 이 범위에 들어가지만 외부 서비스 온보딩 없이 바로 작동하는 CE 구성을 우선 적용했다.
  - https://semgrep.dev/pricing/
  - https://semgrep.dev/docs/usage-limits/

## 변경 파일

- `.github/workflows/pr-static-review.yml`: PR 이벤트에서 Semgrep 1.170.1을 실행하고 reviewdog 0.21.0으로 신규 finding을 게시한다.
- `.semgrep.yml`: 프로젝트 고유 Java/Dart 규칙 4개를 정의한다.

## 공유 파일 / 운영 영향

- 공유 위험 파일: `.github/workflows/pr-static-review.yml`
- 수정 이유: 모든 PR에 영향을 주는 코드 리뷰 자동화를 도입하기 위해 필요하다.
- 권한: `contents: read`, `pull-requests: write`
- 외부 action: checkout, setup-python, reviewdog action을 검증한 commit SHA로 고정했다.
- API 계약: 없음
- DB migration: 없음
- 환경 변수/secret: 없음
- fork PR: 쓰기 권한이 제한되므로 job을 건너뛴다.

## 저장소 규칙

- Spring Boot 3 코드의 `javax.persistence` import 금지
- Backend 운영 코드의 `System.out`/`System.err` 사용 경고
- 공통 네트워크 계층 밖에서 Flutter `Dio()` 직접 생성 경고
- Flutter 운영 코드의 `print`/`debugPrint` 사용 경고

## 검증

### YAML 및 공급망 설정

```powershell
python -c "from ruamel.yaml import YAML; ..."
```

- 결과: workflow와 Semgrep config 2개 파일 parse 성공
- 결과: 외부 action 3개가 모두 40자리 commit SHA로 고정됨
- 결과: `git diff --check` 통과

### 로컬 Semgrep 시도

```powershell
python -m venv $env:TEMP\potato-semgrep-107
python -m pip install semgrep==1.170.1
semgrep --legacy scan --config .semgrep.yml ...
```

- 설치: 성공
- 실행: 실패
- 원인: Windows 애플리케이션 제어 정책이 Semgrep 엔진 실행 파일을 `WinError 4551`로 차단했다.
- 대체 검증: 동일 Semgrep 버전을 Ubuntu GitHub-hosted runner에서 실행했다.

### GitHub Actions 1차 실행

- 실행: https://github.com/Code-Badgers/potato-mubwanna/actions/runs/29905217457
- 결과: 실패, Semgrep scan exit code 2
- 원인: `--config auto`와 `--metrics=off`를 함께 사용할 수 없다.
- 해결: 자동 config 대신 공개 규칙 묶음 `p/default`를 명시해 metrics를 계속 비활성화했다.

### GitHub Actions 2차 실행

- 실행: https://github.com/Code-Badgers/potato-mubwanna/actions/runs/29905296511
- 결과: 성공
- 추가 확인: Semgrep 경로 패턴의 향후 해석 변경 경고를 발견했다.
- 해결: custom rule 경로를 저장소 루트 기준 `/backend/**`, `/frontend/**`로 고정했다.

### GitHub Actions 최종 실행

- 실행: https://github.com/Code-Badgers/potato-mubwanna/actions/runs/29905399249
- 결과: 성공, 전체 단계 통과
- 시간: 36초
- 규칙: 244개 실행
- 대상: 423개 파일
- 파싱: 약 99.9%
- 경로 경고: 0건
- 기존 finding: 1건. 이번 PR 신규 라인이 아니므로 reviewdog의 `filter-mode=added`에 의해 코멘트 및 차단 대상에서 제외됐다.

## 남은 리스크

- 정적 규칙 기반 검사이므로 Gemini처럼 설계 의도나 광범위한 문맥을 자연어로 검토하지는 않는다.
- 공개 Semgrep Registry의 `p/default` 규칙 내용은 시간이 지나며 갱신될 수 있다. Semgrep CLI와 외부 action 버전은 고정했다.
- fork PR은 GitHub의 write token 제한 때문에 인라인 리뷰를 게시하지 않는다.
- 기존 코드 finding 1건은 #107 범위 밖이며 별도 이슈에서 확인해야 한다.
- merge 차단에 사용하려면 PR 병합 후 저장소 branch protection에서 `Semgrep review`를 required check로 지정해야 한다.

## 다음 작업

- PR #108을 리뷰하고 병합한다.
- 필요 시 `main` branch protection에 `Semgrep review` required check를 추가한다.
- 자연어 AI 분류가 필요해지면 Semgrep Free 온보딩을 별도 이슈로 진행하되 코드 전송 및 보존 정책을 먼저 확인한다.
