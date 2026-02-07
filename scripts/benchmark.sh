#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DATA=$ROOT/data
BIN=$ROOT/build
OUT=bench_results.csv

SIZES=(1048576 10485760 104857600 524288000) # 1MB,10MB,100MB,500MB (bytes per file)
REPS=3

echo "impl,size,rep,time_ms" > $OUT
for s in "${SIZES[@]}"; do
  echo "Generating inputs of size $s bytes per file..."
  python3 $DATA/generate_input.py --size-per-file $s --prefix "$DATA/bench_${s}" --seed 42 --alphabet ascii
  for r in $(seq 1 $REPS); do
    echo "Run seq (note: may be infeasible for large sizes)"
    t0=$(date +%s%3N)
    "$BIN/lcs_hirschberg" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin" > /dev/null
    t1=$(date +%s%3N)
    echo "hirschberg,$s,$r,$((t1-t0))" >> $OUT

    echo "Run omp"
    t0=$(date +%s%3N)
    "$BIN/lcs_omp" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin" 4 > /dev/null
    t1=$(date +%s%3N)
    echo "omp,$s,$r,$((t1-t0))" >> $OUT

    echo "Run mpi (2 procs)"
    t0=$(date +%s%3N)
    mpirun -np 2 "$BIN/lcs_mpi" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin" > /dev/null
    t1=$(date +%s%3N)
    echo "mpi,$s,$r,$((t1-t0))" >> $OUT

    # Run CUDA (if available)
    if command -v nvcc >/dev/null 2>&1 && [ -x "$BIN/lcs_cuda" ]; then
      echo "Run cuda"
      t0=$(date +%s%3N)
      "$BIN/lcs_cuda" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin" > /dev/null
      t1=$(date +%s%3N)
      echo "cuda,$s,$r,$((t1-t0))" >> $OUT
    fi

    # Run hybrid stub (if present)
    if [ -x "$BIN/lcs_omp_cuda" ]; then
      echo "Run hybrid (omp+cuda stub)"
      t0=$(date +%s%3N)
      "$BIN/lcs_omp_cuda" "$DATA/bench_${s}_A.bin" "$DATA/bench_${s}_B.bin" 4 > /dev/null
      t1=$(date +%s%3N)
      echo "hybrid,$s,$r,$((t1-t0))" >> $OUT
    fi
  done
done

echo "Benchmarks done, results in $OUT"
