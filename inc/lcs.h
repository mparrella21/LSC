/*
 * Assignment: Longest Common Subsequence (HPC Project)
 * Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
 * Lecturer: Moscato Francesco, fmoscato@unisa.it
 *
 * License: GPLv3 (see LICENSE file)
 * Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
 * Purpose: Header file che definisce le strutture dati comuni, i prototipi delle funzioni e le costanti del progetto.
 */
 
#ifndef LCS_H
#define LCS_H

#include <stddef.h>

/* Compute length of LCS using standard DP (returns length). */
int lcs_length_dp(const char *a, size_t n, const char *b, size_t m);

/* Compute LCS sequence using full DP (allocates O(n*m) memory). Caller frees returned string. */
char *lcs_sequence_dp(const char *a, size_t n, const char *b, size_t m, size_t *out_len);

/* Hirschberg memory-optimized LCS: computes sequence. Caller frees returned string. */
char *lcs_sequence_hirschberg(const char *a, size_t n, const char *b, size_t m, size_t *out_len);

#endif /* LCS_H */
