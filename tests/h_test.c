#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../inc/lcs.h"
int main(){ FILE *fa=fopen("tests/sample_A.bin","rb"), *fb=fopen("tests/sample_B.bin","rb"); fseek(fa,0,SEEK_END); size_t na=ftell(fa); fseek(fa,0,SEEK_SET); char *a=malloc(na); fread(a,1,na,fa); fclose(fa);
 fseek(fb,0,SEEK_END); size_t nb=ftell(fb); fseek(fb,0,SEEK_SET); char *b=malloc(nb); fread(b,1,nb,fb); fclose(fb);
 size_t out; char *s = lcs_sequence_hirschberg(a,na,b,nb,&out); if(s) { printf("Hirschberg: len=%zu seq=%s\n", out, s); free(s); } else printf("Hirschberg: len=0\n"); free(a); free(b); return 0; }
