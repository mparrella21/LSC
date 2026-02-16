/*
 * Assignment: Longest Common Subsequence (HPC Project)
 * Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
 * Lecturer: Moscato Francesco, fmoscato@unisa.it
 *
 * License: GPLv3 (see LICENSE file)
 * Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
 * Purpose: Implementazione dell'algoritmo di Hirschberg per calcolare la LCS con complessità spaziale lineare O(min(n,m)).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../inc/lcs.h"

static int *lcs_score(const char *a, size_t n, const char *b, size_t m) {
    int *prev = calloc(m+1, sizeof(int));
    int *cur = calloc(m+1, sizeof(int));
    if (!prev || !cur) { fprintf(stderr, "Allocation failed\n"); exit(1); }
    for (size_t i = 1; i <= n; ++i) {
        for (size_t j = 1; j <= m; ++j) {
            if (a[i-1] == b[j-1]) cur[j] = prev[j-1] + 1;
            else cur[j] = (prev[j] > cur[j-1]) ? prev[j] : cur[j-1];
        }
        int *tmp = prev; prev = cur; cur = tmp;
    }
    free(cur);
    return prev; /* caller must free */
}

/* returns LCS of a and b as malloc'd string, sets out_len */
char *lcs_sequence_hirschberg(const char *a, size_t n, const char *b, size_t m, size_t *out_len) {
    if (n == 0 || m == 0) { *out_len = 0; return NULL; }
    if (n == 1) {
        for (size_t j = 0; j < m; ++j) if (a[0] == b[j]) {
            char *r = malloc(2); r[0] = a[0]; r[1] = '\0'; *out_len = 1; return r; }
        *out_len = 0; return NULL;
    }
    size_t i = n/2;
    int *lscore = lcs_score(a, i, b, m);
    int *rscore = lcs_score(a + i, n - i, b, m);
    /* find split k maximizing lscore[k] + rscore_rev[k] */
    size_t k = 0; int best = -1;
    for (size_t j = 0; j <= m; ++j) {
        int val = lscore[j] + rscore[m - j];
        if (val > best) { best = val; k = j; }
    }
    free(lscore); free(rscore);
    size_t left_len; char *left = lcs_sequence_hirschberg(a, i, b, k, &left_len);
    size_t right_len; char *right = lcs_sequence_hirschberg(a + i, n - i, b + k, m - k, &right_len);
    char *res = malloc(left_len + right_len + 1);
    if (left_len) memcpy(res, left, left_len);
    if (right_len) memcpy(res + left_len, right, right_len);
    res[left_len + right_len] = '\0';
    *out_len = left_len + right_len;
    free(left); free(right);
    return res;
}
