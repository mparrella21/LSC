/*
 * Assignment: Longest Common Subsequence (HPC Project)
 * Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
 * Lecturer: Moscato Francesco, fmoscato@unisa.it
 *
 * License: GPLv3 (see LICENSE file)
 * Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
 * Purpose: Implementazione parallela a Memoria Distribuita (MPI) con decomposizione a strisce (stripes) per gestire input di grandi dimensioni.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mpi.h>
#include "../inc/lcs.h"

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    int rank, size; 
    MPI_Comm_rank(MPI_COMM_WORLD, &rank); 
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // --- 1. PARSING E SETUP (Non misurato) ---
    if (argc < 3) { 
        if (rank==0) fprintf(stderr, "Usage: %s fileA fileB [--print-seq]\n", argv[0]); 
        MPI_Finalize(); 
        return 1; 
    }

    char *A = NULL, *B = NULL; 
    size_t n=0, m=0;

    // Solo Rank 0 legge i file dal disco
    if (rank == 0) {
        FILE *fa = fopen(argv[1], "rb"); 
        FILE *fb = fopen(argv[2], "rb"); 
        if (!fa || !fb) { 
            perror("fopen"); 
            MPI_Abort(MPI_COMM_WORLD, 1); 
        }
        
        fseek(fa, 0, SEEK_END); n = ftell(fa); fseek(fa, 0, SEEK_SET);
        fseek(fb, 0, SEEK_END); m = ftell(fb); fseek(fb, 0, SEEK_SET);
        
        A = malloc(n); 
        B = malloc(m);
        if (!A || !B) { fprintf(stderr, "Malloc A/B failed on rank 0\n"); MPI_Abort(MPI_COMM_WORLD, 1); }

        if (fread(A, 1, n, fa) != n || fread(B, 1, m, fb) != m) {
             fprintf(stderr, "Read failed\n"); MPI_Abort(MPI_COMM_WORLD, 1);
        }
        fclose(fa); fclose(fb);
    }

    // Distribuzione dimensioni
    MPI_Bcast(&n, 1, MPI_UNSIGNED_LONG, 0, MPI_COMM_WORLD);
    MPI_Bcast(&m, 1, MPI_UNSIGNED_LONG, 0, MPI_COMM_WORLD);

    // Allocazione sugli altri rank
    if (rank != 0) { 
        A = malloc(n); 
        B = malloc(m); 
        if (!A || !B) { fprintf(stderr, "Malloc A/B failed on rank %d\n", rank); MPI_Abort(MPI_COMM_WORLD, 1); }
    }

    // Distribuzione dati (Heavy I/O part - ancora NON misurata)
    MPI_Bcast(A, n, MPI_CHAR, 0, MPI_COMM_WORLD);
    MPI_Bcast(B, m, MPI_CHAR, 0, MPI_COMM_WORLD);

    // Allocazione buffer DP (parte della preparazione)
    int *prev = calloc(m + 1, sizeof(int));
    int *cur = calloc(m + 1, sizeof(int));
    if (!prev || !cur) { fprintf(stderr, "Allocation DP failed\n"); MPI_Abort(MPI_COMM_WORLD, 1); }

    // Calcolo porzione di lavoro (Stripe)
    size_t base = n / size; 
    size_t rem = n % size;
    size_t start = rank * base + (rank < rem ? rank : rem) + 1; // 1-based row index
    size_t count = base + (rank < rem ? 1 : 0);
    size_t end = start + count - 1;

    // --- 2. INIZIO MISURAZIONE (Solo Calcolo) ---
    // Barriera fondamentale: assicura che tutti abbiano finito di ricevere i dati e allocare
    MPI_Barrier(MPI_COMM_WORLD); 
    double start_time = MPI_Wtime();

    // Se questo rank non ha lavoro, salta il loop
    if (count > 0) {
        // Se non sono il primo rank, devo ricevere la riga precedente dal rank (i-1)
        if (rank > 0) {
            MPI_Recv(prev, m + 1, MPI_INT, rank - 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        }

        // Loop di calcolo (CORE ALGORITHM)
        for (size_t i = start; i <= end; ++i) {
            for (size_t j = 1; j <= m; ++j) {
                if (A[i-1] == B[j-1]) cur[j] = prev[j-1] + 1;
                else cur[j] = (prev[j] > cur[j-1]) ? prev[j] : cur[j-1];
            }
            // Swap puntatori
            int *tmp = prev; prev = cur; cur = tmp;
        }

        // Se non sono l'ultimo rank, invio la mia ultima riga al rank (i+1)
        if (rank < size - 1) {
            MPI_Send(prev, m + 1, MPI_INT, rank + 1, 0, MPI_COMM_WORLD);
        }
    }

    // --- 3. FINE MISURAZIONE ---
    // Barriera per aspettare che l'ultimo rank finisca (visto che è pipeline)
    MPI_Barrier(MPI_COMM_WORLD);
    double end_time = MPI_Wtime();

    // --- 4. GESTIONE RISULTATO ---
    // L'ultimo rank ha il risultato finale in prev[m]
    int final_len = 0;
    int local_len = prev[m]; // Valido solo per rank == size-1

    if (rank == size - 1) {
        if (size == 1) {
            final_len = local_len;
        } else {
            // Invia il risultato al Rank 0 per la stampa pulita
            MPI_Send(&local_len, 1, MPI_INT, 0, 999, MPI_COMM_WORLD);
        }
    }

    if (rank == 0) {
        if (size > 1) {
            MPI_Recv(&final_len, 1, MPI_INT, size - 1, 999, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        } else {
            final_len = local_len;
        }
        
        // STAMPA FORMATTATA PER BENCHMARK
        printf("RESULT_LEN: %d\n", final_len);
        printf("ELAPSED_TIME: %.6f\n", end_time - start_time);
    }

    // Cleanup
    free(prev); free(cur); free(A); free(B);
    MPI_Finalize();
    return 0;
}