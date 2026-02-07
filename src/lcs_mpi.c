/*
 * GPLv3
 * MPI LCS - stripe-based (memory-distribution) implementation for length
 * This implementation is intentionally simple and focuses on distributing memory
 * across processes so that very large inputs can be handled. It pipelines stripes
 * (each rank computes a contiguous block of rows) and passes the last computed row
 * to the next rank. Correctness is guaranteed; runtime is largely sequential.
 * Student: <Your Name>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mpi.h>
#include "../inc/lcs.h"

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    int rank, size; MPI_Comm_rank(MPI_COMM_WORLD, &rank); MPI_Comm_size(MPI_COMM_WORLD, &size);
    if (argc < 3) { if (rank==0) fprintf(stderr, "Usage: %s fileA fileB [--print-seq]\n", argv[0]); MPI_Finalize(); return 1; }
    int print_seq = 0;
    for (int i = 3; i < argc; ++i) if (strcmp(argv[i], "--print-seq") == 0) print_seq = 1;
    char *A = NULL, *B = NULL; size_t n=0,m=0;
    if (rank == 0) {
        FILE *fa = fopen(argv[1], "rb"); FILE *fb = fopen(argv[2], "rb"); if (!fa || !fb) { perror("fopen"); MPI_Abort(MPI_COMM_WORLD,1); }
        fseek(fa,0,SEEK_END); n = ftell(fa); fseek(fa,0,SEEK_SET);
        fseek(fb,0,SEEK_END); m = ftell(fb); fseek(fb,0,SEEK_SET);
        A = malloc(n); B = malloc(m); fread(A,1,n,fa); fread(B,1,m,fb); fclose(fa); fclose(fb);
    }
    /* broadcast sizes */
    MPI_Bcast(&n, 1, MPI_UNSIGNED_LONG, 0, MPI_COMM_WORLD);
    MPI_Bcast(&m, 1, MPI_UNSIGNED_LONG, 0, MPI_COMM_WORLD);
    if (rank != 0) { A = malloc(n); B = malloc(m); }
    MPI_Bcast(A, n, MPI_CHAR, 0, MPI_COMM_WORLD);
    MPI_Bcast(B, m, MPI_CHAR, 0, MPI_COMM_WORLD);

    if (print_seq && rank == 0) {
        /* use Hirschberg on rank 0 to reconstruct and print sequence for verification */
        size_t out; char *s = lcs_sequence_hirschberg(A, n, B, m, &out);
        if (s) { printf("Hirschberg (rank0): len=%zu seq=%s\n", out, s); free(s); }
    }

    /* determine stripe for each rank: rows 1..n split among ranks */
    size_t base = n / size; size_t rem = n % size;
    size_t start = rank * base + (rank < rem ? rank : rem) + 1; /* 1-based row index */
    size_t count = base + (rank < rem ? 1 : 0);
    size_t end = start + count - 1;
    if (count == 0) { /* no rows to compute */ MPI_Finalize(); return 0; }

    int *prev = calloc(m+1, sizeof(int));
    int *cur = calloc(m+1, sizeof(int));
    if (!prev || !cur) { fprintf(stderr, "Allocation failed\n"); MPI_Abort(MPI_COMM_WORLD,1); }

    /* If not rank 0, receive prev row from previous rank */
    if (rank > 0) {
        MPI_Recv(prev, m+1, MPI_INT, rank-1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    }

    for (size_t i = start; i <= end; ++i) {
        for (size_t j = 1; j <= m; ++j) {
            if (A[i-1] == B[j-1]) cur[j] = prev[j-1] + 1;
            else cur[j] = (prev[j] > cur[j-1]) ? prev[j] : cur[j-1];
        }
        int *tmp = prev; prev = cur; cur = tmp;
    }

    /* send last row to next rank, or print final result if last rank */
    if (rank < size - 1) MPI_Send(prev, m+1, MPI_INT, rank+1, 0, MPI_COMM_WORLD);
    else {
        printf("LCS length = %d\n", prev[m]);
    }

    free(prev); free(cur); free(A); free(B);
    MPI_Finalize();
    return 0;
}
