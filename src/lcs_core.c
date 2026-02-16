/*
 * Assignment: Longest Common Subsequence (HPC Project)
 * Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
 * Lecturer: Moscato Francesco, fmoscato@unisa.it
 *
 * License: GPLv3 (see LICENSE file)
 * Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
 * Purpose: Funzioni core condivise (allocazione matrice, logica DP base) utilizzate dalle implementazioni sequenziali e parallele.
 */
 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../inc/lcs.h"

int lcs_length_dp(const char *a, size_t n, const char *b, size_t m) {
    if (n == 0 || m == 0) return 0;
    int *prev = calloc(m + 1, sizeof(int));
    int *cur = calloc(m + 1, sizeof(int));
    if (!prev || !cur) { fprintf(stderr, "Allocation failed\n"); exit(1); }
    for (size_t i = 1; i <= n; ++i) {
        for (size_t j = 1; j <= m; ++j) {
            if (a[i-1] == b[j-1]) cur[j] = prev[j-1] + 1;
            else cur[j] = (prev[j] > cur[j-1]) ? prev[j] : cur[j-1];
        }
        int *tmp = prev; prev = cur; cur = tmp;
    }
    int res = prev[m];
    free(prev); free(cur);
    return res;
}

char *lcs_sequence_dp(const char *a, size_t n, const char *b, size_t m, size_t *out_len) {
    if (n == 0 || m == 0) { *out_len = 0; return NULL; }
    int *mat = calloc((n+1)*(m+1), sizeof(int));
    if (!mat) { fprintf(stderr, "Allocation failed\n"); exit(1); }
    #define IDX(i,j) ((i)*(m+1)+(j))
    for (size_t i = 1; i <= n; ++i) {
        for (size_t j = 1; j <= m; ++j) {
            if (a[i-1] == b[j-1]) mat[IDX(i,j)] = mat[IDX(i-1,j-1)] + 1;
            else mat[IDX(i,j)] = (mat[IDX(i-1,j)] > mat[IDX(i,j-1)]) ? mat[IDX(i-1,j)] : mat[IDX(i,j-1)];
        }
    }
    int len = mat[IDX(n,m)];
    char *res = malloc(len + 1);
    res[len] = '\0';
    size_t i = n, j = m; int p = len - 1;
    while (i > 0 && j > 0) {
        if (a[i-1] == b[j-1]) { res[p--] = a[i-1]; i--; j--; }
        else if (mat[IDX(i-1,j)] >= mat[IDX(i,j-1)]) i--;
        else j--;
    }
    *out_len = len;
    free(mat);
    return res;
}
