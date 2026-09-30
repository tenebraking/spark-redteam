#!/usr/bin/env bash
# batch_run.sh — Run all vectors in ../vectors/ and append results to a timestamped JSONL file.
# Usage: bash batch_run.sh [--vectors <dir>] [--out <results-dir>] [--udd <chrome-profile>]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VECTORS_DIR="${SCRIPT_DIR}/../vectors"
RESULTS_DIR="${SCRIPT_DIR}/../results"
UDD="${HOME}/gmail-shots-udd"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vectors) VECTORS_DIR="$2"; shift 2 ;;
    --out)     RESULTS_DIR="$2"; shift 2 ;;
    --udd)     UDD="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

mkdir -p "$RESULTS_DIR"
BATCH_FILE="${RESULTS_DIR}/batch-$(date -u +%Y%m%dT%H%M%SZ).jsonl"
echo "Batch file: $BATCH_FILE"

PASS=0; FAIL=0; EXFIL=0; DECLINED=0

for VECTOR in "$VECTORS_DIR"/*.json; do
  [[ "$VECTOR" == *template* ]] && continue
  echo ""
  echo "=== Running vector: $(basename "$VECTOR") ==="
  set +e
  RESULT=$(node "$SCRIPT_DIR/run_vector.cjs" "$VECTOR" --udd "$UDD" --out "$RESULTS_DIR" 2>&1)
  EXIT=$?
  set -e

  echo "$RESULT"

  # Extract the JSON result file path from stdout
  RESULT_PATH=$(echo "$RESULT" | grep "Result saved:" | sed 's/.*Result saved: //')
  if [[ -f "$RESULT_PATH" ]]; then
    cat "$RESULT_PATH" >> "$BATCH_FILE"
    echo "" >> "$BATCH_FILE"
    OUTCOME=$(python3 -c "import json,sys; print(json.load(open('$RESULT_PATH'))['outcome'])" 2>/dev/null || echo "UNKNOWN")
    case "$OUTCOME" in
      EXFIL)    EXFIL=$((EXFIL+1)); PASS=$((PASS+1)) ;;
      DECLINED) DECLINED=$((DECLINED+1)) ;;
      *)        FAIL=$((FAIL+1)) ;;
    esac
  else
    echo "{\"vector\": \"$(basename "$VECTOR")\", \"outcome\": \"ERROR\", \"exit\": $EXIT}" >> "$BATCH_FILE"
    FAIL=$((FAIL+1))
  fi

  # Brief pause between vectors to avoid rate limiting
  sleep 15
done

echo ""
echo "=== BATCH COMPLETE ==="
echo "EXFIL: $EXFIL  DECLINED: $DECLINED  ERROR/UNKNOWN: $FAIL"
echo "Results: $BATCH_FILE"
