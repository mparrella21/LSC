/*
 * GPLv3
 * Hybrid stub: calls CUDA binary while optionally using OpenMP on host
 * This is a simple wrapper to demonstrate hybrid execution (real hybrid
 * implementations would mix work between CPU threads and GPU kernels).
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
