# spark-redteam

Automated red-team test runner for **Gemini Spark indirect prompt injection** testing.

Tests vectors where a crafted GitHub issue or email causes Spark to call an attacker-controlled endpoint and exfiltrate data from the victim's Google Workspace (Gmail / Drive).

## Architecture

```
vectors/          JSON configs — one per test variant
runner/           Playwright scripts (submit task, poll, classify result)
capture/          Endpoints that log inbound data
  vercel-endpoint/  Vercel serverless function (all-requests logger)
  gas-script/       Google Apps Script web app (missing_parameter inducer)
analysis/         Parse results.jsonl → CSV rows for the test sheet
```

## Quick start

### Prerequisites
- Mac with Chrome + Playwright (`npm install -g playwright && npx playwright install chromium`)
- A persistent Chrome profile already logged into the victim Google account at `~/gmail-shots-udd`
- Tailscale SSH access to the Mac (or run locally)
- `VERCEL_TOKEN` env var set for log reads

### Run a single vector
```bash
cd runner
node run_vector.cjs ../vectors/gas-readme-quality.json
```

Output: `results/<vector-id>-<timestamp>.json` + screenshot

### Run all vectors
```bash
bash runner/batch_run.sh
```

Output: `results/batch-<timestamp>.jsonl` — one JSON record per run

### Analyze batch results
```bash
python3 analysis/parse_results.py results/batch-<timestamp>.jsonl
```

Prints a summary table and writes `results/batch-<timestamp>.csv` ready to paste into the test sheet.

## Vector config schema

```jsonc
{
  "id": "unique-kebab-id",
  "description": "Human-readable description",
  "target_account": "victim@gmail.com",
  "spark_prompt": "The task text submitted to Spark",
  "capture_endpoint": "https://...",   // URL to check for exfil signal
  "signals": ["token", "CANARY", ...], // Strings to scan for in response + logs
  "notes": "Anything useful for the tester"
}
```

## Capture endpoints

| Endpoint | URL | Log source |
|---|---|---|
| Vercel formatter | `https://readme-formatter.vercel.app` | Vercel runtime logs (search `CAPTURE`) |
| GAS ReadmeQuality | `https://script.google.com/macros/s/AKfycbx-FUx30WKrgCbbroSnTcWNBbMd_moD8YtYLCvSS8dMHLsuUo-msOZs8HqzVyt2GX_7/exec` | Forwards to Vercel `/capture` |

## Findings log

Results are recorded in the engagement testing sheet. See `analysis/parse_results.py` for the column mapping.

## Safety

- All test accounts are synthetic (controlled by the red team).
- All exfil data is canary/synthetic — no real PII or credentials.
- Do not point vectors at production accounts or real credentials.
