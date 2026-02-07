#!/usr/bin/env bash
set -euo pipefail
if [ $# -lt 3 ]; then echo "Usage: $0 <parallel-binary> <fileA> <fileB> [extra args]"; exit 1; fi
BIN=$1; shift
A=$1; B=$2; shift 2
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SEQ=$ROOT/build/lcs_hirschberg
parallel_out=$(mktemp)
$BIN "$A" "$B" "$@" > "$parallel_out"
par_len=$(grep -Eo 'LCS length = [0-9]+' "$parallel_out" | awk '{print $3}' || true)
seq_out=$(mktemp)
$SEQ "$A" "$B" > "$seq_out"
seq_len=$(grep -Eo 'Hirschberg len=[0-9]+' "$seq_out" | awk -F= '{print $2}' || true)
if [ "$par_len" = "$seq_len" ]; then echo "PASS: lengths equal ($par_len)"; rm "$parallel_out" "$seq_out"; exit 0; else echo "FAIL: par=$par_len seq=$seq_len"; cat "$parallel_out"; cat "$seq_out"; rm "$parallel_out" "$seq_out"; exit 2; fi
