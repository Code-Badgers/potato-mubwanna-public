import assert from "node:assert/strict";
import test from "node:test";
import {
  REVIEW_MARKER,
  formatReviewInput,
  parseModelResponse,
  renderReviewComment,
} from "./ai-review-core.mjs";

const pullRequest = {
  number: 112,
  title: "AI review",
  body: "Replace static review",
  base: { ref: "main" },
  head: { ref: "chore/112-ai-pr-review" },
};

test("formatReviewInput includes metadata and truncates oversized patches", () => {
  const files = [
    {
      filename: "backend/src/App.java",
      status: "modified",
      additions: 1,
      deletions: 0,
      patch: `+${"x".repeat(200)}`,
    },
  ];
  const result = formatReviewInput(pullRequest, files, 120);

  assert.equal(result.text.length, 120);
  assert.equal(result.truncated, true);
  assert.match(result.text, /PR: #112 AI review/);
});

test("parseModelResponse accepts JSON wrapped in a code fence", () => {
  const review = parseModelResponse(`\`\`\`json
    {"summary":"확인 완료","findings":[{"severity":"high","title":"오류","body":"설명","path":"backend/App.java","line":12}]}
  \`\`\``);

  assert.equal(review.summary, "확인 완료");
  assert.equal(review.findings[0].line, 12);
});

test("parseModelResponse rejects invalid findings", () => {
  assert.throws(
    () =>
      parseModelResponse('{"summary":"x","findings":[{"severity":"unknown"}]}'),
    /finding 1 is invalid/,
  );
});

test("renderReviewComment creates stable marker and source link", () => {
  const comment = renderReviewComment(
    {
      summary: "검토 결과",
      findings: [
        {
          severity: "medium",
          title: "검증 누락",
          body: "입력을 검증해야 합니다.",
          path: "backend/src/App.java",
          line: 42,
        },
      ],
    },
    {
      repositoryUrl: "https://github.com/example/repo",
      headSha: "abc123",
      truncated: false,
    },
  );

  assert.match(
    comment,
    new RegExp(REVIEW_MARKER.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")),
  );
  assert.match(comment, /backend\/src\/App\.java#L42/);
  assert.match(comment, /\[MEDIUM\]/);
});
