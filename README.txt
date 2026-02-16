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
1. Sequential (Standard DP and Hirschberg linear-space validation)
2. OpenMP (Shared Memory - Wavefront approach with optimized 3-buffer rows)
3. MPI (Message Passing - Stripe decomposition for distributed memory)
4. CUDA (GPU - Anti-diagonal kernel with dynamic block size)

================================================================================
PROJECT STRUCTURE
================================================================================
- inc/        : Header files (lcs.h)
- src/        : Source code (lcs_seq.c, lcs_omp.c, lcs_mpi.c, lcs_cuda.cu, lcs_core.c, lcs_hirschberg.c)
- data/       : Input generator script (generate_input.py)
- build/      : Compiled binaries (created after make)
- tests/      : Test infrastructure
    - run_tests.sh : Main validation script
    - h_test.c     : Unit test for Hirschberg implementation
- scripts/    : Benchmark orchestration
    - benchmark.sh : Main performance test script
    - verify.sh    : Output correctness verifier
- bench_results.csv : Raw results of the performance evaluation
- cudaLCS.ipynb     : Jupyter Notebook for CUDA execution on Google Colab
- grafici LCS.ipynb : Python notebook for data analysis and plotting

================================================================================
COMPILATION (LOCAL ENVIRONMENT)
================================================================================
Prerequisites: GCC (with OpenMP), MPICH/OpenMPI, Python 3.
Optional: NVCC (NVIDIA Cuda Toolkit) for local GPU compilation.

To compile all CPU versions (Seq, OMP, MPI):
    make

To clean build files:
    make clean

NOTE ON CUDA COMPILATION:
The Makefile attempts to compile 'lcs_cuda' using 'nvcc'. 
If 'nvcc' is not found on your system, the CUDA compilation will fail/skip, 
but CPU binaries (lcs_seq, lcs_omp, lcs_mpi) will still be generated correctly.

================================================================================
EXECUTION & REPRODUCIBILITY
================================================================================

1. GENERATE INPUTS
   Use the python script to generate random sequences.
   Example (1MB):
   python3 data/generate_input.py --size-per-file 1048576 --prefix data/test1MB --seed 42

2. RUNNING BINARIES (CPU)
   - Sequential: ./build/lcs_seq data/bench_1MB_A.bin data/bench_1MB_B.bin
   - OpenMP:     ./build/lcs_omp data/bench_1MB_A.bin data/bench_1MB_B.bin <num_threads>
   - MPI:        mpirun -np <procs> ./build/lcs_mpi data/bench_1MB_A.bin data/bench_1MB_B.bin

3. RUNNING CUDA (GOOGLE COLAB)
   Since a local GPU was not available, CUDA benchmarks were performed on 
   Google Colab (Tesla T4).
   - File: cudaLCS.ipynb
   - Usage: 
     1. Upload 'cudaLCS.ipynb' to Google Colab.
     2. Upload the input generator script ('data/generate_input.py') to the 
        Colab session storage (root folder).
     3. (Optional) Upload 'src/lcs_cuda.cu' if the notebook does not contain 
        the inline code cell.
     4. Run all cells. The notebook handles compilation and execution automatically.

4. VERIFY CORRECTNESS
   To run a quick regression test (comparing Parallel output vs Sequential):
   make test (or ./scripts/verify.sh)

5. REPRODUCE BENCHMARKS (CPU)
   To reproduce the measurements presented in the report:
   ./scripts/benchmark.sh
   
   Note: The script automatically generates inputs and runs benchmarks for 
   sizes 10KB, 50KB, 100KB, 200KB, and 1MB.
   Results are saved in 'bench_results.csv'.

================================================================================
NOTE ON TEST SIZES & COMPLEXITY
================================================================================
The project requirements mention testing structures up to 1GB.
However, due to the O(N^2) complexity of the LCS algorithm:
- 1MB input (N=10^6) takes ~30 minutes on a single node (Sequential).
- 10MB input (N=10^7) would theoretically take ~50 hours (100x time).
- 1GB input would take years on a single node.

Therefore, performance benchmarks in this report are limited to 1MB size 
for feasibility. The MPI implementation is technically designed to handle larger 
sizes by distributing memory across nodes (Domain Decomposition), but execution 
time on a single workstation remains prohibitive for sizes > 1MB.

The CUDA implementation uses a Full Matrix approach (O(N^2) space) to maximize 
parallelism, so it is limited by VRAM capacity (approx. 50KB input limit on T4).
The CPU implementations (OpenMP/MPI) use Space Optimization (O(N) space), 
allowing 1MB+ inputs.