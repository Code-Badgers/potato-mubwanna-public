import fs from "node:fs";
import { pathToFileURL } from "node:url";
import {
  REVIEW_MARKER,
  parseModelResponse,
  renderReviewComment,
} from "./ai-review-core.mjs";

async function githubRequest(url, token, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      Accept: "application/vnd.github+json",
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      "X-GitHub-Api-Version": "2022-11-28",
      ...options.headers,
    },
  });
  if (!response.ok) {
    throw new Error(
      `GitHub API request failed: ${response.status} ${await response.text()}`,
    );
  }
  return response.status === 204 ? null : response.json();
}

async function findExistingComment(apiUrl, repository, number, token) {
  for (let page = 1; ; page += 1) {
    const comments = await githubRequest(
      `${apiUrl}/repos/${repository}/issues/${number}/comments?per_page=100&page=${page}`,
      token,
    );
    const existing = comments.find(
      (comment) =>
        comment.user?.login === "github-actions[bot]" &&
        comment.body?.includes(REVIEW_MARKER),
    );
    if (existing) return existing;
    if (comments.length < 100) return null;
  }
}

function readResponse(env) {
  if (env.AI_RESPONSE_FILE && fs.existsSync(env.AI_RESPONSE_FILE)) {
    return fs.readFileSync(env.AI_RESPONSE_FILE, "utf8");
  }
  return env.AI_RESPONSE || "";
}

export async function main(env = process.env) {
  const event = JSON.parse(fs.readFileSync(env.GITHUB_EVENT_PATH, "utf8"));
  if (!event.pull_request)
    throw new Error("This workflow requires a pull_request event");
  if (!env.GITHUB_TOKEN) throw new Error("GITHUB_TOKEN is required");

  const review = parseModelResponse(readResponse(env));
  const body = renderReviewComment(review, {
    repositoryUrl: event.repository.html_url,
    headSha: event.pull_request.head.sha,
    truncated: env.REVIEW_INPUT_TRUNCATED === "true",
  });
  const apiUrl = env.GITHUB_API_URL || "https://api.github.com";
  const existing = await findExistingComment(
    apiUrl,
    env.GITHUB_REPOSITORY,
    event.pull_request.number,
    env.GITHUB_TOKEN,
  );
  const endpoint = existing
    ? `${apiUrl}/repos/${env.GITHUB_REPOSITORY}/issues/comments/${existing.id}`
    : `${apiUrl}/repos/${env.GITHUB_REPOSITORY}/issues/${event.pull_request.number}/comments`;

  await githubRequest(endpoint, env.GITHUB_TOKEN, {
    method: existing ? "PATCH" : "POST",
    body: JSON.stringify({ body }),
  });
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
