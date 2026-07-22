export const REVIEW_MARKER = "<!-- potato-ai-pr-review -->";
export const MAX_REVIEW_INPUT_CHARS = 20_000;

const SEVERITIES = new Set(["critical", "high", "medium", "low"]);

function appendWithinLimit(parts, value, state) {
  if (state.length >= state.limit) {
    state.truncated = true;
    return;
  }

  const remaining = state.limit - state.length;
  if (value.length > remaining) {
    parts.push(value.slice(0, remaining));
    state.length = state.limit;
    state.truncated = true;
    return;
  }

  parts.push(value);
  state.length += value.length;
}

export function formatReviewInput(
  pullRequest,
  files,
  limit = MAX_REVIEW_INPUT_CHARS,
) {
  const parts = [];
  const state = { length: 0, limit, truncated: false };
  const metadata = [
    `PR: #${pullRequest.number} ${pullRequest.title}`,
    `Base: ${pullRequest.base.ref}`,
    `Head: ${pullRequest.head.ref}`,
    `Description:\n${pullRequest.body || "(none)"}`,
    "",
  ].join("\n");
  appendWithinLimit(parts, metadata, state);

  for (const file of files) {
    const patch = file.patch || "(patch unavailable: binary or too large)";
    const section = [
      `## ${file.filename}`,
      `Status: ${file.status}; additions: ${file.additions}; deletions: ${file.deletions}`,
      "```diff",
      patch,
      "```",
      "",
    ].join("\n");
    appendWithinLimit(parts, section, state);
  }

  return { text: parts.join(""), truncated: state.truncated };
}

function stripCodeFence(value) {
  const trimmed = value.trim();
  const match = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
  return match ? match[1] : trimmed;
}

export function parseModelResponse(rawResponse) {
  if (typeof rawResponse !== "string" || rawResponse.trim() === "") {
    throw new Error("AI review response is empty");
  }

  const parsed = JSON.parse(stripCodeFence(rawResponse));
  if (typeof parsed.summary !== "string" || !Array.isArray(parsed.findings)) {
    throw new Error("AI review response does not match the expected structure");
  }

  const findings = parsed.findings.slice(0, 8).map((finding, index) => {
    if (
      !SEVERITIES.has(finding?.severity) ||
      typeof finding.title !== "string" ||
      typeof finding.body !== "string" ||
      typeof finding.path !== "string" ||
      !Number.isInteger(finding.line) ||
      finding.line < 1
    ) {
      throw new Error(`AI review finding ${index + 1} is invalid`);
    }

    return {
      severity: finding.severity,
      title: finding.title.trim(),
      body: finding.body.trim(),
      path: finding.path.trim(),
      line: finding.line,
    };
  });

  return { summary: parsed.summary.trim(), findings };
}

function encodePath(path) {
  return path.split("/").map(encodeURIComponent).join("/");
}

export function renderReviewComment(review, context) {
  const lines = [
    REVIEW_MARKER,
    "## AI PR Review",
    "",
    review.summary || "리뷰 요약이 제공되지 않았습니다.",
    "",
  ];

  if (review.findings.length === 0) {
    lines.push("등록된 변경사항에서 중요한 문제를 찾지 못했습니다.", "");
  } else {
    lines.push(`### Findings (${review.findings.length})`, "");
    for (const finding of review.findings) {
      const fileUrl = `${context.repositoryUrl}/blob/${context.headSha}/${encodePath(finding.path)}#L${finding.line}`;
      lines.push(
        `- **[${finding.severity.toUpperCase()}] ${finding.title}** ([${finding.path}:${finding.line}](${fileUrl}))`,
        `  ${finding.body}`,
      );
    }
    lines.push("");
  }

  if (context.truncated) {
    lines.push(
      "> 변경량이 무료 모델 입력 한도를 넘어 일부 diff만 검토했습니다.",
      "",
    );
  }

  lines.push(
    "<sub>GitHub Models의 AI 결과이므로 중요한 변경은 사람이 다시 확인해야 합니다.</sub>",
  );
  return lines.join("\n");
}
