/*
 * GPLv3
 * Hirschberg CLI wrapper
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../inc/lcs.h"

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "Usage: %s fileA fileB [--print-seq]\n", argv[0]); return 1; }
    const char *fileA = argv[1]; const char *fileB = argv[2];
    FILE *fa = fopen(fileA, "rb"); FILE *fb = fopen(fileB, "rb"); if (!fa || !fb) { perror("fopen"); return 1; }
    fseek(fa,0,SEEK_END); size_t na = ftell(fa); fseek(fa,0,SEEK_SET);
    fseek(fb,0,SEEK_END); size_t nb = ftell(fb); fseek(fb,0,SEEK_SET);
    char *a = malloc(na); char *b = malloc(nb); fread(a,1,na,fa); fread(b,1,nb,fb); fclose(fa); fclose(fb);
    size_t out; char *s = lcs_sequence_hirschberg(a, na, b, nb, &out);
    printf("Hirschberg len=%zu\n", out);
    if (argc>3 && strcmp(argv[3],"--print-seq")==0 && s) printf("seq=%s\n", s);
    free(s); free(a); free(b);
    return 0;
}
