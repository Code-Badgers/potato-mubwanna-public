# SKILLS.md

이 문서는 Codex가 프로젝트에서 반복적으로 사용할 작업 기술과 절차를 정의한다.
구체적인 작업 규칙은 AGENTS.md를 우선하고, 이 문서는 작업 유형별 체크리스트로 사용한다.

## 1. Project Onboarding

Use when starting work in a repository.

- Read AGENTS.md first.
- Check `git status --short --branch`.
- Identify tech stack, package manager, test commands, app entry points.
- Read nearby code before changing anything.
- Prefer existing patterns over new abstractions.
- Record assumptions if requirements are ambiguous.

## 2. Feature Implementation

Use when adding a new feature.

- Define the smallest user-visible outcome.
- Find related models, API routes, UI components, tests, and docs.
- Update backend, frontend, types, validation, and tests together when contracts change.
- Include loading, empty, error, and invalid-input states where relevant.
- Run the closest test first, then broader validation if shared behavior changed.
- Avoid speculative extensibility.

## 3. Bug Fixing

Use when fixing incorrect behavior.

- Reproduce or identify the failing path first.
- Locate the smallest responsible code path.
- Add or update a regression test when practical.
- Fix the cause, not only the symptom.
- Check nearby edge cases.
- Summarize the original cause and verification result.

## 4. Refactoring

Use when improving structure without intended behavior changes.

- Confirm the refactor has a concrete benefit.
- Keep public behavior unchanged.
- Avoid mixing refactor with feature or bug changes.
- Prefer small, mechanical steps.
- Run tests before and after when possible.
- Do not rename or move files unless it clearly reduces complexity.

## 5. API Contract Work

Use when changing request/response behavior.

- Identify all consumers before changing the contract.
- Update DTOs, schemas, frontend types, mocks, and tests together.
- Preserve backward compatibility unless the breaking change is intentional.
- Define error responses explicitly.
- Verify pagination, sorting, filtering, auth, and validation behavior.

## 6. Database Change

Use when changing schema, seeds, or persistence behavior.

- Use migrations rather than ad hoc schema changes.
- Update entities, repositories, DTOs, tests, and seed data together.
- Consider existing production data and nullability.
- Avoid destructive migrations unless explicitly approved.
- Include rollback or recovery notes for risky changes.
- Test migration execution if tooling supports it.

## 7. Frontend UI Work

Use when changing screens, components, or interaction flows.

- Build the actual usable screen, not a decorative placeholder.
- Match the existing design system.
- Include loading, empty, error, disabled, and success states.
- Check mobile and desktop layouts.
- Avoid text overflow and overlapping UI.
- Prefer accessible controls and semantic HTML.
- Run build/lint and browser verification when layout or interaction changed.

## 8. Testing And Verification

Use before considering work complete.

- Start with the narrowest relevant test.
- Add regression tests for domain logic, parsing, permissions, statistics, and money-like calculations.
- Run broader tests when shared code, API contracts, or build configuration changed.
- If tests cannot run, record why and what risk remains.
- Never claim validation passed unless the command actually succeeded.

## 9. Production Debugging

Use when diagnosing incidents, deploy failures, auth issues, data corruption, or CI failures.

- Capture the exact symptom, time range, environment, and affected users.
- Check recent changes first.
- Inspect logs, failing checks, configuration, secrets, migrations, and external dependencies.
- Prefer a minimal reversible fix.
- Add monitoring, tests, or documentation if the issue is likely to recur.
- Record the problem-solving case if it is portfolio-worthy.

## 10. Documentation

Use when creating or updating project docs.

- Keep docs short, current, and action-oriented.
- Document commands, environment variables, deployment steps, and known risks.
- Prefer examples over long explanation.
- Update docs in the same change when behavior changes.
- Do not create duplicate sources of truth.

## 11. Git And PR Workflow

Use before committing or opening a PR.

- Check `git status --short`.
- Review `git diff`.
- Stage only files related to the task.
- Use an atomic commit.
- Do not commit generated or temporary files unless requested.
- Use the project’s commit message convention.
- Do not push directly to main unless explicitly approved.
- PR body should include summary, tests, operational impact, and post-deploy checks.

## 12. Handoff

Use when stopping before all work is finished.

- Record completed work.
- Record remaining tasks.
- Mention failing tests or commands not run.
- Note important assumptions, environment variables, and risky files.
- Leave the repo in a clear state for the next agent.
