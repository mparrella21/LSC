/*
 * GPLv3
 * OpenMP (shared memory) LCS - wavefront/anti-diagonal parallelization for length
 * Student: <Your Name>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include "../inc/lcs.h"

int lcs_length_omp(const char *a, size_t n, const char *b, size_t m) {
    if (n == 0 || m == 0) return 0;
    /* We'll compute anti-diagonals: for k from 2 to n+m, the cells (i,j) with i+j=k */
    int *prev = calloc(m + 1, sizeof(int));
    int *cur = calloc(m + 1, sizeof(int));
    if (!prev || !cur) { fprintf(stderr, "Allocation failed\n"); exit(1); }
    for (size_t k = 2; k <= n + m; ++k) {
        size_t i_start = (k > m+1) ? (k - (m+1)) : 1;
        size_t i_end = (k - 1 > n) ? n : k - 1;
        #pragma omp parallel for schedule(static)
        for (long ii = (long)i_start; ii <= (long)i_end; ++ii) {
            size_t i = (size_t)ii;
            size_t j = k - i;
            if (a[i-1] == b[j-1]) cur[j] = prev[j-1] + 1;
            else cur[j] = (prev[j] > cur[j-1]) ? prev[j] : cur[j-1];
        }
        int *tmp = prev; prev = cur; cur = tmp;
    }
    int res = prev[m];
    free(prev); free(cur);
    return res;
}

/* Simple CLI: lcs_omp fileA fileB [threads] [--print-seq]
*/
int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "Usage: %s fileA fileB [threads] [--print-seq]\n", argv[0]); return 1; }
    const char *fa = argv[1]; const char *fb = argv[2];
    int threads = 1; int print_seq = 0;
    for (int i = 3; i < argc; ++i) {
        if (strcmp(argv[i], "--print-seq") == 0) print_seq = 1;
        else threads = atoi(argv[i]);
    }
    FILE *f1 = fopen(fa, "rb"); FILE *f2 = fopen(fb, "rb"); if (!f1 || !f2) { perror("fopen"); return 1; }
    fseek(f1, 0, SEEK_END); size_t n = ftell(f1); fseek(f1, 0, SEEK_SET);
    fseek(f2, 0, SEEK_END); size_t m = ftell(f2); fseek(f2, 0, SEEK_SET);
    char *a = malloc(n); char *b = malloc(m); fread(a,1,n,f1); fread(b,1,m,f2); fclose(f1); fclose(f2);
    omp_set_num_threads(threads);
    double t0 = omp_get_wtime();
    int len = lcs_length_omp(a, n, b, m);
    double t1 = omp_get_wtime();
    printf("LCS length = %d\n", len);
    printf("Time: %.3f s (threads=%d)\n", t1 - t0, threads);
    if (print_seq) {
        size_t out; char *s = lcs_sequence_dp(a, n, b, m, &out);
        if (s) { printf("LCS seq: %s\n", s); free(s); }
    }
    free(a); free(b);
    return 0;
}
