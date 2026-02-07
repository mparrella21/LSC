/*
 * GPLv3
 * Project: LCS - High Performance Computing assignment
 * Student: <Your Name, ID, email>
 * Lecturer: <Course Lecturer>
 * Purpose: Declarations for LCS implementations (sequential, Hirschberg, OpenMP, MPI, CUDA)
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
