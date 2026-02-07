LCS HPC Project

Structure:
- inc/: headers
- src/: source files
- data/: input generator
- build/: binaries
- tests/: small test scripts

Quick start:
  make
  ./build/lcs_seq tests/sample_A.bin tests/sample_B.bin --print-seq

See tests/ for correctness checks and examples.

Generating large inputs:
  python3 data/generate_input.py --size-per-file 1048576 --prefix data/1MB
  python3 data/generate_input.py --size-per-file 10485760 --prefix data/10MB
  python3 data/generate_input.py --size-per-file 104857600 --prefix data/100MB
  python3 data/generate_input.py --size-per-file 524288000 --prefix data/500MB
  # 1GB may be generated similarly but ensure enough disk space and memory.

Notes:
- Sequential DP is O(n*m) memory; use Hirschberg for large inputs.
- OpenMP version supports `--print-seq` to print the LCS sequence (uses full DP for reconstruction).
- MPI version supports `--print-seq` (rank 0 reconstructs using Hirschberg for verification) and is stripe-based to distribute memory across ranks.
- CUDA implementation (anti-diagonal kernel) is available in `src/lcs_cuda.cu`; supports `--print-seq` to print sequence (copies matrix back to host for backtracking).
- Hybrid stub `lcs_omp_cuda` demonstrates a simple host-side wrapper calling the CUDA binary; it's principally a placeholder for hybrid experiments.
- Use `scripts/benchmark.sh` to run reproducible benchmarks (writes to bench_results.csv).