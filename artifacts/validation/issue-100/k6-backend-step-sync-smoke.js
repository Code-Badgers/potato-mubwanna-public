import http from 'k6/http';
import { check, sleep } from 'k6';

http.setResponseCallback(http.expectedStatuses(200, 401, 403));

export const options = {
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
  },
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: 5,
      duration: '20s',
    },
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:18080/api';

export default function () {
  const payload = JSON.stringify({
    activityDate: '2026-07-21',
    steps: 8420,
    distanceMeters: 5894.0,
    source: 'HEALTH_CONNECT',
  });
  const response = http.put(`${BASE_URL}/potatoes/me/activity/daily`, payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(response, {
    'step sync requires auth': (res) => res.status === 401 || res.status === 403,
    'step sync response is json': (res) =>
      res.headers['Content-Type']?.includes('application/json') ?? false,
  });

  sleep(1);
}

export function handleSummary(data) {
  const metrics = {
    checksRate: data.metrics.checks?.values?.rate ?? 0,
    requests: data.metrics.http_reqs?.values?.count ?? 0,
    failedRate: data.metrics.http_req_failed?.values?.rate ?? 0,
    avgDuration: data.metrics.http_req_duration?.values?.avg ?? 0,
    p95Duration: data.metrics.http_req_duration?.values?.['p(95)'] ?? 0,
    maxDuration: data.metrics.http_req_duration?.values?.max ?? 0,
  };

  return {
    'artifacts/validation/issue-100/k6-backend-summary.json': JSON.stringify(data, null, 2),
    'artifacts/validation/issue-100/k6-backend-report.html': htmlReport(metrics),
    stdout: textSummary(metrics),
  };
}

function textSummary(metrics) {
  return [
    '',
    'k6 backend step sync smoke summary',
    `checks_rate=${percent(metrics.checksRate)}`,
    `requests=${metrics.requests}`,
    `failed_rate=${percent(metrics.failedRate)}`,
    `avg_duration_ms=${fixed(metrics.avgDuration)}`,
    `p95_duration_ms=${fixed(metrics.p95Duration)}`,
    `max_duration_ms=${fixed(metrics.maxDuration)}`,
    '',
  ].join('\n');
}

function htmlReport(metrics) {
  return `<!doctype html>
<html lang="ko">
<head><meta charset="utf-8"><title>Issue 100 k6 Backend Step Sync Report</title>
<style>body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;margin:40px;color:#1f2a1f;background:#f8fbf5}.grid{display:grid;grid-template-columns:repeat(3,minmax(160px,1fr));gap:14px;margin-top:24px}.card{background:white;border:1px solid #dfe8dd;border-radius:10px;padding:18px;box-shadow:0 8px 24px rgba(31,42,31,.08)}.label{color:#657060;font-size:13px;font-weight:700}.value{margin-top:8px;font-size:26px;font-weight:900}.ok{color:#2fba70}</style></head>
<body><h1>Issue 100 Backend k6 Smoke Report</h1><p>대상: PUT /api/potatoes/me/activity/daily 인증 필요 경로 · 5 VUs · 20초</p><div class="grid">
${metricCard('Checks', percent(metrics.checksRate), 'ok')}${metricCard('Requests', metrics.requests)}${metricCard('Failed Rate', percent(metrics.failedRate), metrics.failedRate === 0 ? 'ok' : '')}${metricCard('Avg Duration', `${fixed(metrics.avgDuration)} ms`)}${metricCard('P95 Duration', `${fixed(metrics.p95Duration)} ms`, metrics.p95Duration < 500 ? 'ok' : '')}${metricCard('Max Duration', `${fixed(metrics.maxDuration)} ms`)}</div></body></html>`;
}

function metricCard(label, value, className = '') {
  return `<section class="card"><div class="label">${label}</div><div class="value ${className}">${value}</div></section>`;
}
function percent(value) { return `${fixed(value * 100)}%`; }
function fixed(value) { return Number(value).toFixed(2); }
