# Project Summary — LCS HPC

This file summarizes what has been implemented, where to find it, and how to study and run each component.

## High-level tasks completed
1. Baseline sequential LCS (DP matrix) and memory-optimized Hirschberg implementation.
2. OpenMP shared-memory length computation using anti-diagonals; optional sequence reconstruction (`--print-seq`).
3. MPI message-passing version (stripe-based) that distributes rows across ranks; optional reconstruction at rank 0 via Hirschberg (`--print-seq`).
4. CUDA anti-diagonal implementation (`src/lcs_cuda.cu`) with host wrapper; optional `--print-seq` that copies matrix back to host and reconstructs the sequence.
5. Hybrid placeholder `src/lcs_omp_cuda.c` that calls the CUDA binary demonstrating host/GPU invocation.
6. Input generator, benchmark scripts, tests, Colab notebook template, Makefile, README and HOWTO documentation.

---

## File / Directory overview
- `inc/lcs.h` — public function declarations and API notes.
- `src/lcs_core.c` — core implementations (lcs_length_dp, lcs_sequence_dp) used by multiple binaries.
- `src/lcs_seq.c` — CLI for sequential DP (uses core functions). Use `--print-seq` to print the sequence.
- `src/lcs_hirschberg.c` and `src/lcs_hirschberg_cli.c` — Hirschberg memory-optimized sequence computation and CLI wrapper.
- `src/lcs_omp.c` — OpenMP anti-diagonal length computation; CLI supports `threads` and `--print-seq` to reconstruct sequence using full DP.
- `src/lcs_mpi.c` — MPI stripe-based implementation for length; supports `--print-seq` (rank 0 reconstructs via Hirschberg).
- `src/lcs_cuda.cu` — CUDA anti-diagonal implementation (per-diagonal kernel launches). Supports `--print-seq` (host backtracking).
- `src/lcs_omp_cuda.c` — hybrid stub (calls `build/lcs_cuda` as a simple hybrid demo).

- `data/generate_input.py` — generator to create input files of sizes (1MB, 10MB, 100MB, 500MB, 1GB if space allows). Options: `--size-per-file`, `--alphabet`, `--seed`.
- `tests/run_tests.sh` — runs full local tests (seq, Hirschberg, OpenMP, MPI, CUDA if available, hybrid stub).
- `tests/test_lcs_cli.py` — simple pytest tests for CLI behavior.
- `scripts/benchmark.sh` — runs reproducible benchmarks for sizes: 1MB, 10MB, 100MB, 500MB. Writes `bench_results.csv` with timings for Hirschberg, OpenMP, MPI, CUDA (if available), hybrid stub.
- `cuda_lcs_colab.ipynb` — Colab notebook template to compile and run the CUDA implementation on Google Colab with GPU runtime (cells to compile, test and benchmark).
- `Makefile` — `all | clean | test`; builds `build/lcs_seq`, `build/lcs_hirschberg`, `build/lcs_omp`, `build/lcs_mpi`, `build/lcs_cuda` (if nvcc available), `build/lcs_omp_cuda`.
- `HOWTO.md` — step-by-step instructions to build, test, generate inputs and run benchmarks.
- `README.txt` — quick overview and notes.
- `PROJECT_SUMMARY.md` — (this file) compact explanation.

---

## How to study the code
1. Read `inc/lcs.h` for the API and function contracts.
2. Read `src/lcs_core.c` to understand the standard DP and backtrack (this is the simplest, authoritative reference).
3. Read `src/lcs_hirschberg.c` to study the memory-optimized divide&conquer approach (useful for large inputs).
4. Read `src/lcs_omp.c` to see how anti-diagonal wavefront parallelism is applied with OpenMP; note the CLI options for `--print-seq`.
5. Read `src/lcs_mpi.c` for a stripe-based memory distribution: each rank computes a block of rows and forwards the last row; note the correctness verification mode (`--print-seq`) which runs Hirschberg on rank 0.
6. Read `src/lcs_cuda.cu` and the Colab notebook to understand the GPU per-diagonal kernel approach and how to compile/run on Colab.

Tips:
- To understand the parallel schemes, sketch the DP matrix and the anti-diagonal order (cells with i+j=k can be computed concurrently).
- For MPI, consider how rows are partitioned and why passing only the last computed row is sufficient for correctness.

---

## How to run and reproduce results (minimal)
1. Build all: `make`
2. Small correctness tests: `bash tests/run_tests.sh`
3. Generate a 10MB test: `python3 data/generate_input.py --size-per-file 10485760 --prefix data/10MB --seed 42 --alphabet ascii`
4. Run OpenMP (4 threads): `./build/lcs_omp data/10MB_A.bin data/10MB_B.bin 4 --print-seq`
5. Run MPI (2 procs & verify): `mpirun -np 2 ./build/lcs_mpi data/10MB_A.bin data/10MB_B.bin --print-seq`
6. Run CUDA on a machine with nvcc/GPU (or in Colab): `nvcc src/lcs_cuda.cu -O2 -o lcs_cuda && ./lcs_cuda data/10MB_A.bin data/10MB_B.bin --print-seq`
7. Run benchmarks (may take long): `bash scripts/benchmark.sh` — results in `bench_results.csv`.

Notes on large inputs and limits:
- The sequential full-DP (`lcs_seq`) needs O(n*m) memory and will quickly become infeasible (use Hirschberg or MPI for very large inputs).
- The CUDA implementation also keeps the full matrix on-device in this demo; for production-grade large inputs implement streaming/banded kernels.

---

## Next recommended steps (if you want me to continue)
- Improve CUDA memory usage: implement banded streaming or tiling to support very large inputs without full matrix on GPU.
- Implement a full hybrid OpenMP+CUDA that splits work (CPU threads process rows while GPU processes diagonals) with overlapping transfers.
- Add more extensive correctness tests and automated performance plots (CSV -> PDF/PNG) and a final report PDF following course guidelines.

---

If you want, I can now:
- Run full benchmarks on Colab (CUDA) and provide a results notebook + plots, or
- Implement streaming/banded CUDA and a true hybrid OpenMP+CUDA.

Tell me which of the above you want next and I'll proceed. 