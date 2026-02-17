/*
 * Assignment: Longest Common Subsequence (HPC Project)
 * Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
 * Lecturer: Moscato Francesco, fmoscato@unisa.it
 *
 * License: GPLv3 (see LICENSE file)
 * Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
 * Purpose: Implementazione parallela su GPU (CUDA) con supporto Large Matrix (size_t).
 * UPDATED: Dynamic block size & Correct Timing & Fixed Integer Overflow.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cuda.h>
#include <cuda_runtime.h>

static inline void cuda_check(cudaError_t e, const char *msg) {
    if (e != cudaSuccess) { fprintf(stderr, "%s: %s\n", msg, cudaGetErrorString(e)); exit(1); }
}

// Kernel: calcola una anti-diagonale
// FIX: Utilizza size_t per gestire matrici con più di 2 miliardi di celle totali
__global__ void diag_kernel(int *dmat, const char *A, const char *B, int n, int m, int k) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    // Calcolo indici i, j basati sulla diagonale k
    int i_start = max(1, k - m);
    int i_end = min(n, k - 1);
    int len = i_end - i_start + 1;

    if (idx >= len) return;

    int i = i_start + idx;
    int j = k - i;

    // FIX: Usiamo size_t per la larghezza e per il calcolo dell'indice
    // Altrimenti n*m con n,m > 46000 supera il limite dei 32 bit (2 miliardi)
    size_t mcols = (size_t)m + 1;

    // Calcolo indici con size_t per evitare overflow
    size_t idx_cur    = (size_t)i * mcols + j;
    size_t idx_up     = (size_t)(i-1) * mcols + j;
    size_t idx_left   = (size_t)i * mcols + (j-1);
    size_t idx_upleft = (size_t)(i-1) * mcols + (j-1);

    // Nota: A e B sono 0-indexed, la matrice DP è 1-indexed
    if (A[i-1] == B[j-1]) {
        dmat[idx_cur] = dmat[idx_upleft] + 1;
    } else {
        int up = dmat[idx_up];
        int left = dmat[idx_left];
        dmat[idx_cur] = (up > left ? up : left);
    }
}

int main(int argc, char **argv) {
    if (argc < 3) { 
        fprintf(stderr, "Usage: %s fileA fileB [blockSize]\n", argv[0]);
        return 1; 
    }

    const char *fileA = argv[1];
    const char *fileB = argv[2];
    int blockSize = 256;

    if (argc > 3) blockSize = atoi(argv[3]);
    if (blockSize <= 0) blockSize = 256;

    FILE *fa = fopen(fileA, "rb");
    FILE *fb = fopen(fileB, "rb");
    if (!fa || !fb) { perror("fopen"); return 1; }

    fseek(fa, 0, SEEK_END); int n = ftell(fa); fseek(fa, 0, SEEK_SET);
    fseek(fb, 0, SEEK_END); int m = ftell(fb); fseek(fb, 0, SEEK_SET);

    char *hA = (char*)malloc(n);
    char *hB = (char*)malloc(m);
    if (!hA || !hB) { fprintf(stderr, "Host alloc fail\n"); return 1; }

    if (fread(hA, 1, n, fa) != n || fread(hB, 1, m, fb) != m) { fprintf(stderr, "Read error\n"); return 1; }
    fclose(fa); fclose(fb);

    size_t mat_elems = (size_t)(n + 1) * (m + 1);
    size_t mat_bytes = mat_elems * sizeof(int);

    char *dA; char *dB; int *dmat;
    cuda_check(cudaMalloc((void**)&dA, n), "cudaMalloc A");
    cuda_check(cudaMalloc((void**)&dB, m), "cudaMalloc B");
    cuda_check(cudaMalloc((void**)&dmat, mat_bytes), "cudaMalloc mat");

    cuda_check(cudaMemcpy(dA, hA, n, cudaMemcpyHostToDevice), "cpy A");
    cuda_check(cudaMemcpy(dB, hB, m, cudaMemcpyHostToDevice), "cpy B");
    cuda_check(cudaMemset(dmat, 0, mat_bytes), "memset mat");

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    int maxk = n + m;
    for (int k = 2; k <= maxk; ++k) {
        int i_start = (k > m+1) ? (k - (m+1)) : 1;
        int i_end = (k - 1 > n) ? n : k - 1;
        int len = i_end - i_start + 1;

        if (len <= 0) continue;
        int threads = blockSize;
        int blocks = (len + threads - 1) / threads;
        diag_kernel<<<blocks, threads>>>(dmat, dA, dB, n, m, k);
    }
    cuda_check(cudaGetLastError(), "kernel launch");

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    int res = 0;
    // Fix indice anche qui per il recupero del risultato
    size_t res_idx = (size_t)n * (m + 1) + m;
    cuda_check(cudaMemcpy(&res, &dmat[res_idx], sizeof(int), cudaMemcpyDeviceToHost), "cpy result");

    printf("RESULT_LEN: %d\n", res);
    printf("ELAPSED_TIME: %.6f\n", milliseconds / 1000.0f);

    cudaFree(dA); cudaFree(dB); cudaFree(dmat);
    free(hA); free(hB);
    cudaEventDestroy(start); cudaEventDestroy(stop);
    return 0;
}