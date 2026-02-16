/*
 * Assignment: Longest Common Subsequence (HPC Project)
 * Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
 * Lecturer: Moscato Francesco, fmoscato@unisa.it
 *
 * License: GPLv3 (see LICENSE file)
 * Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
 * Purpose: Implementazione parallela Shared Memory (OpenMP) con approccio wavefront (anti-diagonale) ottimizzato nello spazio (3 buffer).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include "../inc/lcs.h"

int lcs_length_omp(const char *a, size_t n, const char *b, size_t m) {
    if (n == 0 || m == 0) return 0;
    
    // Servono 3 buffer per le dipendenze:
    // cur (k), prev (k-1), prev_prev (k-2)
    // Usiamo calloc per garantire che i bordi (indice 0) siano 0.
    int *pp = calloc(m + 1, sizeof(int)); // k-2
    int *p  = calloc(m + 1, sizeof(int)); // k-1
    int *c  = calloc(m + 1, sizeof(int)); // k
    
    if (!pp || !p || !c) { fprintf(stderr, "Allocation failed\n"); exit(1); }
    
    // Ciclo sulle anti-diagonali k = i + j
    // Range: da 2 (cella 1,1) a n+m (cella n,m)
    for (size_t k = 2; k <= n + m; ++k) {
        
        // Determina il range di i valido per questa diagonale
        size_t i_start = (k > m + 1) ? (k - (m + 1)) : 1;
        size_t i_end   = (k - 1 > n) ? n : k - 1;
        
        #pragma omp parallel for schedule(static)
        for (long ii = (long)i_start; ii <= (long)i_end; ++ii) {
            size_t i = (size_t)ii;
            size_t j = k - i;
            
            // Logica LCS:
            // Se caratteri uguali: 1 + cella[i-1][j-1] (che sta in pp[j-1])
            // Altrimenti: max(cella[i][j-1], cella[i-1][j]) (che stanno in p[j-1] e p[j])
            
            if (a[i-1] == b[j-1]) {
                c[j] = pp[j-1] + 1;
            } else {
                int up = p[j];      // Corrisponde logicamente a (i-1, j) nella diag precedente
                int left = p[j-1];  // Corrisponde logicamente a (i, j-1) nella diag precedente
                c[j] = (up > left) ? up : left;
            }
        }
        
        // Rotazione puntatori:
        // pp diventa il vecchio p
        // p diventa il vecchio c (che ora è calcolato)
        // c diventa il vecchio pp (buffer da riciclare per la prossima k)
        int *tmp = pp;
        pp = p;
        p = c;
        c = tmp;
    }
    
    // Il risultato finale si trova in p[m] perché abbiamo fatto lo swap alla fine del ciclo
    int res = p[m];
    
    free(pp); free(p); free(c);
    return res;
}

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "Usage: %s fileA fileB [threads] [--print-seq]\n", argv[0]); return 1; }
    
    const char *fa = argv[1]; 
    const char *fb = argv[2];
    int threads = 1; 
    
    for (int i = 3; i < argc; ++i) {
        if (strcmp(argv[i], "--print-seq") == 0) { /* ignore */ }
        else threads = atoi(argv[i]);
    }
    
    if (threads < 1) threads = 1;
    omp_set_num_threads(threads);

    FILE *f1 = fopen(fa, "rb"); 
    FILE *f2 = fopen(fb, "rb"); 
    if (!f1 || !f2) { perror("fopen"); return 1; }
    
    fseek(f1, 0, SEEK_END); size_t n = ftell(f1); fseek(f1, 0, SEEK_SET);
    fseek(f2, 0, SEEK_END); size_t m = ftell(f2); fseek(f2, 0, SEEK_SET);
    
    char *A = malloc(n+1); 
    char *B = malloc(m+1);
    if (!A || !B) { fprintf(stderr, "Malloc failed\n"); return 1; }
    
    if (fread(A, 1, n, f1) != n || fread(B, 1, m, f2) != m) { fprintf(stderr, "Read failed\n"); return 1; }
    A[n] = 0; B[m] = 0;
    fclose(f1); fclose(f2);

    // Timer START
    double start_time = omp_get_wtime();
    
    // Calcolo
    int len = lcs_length_omp(A, n, B, m);
    
    // Timer END
    double end_time = omp_get_wtime();
    
    printf("RESULT_LEN: %d\n", len);
    printf("ELAPSED_TIME: %.6f\n", end_time - start_time);

    free(A); free(B);
    return 0;
}