#!/usr/bin/env bash
# Script di verifica correttezza: Confronta binario parallelo con lcs_seq
set -euo pipefail

if [ $# -lt 3 ]; then 
    echo "Usage: $0 <parallel-binary> <fileA> <fileB> [extra args]"
    exit 1
fi

BIN="$1"
shift
A="$1"
B="$2"
shift 2

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# FIX: Usiamo lcs_seq come riferimento affidabile (Gold Standard)
SEQ="$ROOT/build/lcs_seq"

parallel_out=$(mktemp)
# Eseguiamo il binario parallelo
"$BIN" "$A" "$B" "$@" > "$parallel_out"

# FIX: Cerchiamo "RESULT_LEN:" invece di "LCS length ="
par_len=$(grep -a "RESULT_LEN:" "$parallel_out" | awk '{print $2}' || echo "0")

seq_out=$(mktemp)
# Eseguiamo Sequenziale
"$SEQ" "$A" "$B" > "$seq_out"
# FIX: Anche qui cerchiamo "RESULT_LEN:"
seq_len=$(grep -a "RESULT_LEN:" "$seq_out" | awk '{print $2}' || echo "0")

# Pulizia output
par_len=$(echo "$par_len" | tr -d '[:space:]')
seq_len=$(echo "$seq_len" | tr -d '[:space:]')

if [ "$par_len" = "$seq_len" ] && [ "$seq_len" != "0" ]; then 
    echo "PASS: lengths equal ($par_len)"
    rm "$parallel_out" "$seq_out"
    exit 0
else 
    echo "FAIL: par=$par_len seq=$seq_len"
    echo "--- Test Output ---"
    cat "$parallel_out"
    echo "--- Reference Output ---"
    cat "$seq_out"
    rm "$parallel_out" "$seq_out"
    exit 2
fi