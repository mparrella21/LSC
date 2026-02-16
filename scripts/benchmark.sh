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

# LE DIMENSIONI COMPLETE
# Le piccole (10KB - 200KB) servono per vedere la curva nei grafici.
# La media (1MB) serve per lo stress test.
# Le enormi (10MB - 1GB) sono qui per rispetto alla traccia (ma verranno skippate).
SIZES=(10240 51200 102400 204800 1048576 10485760 104857600 524288000 1073741824)

# Header CSV
echo "impl,size,rep,param,time_s" > "$OUT"

for s in "${SIZES[@]}"; do
    echo "=========================================="
    echo "Processing Size: $s bytes"
    
    # 1. GENERAZIONE INPUT
    # Generiamo i file se non esistono.
    # Evitiamo di generare file > 10MB per non riempire l'hard disk inutilmente.
    if [ ! -f "$DATA/bench_${s}_A.bin" ]; then
        if [ "$s" -le 10485760 ]; then
             echo "Generating inputs..."
             python3 "$DATA/generate_input.py" --size-per-file "$s" --prefix "$DATA/bench_${s}" --seed 42 --alphabet ascii
        else
             echo "Skipping input generation for huge size $s (Virtual Test)"
        fi
    fi

    # 2. CONFIGURAZIONE RIPETIZIONI
    # 3 ripetizioni per test veloci (<1MB), 1 sola per 1MB per risparmiare tempo.
    if [ "$s" -ge 1048576 ]; then
        REPS=1
    else
        REPS=3
    fi

    # 3. LOGICA DI SALTO (Safety Caps)
    
    # SEQUENZIALE: Stop a 200KB (troppo lento dopo)
    RUN_SEQ=true
    if [ "$s" -gt 204800 ]; then RUN_SEQ=false; fi

    # PARALLELO (OMP/MPI): Stop a 1MB (troppo lento dopo)
    RUN_PAR=true
    if [ "$s" -gt 1048576 ]; then 
        RUN_PAR=false
        # Scriviamo nel CSV che abbiamo saltato
        echo "impl,$s,0,skipped,0" >> "$OUT"
        echo "WARNING: Size $s exceeds execution time limits. Logged as skipped."
        continue
    fi

    # CUDA: Stop a 50KB/100KB (dipende dalla tua GPU/Codice)
    # Se il tuo codice CUDA regge 1MB senza crashare, puoi alzare questo limite.
    # Ma per sicurezza teniamolo basso se non siamo su Colab.
    RUN_CUDA=true
    if [ "$s" -gt 102400 ]; then RUN_CUDA=false; fi


    for r in $(seq 1 $REPS); do
        echo "  Rep $r/$REPS"

        # --- 1. SEQUENTIAL ---
        if [ "$RUN_SEQ" = true ]; then
            echo "    Running SEQ..."
            output=$("$BIN/lcs_seq" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin")
            t_seq=$(echo "$output" | grep "ELAPSED_TIME" | cut -d' ' -f2)
            echo "seq,$s,$r,NA,$t_seq" >> "$OUT"
        fi

        # --- 2. OPENMP (1, 2, 4 Thread) ---
        if [ "$RUN_PAR" = true ]; then
            for t in 1 2 4; do
                echo "    Running OMP ($t threads)..."
                output=$("$BIN/lcs_omp" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin" $t)
                t_omp=$(echo "$output" | grep "ELAPSED_TIME" | cut -d' ' -f2)
                echo "omp,$s,$r,$t,$t_omp" >> "$OUT"
            done
        fi

        # --- 3. MPI (2, 4 Processi) ---
        if [ "$RUN_PAR" = true ]; then
            for p in 2 4; do
                echo "    Running MPI ($p procs)..."
                output=$(mpirun --allow-run-as-root --oversubscribe -np $p "$BIN/lcs_mpi" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin")
                t_mpi=$(echo "$output" | grep "ELAPSED_TIME" | cut -d' ' -f2)
                echo "mpi,$s,$r,$p,$t_mpi" >> "$OUT"
            done
        fi

        # --- 4. CUDA ---
        if [ "$RUN_CUDA" = true ] && command -v nvcc >/dev/null 2>&1 && [ -f "$BIN/lcs_cuda" ]; then
             for b in 128 256; do
                 echo "    Running CUDA (Block $b)..."
                 output=$("$BIN/lcs_cuda" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin" $b)
                 t_cuda=$(echo "$output" | grep "ELAPSED_TIME" | cut -d' ' -f2)
                 echo "cuda,$s,$r,$b,$t_cuda" >> "$OUT"
             done
        fi
    done
done

echo "Benchmark completed. Results in $OUT"