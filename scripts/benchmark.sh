# Assignment: Longest Common Subsequence (HPC Project)
# Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
# Lecturer: Moscato Francesco, fmoscato@unisa.it
#
# License: GPLv3 (see LICENSE file)
# Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
# Purpose: Script di automazione per eseguire i benchmark riproducibili su diverse dimensioni di input (1MB, ecc.).


#!/usr/bin/env bash
set -uo pipefail

# Path setup
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DATA="$ROOT/data"
BIN="$ROOT/build"
OUT="bench_results.csv"

# SIZES: 10KB, 50KB, 100KB, 200KB (bytes)
#SIZES=(10240 51200 102400 204800)

# SIZES: Solo 1MB
SIZES=(1048576)

REPS=1

# Header CSV
echo "impl,size,rep,param,time_s" > "$OUT"

for s in "${SIZES[@]}"; do
    echo "=========================================="
    echo "Testing Size: $s bytes"
    
    # Generazione Input
    # MODIFICA IMPORTANTE: Aggiunte virgolette attorno a $DATA e al percorso dello script
    if [ ! -f "$DATA/bench_${s}_A.bin" ]; then
        echo "Generating inputs..."
        python3 "$DATA/generate_input.py" --size-per-file "$s" --prefix "$DATA/bench_${s}" --seed 42 --alphabet ascii
    fi

    for r in $(seq 1 $REPS); do
        echo "  Rep $r/$REPS"

        # --- 1. SEQUENTIAL ---
        if [ "$s" -le 10485760 ]; then
            echo "    Running SEQ..."
            output=$("$BIN/lcs_seq" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin")
            t_seq=$(echo "$output" | grep "ELAPSED_TIME" | cut -d' ' -f2)
            echo "seq,$s,$r,NA,$t_seq" >> "$OUT"
        else
            echo "    Skipping SEQ (too big)"
        fi

        # --- 2. OMP ---
        echo "    Running OMP (1 thread)..."
        output=$("$BIN/lcs_omp" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin" 1)
        t_omp1=$(echo "$output" | grep "ELAPSED_TIME" | cut -d' ' -f2)
        echo "omp,$s,$r,1,$t_omp1" >> "$OUT"

        echo "    Running OMP (4 threads)..."
        output=$("$BIN/lcs_omp" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin" 4)
        t_omp4=$(echo "$output" | grep "ELAPSED_TIME" | cut -d' ' -f2)
        echo "omp,$s,$r,4,$t_omp4" >> "$OUT"

        # --- 3. MPI ---
        echo "    Running MPI (2 procs)..."
        # MPI a volte è schizzinoso con gli spazi anche con le virgolette, ma ci proviamo
        output=$(mpirun --allow-run-as-root -np 2 "$BIN/lcs_mpi" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin")
        t_mpi=$(echo "$output" | grep "ELAPSED_TIME" | cut -d' ' -f2)
        echo "mpi,$s,$r,2,$t_mpi" >> "$OUT"

        # --- 4. CUDA ---
        if command -v nvcc >/dev/null 2>&1 && [ -f "$BIN/lcs_cuda" ]; then
             for b in 128 256 512; do
                 echo "    Running CUDA (Block $b)..."
                 output=$("$BIN/lcs_cuda" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin" $b)
                 t_cuda=$(echo "$output" | grep "ELAPSED_TIME" | cut -d' ' -f2)
                 echo "cuda,$s,$r,$b,$t_cuda" >> "$OUT"
             done
        fi

    done
done

echo "Benchmark completed. Results in $OUT"