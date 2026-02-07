#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BIN=$ROOT/build
python3 - <<PY
s1 = b"ABCBDAB"
s2 = b"BDCAB"
open('tests/sample_A.bin','wb').write(s1)
open('tests/sample_B.bin','wb').write(s2)
PY

echo "Building..."
make -s

echo "Running sequential..."
"$BIN/lcs_seq" tests/sample_A.bin tests/sample_B.bin --print-seq > tests/out_seq.txt
cat tests/out_seq.txt

echo "Running Hirschberg..."
# compile and run a small wrapper to test hirschberg sequence via a tiny harness
cat > tests/h_test.c <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../inc/lcs.h"
int main(){ FILE *fa=fopen("tests/sample_A.bin","rb"), *fb=fopen("tests/sample_B.bin","rb"); fseek(fa,0,SEEK_END); size_t na=ftell(fa); fseek(fa,0,SEEK_SET); char *a=malloc(na); fread(a,1,na,fa); fclose(fa);
 fseek(fb,0,SEEK_END); size_t nb=ftell(fb); fseek(fb,0,SEEK_SET); char *b=malloc(nb); fread(b,1,nb,fb); fclose(fb);
 size_t out; char *s = lcs_sequence_hirschberg(a,na,b,nb,&out); if(s) { printf("Hirschberg: len=%zu seq=%s\n", out, s); free(s); } else printf("Hirschberg: len=0\n"); free(a); free(b); return 0; }
C

gcc -O2 -std=c11 -Iinc tests/h_test.c src/lcs_hirschberg.c -o tests/h_test
./tests/h_test > tests/out_hir.txt
cat tests/out_hir.txt

echo "Testing OpenMP (1 and 4 threads)..."
"$BIN/lcs_omp" tests/sample_A.bin tests/sample_B.bin 1 > tests/out_omp1.txt
"$BIN/lcs_omp" tests/sample_A.bin tests/sample_B.bin 4 > tests/out_omp4.txt
cat tests/out_omp1.txt
cat tests/out_omp4.txt

echo "Testing MPI (single-node run with 2 procs)..."
mpirun -np 2 "${BIN}/lcs_mpi" tests/sample_A.bin tests/sample_B.bin > tests/out_mpi.txt
cat tests/out_mpi.txt

echo "MPI with sequence reconstruction (rank0)"
mpirun -np 2 "${BIN}/lcs_mpi" tests/sample_A.bin tests/sample_B.bin --print-seq > tests/out_mpi_print.txt || true
cat tests/out_mpi_print.txt || true

# If nvcc is available, build and test CUDA binary
if command -v nvcc >/dev/null 2>&1; then
  echo "Testing CUDA binary..."
  make -s $(BIN)/lcs_cuda >/dev/null 2>&1 || true
  if [ -x "$BIN/lcs_cuda" ]; then
    "$BIN/lcs_cuda" tests/sample_A.bin tests/sample_B.bin --print-seq > tests/out_cuda.txt || true
    cat tests/out_cuda.txt || true
  else
    echo "CUDA binary not built"
  fi
else
  echo "nvcc not found; skipping CUDA tests"
fi

# Hybrid stub
if [ -x "$BIN/lcs_omp_cuda" ]; then
  echo "Testing hybrid stub (calls CUDA)..."
  "$BIN/lcs_omp_cuda" tests/sample_A.bin tests/sample_B.bin 2 > tests/out_hybrid.txt || true
  cat tests/out_hybrid.txt || true
fi

echo "All tests ran (compare outputs manually for correctness)."
