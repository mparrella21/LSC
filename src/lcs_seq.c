/*
 * Assignment: Longest Common Subsequence (HPC Project)
 * Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
 * Lecturer: Moscato Francesco, fmoscato@unisa.it
 *
 * License: GPLv3 (see LICENSE file)
 * Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
 * Purpose: Implementazione sequenziale dell'algoritmo LCS (Programmazione Dinamica standard) usata come baseline per i benchmark.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include "../inc/lcs.h"

// Funzione helper per il tempo in secondi (double)
static double get_time_sec() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

/* Core functions are in src/lcs_core.c */

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s fileA fileB [--print-seq]\n", argv[0]);
        return 1;
    }
    const char *fileA = argv[1];
    const char *fileB = argv[2];
    int print_seq = 0;
    if (argc > 3 && strcmp(argv[3], "--print-seq") == 0) print_seq = 1;

    // 1. Lettura File (NON misurata)
    FILE *fa = fopen(fileA, "rb");
    FILE *fb = fopen(fileB, "rb");
    if (!fa || !fb) { perror("fopen"); return 1; }
    
    fseek(fa, 0, SEEK_END); long na = ftell(fa); fseek(fa, 0, SEEK_SET);
    fseek(fb, 0, SEEK_END); long nb = ftell(fb); fseek(fb, 0, SEEK_SET);
    
    char *a = malloc(na);
    char *b = malloc(nb);
    if (!a || !b) { fprintf(stderr, "Allocation failed\n"); return 1; }
    
    if (fread(a, 1, na, fa) != na || fread(b, 1, nb, fb) != nb) {
        fprintf(stderr, "Read failed\n"); return 1;
    }
    fclose(fa); fclose(fb);

    // 2. Timer START
    double t0 = get_time_sec();

    // 3. Calcolo
    // Nota: lcs_length_dp deve essere definita in lcs_core.c e linkata dal Makefile
    int len = lcs_length_dp(a, na, b, nb);

    // 4. Timer END
    double t1 = get_time_sec();

    // 5. Output Standardizzato per Benchmark
    printf("RESULT_LEN: %d\n", len);
    printf("ELAPSED_TIME: %.6f\n", t1 - t0);

    // Stampa sequenza solo se richiesto (Debug)
    if (print_seq) {
        size_t out_len; 
        char *seq = lcs_sequence_dp(a, na, b, nb, &out_len);
        if (seq) {
            printf("LCS seq: %s\n", seq);
            free(seq);
        }
    }

    free(a); free(b);
    return 0;
}