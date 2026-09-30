#!/usr/bin/env python3
"""Parse a batch results JSONL file into a summary table and CSV rows for the test sheet."""

import json
import sys
import csv
import io
from pathlib import Path
from datetime import datetime

def load_results(path):
    results = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    results.append(json.loads(line))
                except json.JSONDecodeError as e:
                    print(f"Skipping bad line: {e}", file=sys.stderr)
    return results

def summarize(results):
    counts = {"EXFIL": 0, "DECLINED": 0, "UNKNOWN": 0, "ERROR": 0}
    for r in results:
        o = r.get("outcome", "ERROR")
        counts[o] = counts.get(o, 0) + 1

    print(f"\n{'='*60}")
    print(f"BATCH SUMMARY — {len(results)} vectors")
    print(f"{'='*60}")
    print(f"  EXFIL:    {counts.get('EXFIL', 0)}")
    print(f"  DECLINED: {counts.get('DECLINED', 0)}")
    print(f"  UNKNOWN:  {counts.get('UNKNOWN', 0)}")
    print(f"  ERROR:    {counts.get('ERROR', 0)}")
    print()

    print(f"{'ID':<35} {'OUTCOME':<10} {'SIGNALS'}")
    print(f"{'-'*35} {'-'*10} {'-'*30}")
    for r in results:
        vid = r.get("vector_id", r.get("vector", "?"))[:34]
        outcome = r.get("outcome", "?")
        signals = ", ".join(r.get("signals_found", []))
        print(f"{vid:<35} {outcome:<10} {signals}")
    print()

def to_csv_rows(results):
    """Return CSV rows matching the test sheet schema (cols A-Q)."""
    rows = []
    for r in results:
        ts = r.get("ts", "")[:10]
        vid = r.get("vector_id", "")
        desc = r.get("description", "")
        outcome = r.get("outcome", "")
        signals = "; ".join(r.get("signals_found", []))
        snippet = "; ".join(r.get("snippets", {}).values())[:200]
        rows.append({
            "Test ID": vid,
            "Date": ts,
            "Description": desc,
            "Outcome": outcome,
            "Signals Found": signals,
            "Snippet": snippet,
            "Task URL": r.get("task_url", ""),
            "Screenshot Prefix": r.get("screenshot_prefix", ""),
        })
    return rows

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 parse_results.py <batch.jsonl>")
        sys.exit(1)

    path = Path(sys.argv[1])
    results = load_results(path)
    summarize(results)

    csv_path = path.with_suffix(".csv")
    rows = to_csv_rows(results)
    if rows:
        with open(csv_path, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=rows[0].keys())
            w.writeheader()
            w.writerows(rows)
        print(f"CSV written: {csv_path}")

if __name__ == "__main__":
    main()
