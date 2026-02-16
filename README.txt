Assignment: Longest Common Subsequence (HPC Project)
Student: Parrella Marco
Matricola: 0622702536
Email: m.parrella21@studenti.unisa.it
Lecturer: Moscato Francesco (fmoscato@unisa.it)
License: GPLv3 (see LICENSE file)

================================================================================
PROJECT DESCRIPTION
================================================================================
This project implements the Longest Common Subsequence (LCS) algorithm using 
different parallel approaches:
1. Sequential (Standard DP and Hirschberg linear-space)
2. OpenMP (Shared Memory - Wavefront approach with optimized 3-buffer rows)
3. MPI (Message Passing - Stripe decomposition for distributed memory)
4. CUDA (GPU - Anti-diagonal kernel with dynamic block size)

================================================================================
PROJECT STRUCTURE
================================================================================
- inc/       : Header files (lcs.h)
- src/       : Source code (.c, .cu)
- data/      : Input generator script
- build/     : Compiled binaries (created after make)
- tests/     : Test scripts and verification
- scripts/   : Benchmark scripts
- benchmark_results.csv : Results of the performance evaluation

================================================================================
COMPILATION
================================================================================
Prerequisites: GCC (with OpenMP), MPICH/OpenMPI, NVCC (Cuda Toolkit).

To compile all versions:
    make

To clean build files:
    make clean

================================================================================
EXECUTION & REPRODUCIBILITY
================================================================================

1. GENERATE INPUTS
   Use the python script to generate random sequences.
   Example (1MB):
   python3 data/generate_input.py --size-per-file 1048576 --prefix data/test1MB --seed 42

2. RUNNING BINARIES
   - Sequential: ./build/lcs_seq data/A.bin data/B.bin
   - OpenMP:     ./build/lcs_omp data/A.bin data/B.bin <num_threads>
   - MPI:        mpirun -np <procs> ./build/lcs_mpi data/A.bin data/B.bin
   - CUDA:       ./build/lcs_cuda data/A.bin data/B.bin <block_size>

3. VERIFY CORRECTNESS
   To run a quick correctness check (small inputs):
   make test

4. REPRODUCE BENCHMARKS
   To reproduce the measurements presented in the report:
   ./scripts/benchmark.sh
   
   Note: The script automatically generates inputs and runs benchmarks for 
   sizes 10KB, 50KB, 100KB, 200KB, and 1MB.
   Results are saved in 'bench_results.csv'.

================================================================================
NOTE ON TEST SIZES (IMPORTANT)
================================================================================
The project requirements mention testing up to 100MB or 1GB.
However, due to the O(N^2) complexity of the LCS algorithm:
- 1MB input takes ~30 minutes on a single node.
- 10MB input would theoretically take ~50 hours (100x time).

Therefore, performance benchmarks in this report are limited to 1MB size 
for feasibility. The MPI implementation is designed to handle larger sizes 
by distributing memory across nodes, but execution time on a single workstation 
remains prohibitive for sizes > 1MB.

CUDA benchmarks are limited to 50KB due to the full-matrix allocation strategy 
used for maximum parallelism exposure.