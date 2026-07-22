import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { formatReviewInput } from "./ai-review-core.mjs";

async function githubRequest(url, token) {
  const response = await fetch(url, {
    headers: {
      Accept: "application/vnd.github+json",
      Authorization: `Bearer ${token}`,
      "X-GitHub-Api-Version": "2022-11-28",
    },
  });
  if (!response.ok) {
    throw new Error(
      `GitHub API request failed: ${response.status} ${await response.text()}`,
    );
  }
  return response.json();
}

async function listPullRequestFiles(apiUrl, repository, number, token) {
  const files = [];
  for (let page = 1; ; page += 1) {
    const batch = await githubRequest(
      `${apiUrl}/repos/${repository}/pulls/${number}/files?per_page=100&page=${page}`,
      token,
    );
    files.push(...batch);
    if (batch.length < 100) break;
  }
  return files;
}

function setOutput(name, value, outputFile) {
  fs.appendFileSync(outputFile, `${name}=${value}${os.EOL}`, "utf8");
}

export async function main(env = process.env) {
  const event = JSON.parse(fs.readFileSync(env.GITHUB_EVENT_PATH, "utf8"));
  if (!event.pull_request)
    throw new Error("This workflow requires a pull_request event");
  if (!env.GITHUB_TOKEN) throw new Error("GITHUB_TOKEN is required");

  const files = await listPullRequestFiles(
    env.GITHUB_API_URL || "https://api.github.com",
    env.GITHUB_REPOSITORY,
    event.pull_request.number,
    env.GITHUB_TOKEN,
  );
  const reviewInput = formatReviewInput(event.pull_request, files);
  const inputFile = path.join(
    env.RUNNER_TEMP || os.tmpdir(),
    "ai-review-input.md",
  );
  fs.writeFileSync(inputFile, reviewInput.text, "utf8");
  setOutput("input-file", inputFile, env.GITHUB_OUTPUT);
  setOutput("truncated", String(reviewInput.truncated), env.GITHUB_OUTPUT);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
