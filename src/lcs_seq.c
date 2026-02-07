/*
 * GPLv3
 * Sequential LCS implementation (standard DP, full matrix)
 * Student: <Your Name>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include "../inc/lcs.h"

static long now_ms() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1000L + tv.tv_usec / 1000L;
}

/* Core functions moved to src/lcs_core.c */

/* Simple CLI: lcs_seq file1 file2 [--print-seq]
   prints length and optionally the sequence
*/
int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s fileA fileB [--print-seq]\n", argv[0]);
        return 1;
    }
    const char *fileA = argv[1];
    const char *fileB = argv[2];
    int print_seq = 0;
    if (argc > 3 && strcmp(argv[3], "--print-seq") == 0) print_seq = 1;
    FILE *fa = fopen(fileA, "rb");
    FILE *fb = fopen(fileB, "rb");
    if (!fa || !fb) { perror("fopen"); return 1; }
    fseek(fa, 0, SEEK_END); long na = ftell(fa); fseek(fa, 0, SEEK_SET);
    fseek(fb, 0, SEEK_END); long nb = ftell(fb); fseek(fb, 0, SEEK_SET);
    char *a = malloc(na);
    char *b = malloc(nb);
    if (!a || !b) { fprintf(stderr, "Allocation failed\n"); return 1; }
    fread(a, 1, na, fa); fread(b, 1, nb, fb);
    fclose(fa); fclose(fb);

    long t0 = now_ms();
    int len = lcs_length_dp(a, na, b, nb);
    long t1 = now_ms();
    printf("LCS length = %d\n", len);
    printf("Time: %ld ms\n", t1 - t0);
    if (print_seq) {
        size_t out_len; char *seq = lcs_sequence_dp(a, na, b, nb, &out_len);
        if (seq) printf("LCS seq: %s\n", seq);
        free(seq);
    }
    free(a); free(b);
    return 0;
}
