/*
 * Assignment: Longest Common Subsequence (HPC Project)
 * Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
 * Lecturer: Moscato Francesco, fmoscato@unisa.it
 *
 * License: GPLv3 (see LICENSE file)
 * Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
 * Purpose: Stub per l'esecuzione ibrida OpenMP/CUDA (wrapper host-side per invocare il kernel GPU).
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "Usage: %s fileA fileB [threads]\n", argv[0]); return 1; }
    int threads = 1; if (argc > 3) threads = atoi(argv[3]);
    omp_set_num_threads(threads);
    /* Placeholder: call the CUDA binary if present */
    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "./build/lcs_cuda %s %s", argv[1], argv[2]);
    int rc = system(cmd);
    return rc;
}
