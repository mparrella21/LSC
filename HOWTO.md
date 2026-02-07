# HOWTO - LCS HPC Project

Quick instructions:

Build all:
  make

Run small tests:
  bash tests/run_tests.sh

Generate inputs of required sizes:
  python3 data/generate_input.py --size-per-file 1048576 --prefix data/1MB
  python3 data/generate_input.py --size-per-file 10485760 --prefix data/10MB
  python3 data/generate_input.py --size-per-file 104857600 --prefix data/100MB
  python3 data/generate_input.py --size-per-file 524288000 --prefix data/500MB

Benchmarks (single node, may be slow):
  bash scripts/benchmark.sh

MPI notes (WSL):
- Ensure OpenMPI or MPICH is installed and in PATH (mpirun).
- Use `mpirun -np <P> build/lcs_mpi <A> <B> [--print-seq]` to run with P processes. The implementation pipelines stripes; it is memory-distribution oriented. Use `--print-seq` to have rank 0 reconstruct and print the LCS using Hirschberg (good for correctness checks on small inputs).

CUDA notes (Colab):
- Open `cuda_lcs_colab.ipynb` in Google Colab with GPU runtime and follow the cells to compile and run the kernel.
- You can also compile `src/lcs_cuda.cu` directly with `nvcc` and run `./lcs_cuda A B [--print-seq]` (note that `--print-seq` copies the full matrix back to host for backtracking).

Hybrid note:
- `build/lcs_omp_cuda` is a simple host-side wrapper that calls the CUDA binary and demonstrates a hybrid invocation pattern (host threads + GPU). It's a starting point for further hybrid developments.

Reproducibility:
- The generator supports `--seed` to reproduce inputs.
- All timings in scripts are wall-clock; scripts use multiple repetitions and store CSV outputs.

License: GPLv3 for source code.
