# Notion Sync Guide

Notion은 코드의 대체물이 아니라 작업 맥락과 의사결정 기록을 공유하는 장소로 사용한다. 최종 진실은 GitHub Issue, PR, 코드, 테스트 결과다.

## Recommended Databases

- `Tasks`: GitHub Issue와 1:1로 연결되는 작업 페이지
- `Decision Log`: 기술 선택, 정책 변경, API 계약 변경 기록
- `Runbook`: 로컬 실행, 검증, 배포, 장애 대응 절차
- `API Contract`: 프론트와 백엔드가 공유하는 endpoint 계약
- `Validation Log`: 테스트 결과, 캡처, 실패와 해결 기록
- `Handoff`: 작업 중단 또는 이어받기 기록

## Task Page Fields

```text
Title:
GitHub Issue:
Branch:
Owner:
Status:
Scope:
Out of Scope:
Related Files:
Validation:
Risks:
Next Actions:
PR:
```

## Before Work

1. 작업 페이지의 목표와 제외 범위를 확인한다.
2. GitHub Issue 번호와 브랜치 이름을 확인한다.
3. 관련 Decision, API Contract, Runbook 링크를 확인한다.

## After Work

1. 변경 요약을 남긴다.
2. 실행한 검증 명령과 결과를 남긴다.
3. 실패한 명령, 환경 제약, 대체 검증을 남긴다.
4. PR 링크와 남은 리스크를 남긴다.
5. 다음 작업자가 바로 이어서 할 일을 남긴다.

## Secrets

- 실제 API 키, JWT secret, DB password, 개인 토큰은 Notion에 평문으로 적지 않는다.
- 필요한 경우 변수명과 발급 위치만 적는다.
- `.env.example`에는 키 이름과 설명만 남긴다.
