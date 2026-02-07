/*
 * GPLv3
 * CUDA LCS - placeholder / host-side stub
 * Full GPU implementation (anti-diagonals or banded DP) is provided in the Colab notebook
 * Student: <Your Name>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cuda.h>

static inline void cuda_check(cudaError_t e, const char *msg) {
    if (e != cudaSuccess) { fprintf(stderr, "%s: %s\n", msg, cudaGetErrorString(e)); exit(1); }
}

// matrix stored row-major with (m+1) columns per row
__global__ void diag_kernel(int *dmat, const char *A, const char *B, int n, int m, int k) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int i_start = max(1, k - m);
    int i_end = min(n, k - 1);
    int len = i_end - i_start + 1;
    if (idx >= len) return;
    int i = i_start + idx;
    int j = k - i;
    int mcols = m + 1;
    int up = dmat[(i-1)*mcols + j];
    int left = dmat[i*mcols + (j-1)];
    int upleft = dmat[(i-1)*mcols + (j-1)];
    if (A[i-1] == B[j-1]) dmat[i*mcols + j] = upleft + 1;
    else dmat[i*mcols + j] = (up > left ? up : left);
}

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "Usage: %s fileA fileB [--print-seq]\n", argv[0]); return 1; }
    const char *fileA = argv[1];
    const char *fileB = argv[2];
    int print_seq = 0; if (argc > 3 && strcmp(argv[3], "--print-seq") == 0) print_seq = 1;
    FILE *fa = fopen(fileA, "rb"); FILE *fb = fopen(fileB, "rb"); if (!fa || !fb) { perror("fopen"); return 1; }
    fseek(fa,0,SEEK_END); int n = ftell(fa); fseek(fa,0,SEEK_SET);
    fseek(fb,0,SEEK_END); int m = ftell(fb); fseek(fb,0,SEEK_SET);
    char *hA = (char*)malloc(n); char *hB = (char*)malloc(m);
    if (!hA || !hB) { fprintf(stderr, "alloc fail\n"); return 1; }
    fread(hA, 1, n, fa); fread(hB, 1, m, fb); fclose(fa); fclose(fb);

    size_t mat_elems = (size_t)(n + 1) * (m + 1);
    size_t mat_bytes = mat_elems * sizeof(int);
    int *hmat = (int*)malloc(mat_bytes);
    if (!hmat) { fprintf(stderr, "host mat alloc fail (size %zu)\n", mat_bytes); return 1; }
    memset(hmat, 0, mat_bytes);

    char *dA; char *dB; int *dmat;
    cuda_check(cudaMalloc((void**)&dA, n), "cudaMalloc A");
    cuda_check(cudaMalloc((void**)&dB, m), "cudaMalloc B");
    cuda_check(cudaMalloc((void**)&dmat, mat_bytes), "cudaMalloc mat");
    cuda_check(cudaMemcpy(dA, hA, n, cudaMemcpyHostToDevice), "cpy A");
    cuda_check(cudaMemcpy(dB, hB, m, cudaMemcpyHostToDevice), "cpy B");
    cuda_check(cudaMemcpy(dmat, hmat, mat_bytes, cudaMemcpyHostToDevice), "cpy mat");

    int maxk = n + m;
    for (int k = 2; k <= maxk; ++k) {
        int i_start = (k > m+1) ? (k - (m+1)) : 1;
        int i_end = (k - 1 > n) ? n : k - 1;
        int len = i_end - i_start + 1;
        if (len <= 0) continue;
        int threads = 256;
        int blocks = (len + threads - 1) / threads;
        diag_kernel<<<blocks, threads>>>(dmat, dA, dB, n, m, k);
        cuda_check(cudaGetLastError(), "kernel");
        cuda_check(cudaDeviceSynchronize(), "sync");
    }

    cuda_check(cudaMemcpy(hmat, dmat, mat_bytes, cudaMemcpyDeviceToHost), "cpy back");
    int res = hmat[n*(m+1) + m];
    printf("LCS length = %d\n", res);

    if (print_seq) {
        int len = res;
        char *seq = malloc(len + 1);
        seq[len] = '\0';
        int i=n, j=m; int p = len - 1;
        while (i > 0 && j > 0) {
            if (hA[i-1] == hB[j-1]) { seq[p--] = hA[i-1]; i--; j--; }
            else if (hmat[(i-1)*(m+1) + j] >= hmat[i*(m+1) + (j-1)]) i--;
            else j--;
        }
        printf("LCS seq: %s\n", seq);
        free(seq);
    }

    cudaFree(dA); cudaFree(dB); cudaFree(dmat);
    free(hA); free(hB); free(hmat);
    return 0;
}
