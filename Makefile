# Assignment: Longest Common Subsequence (HPC Project)
# Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
# Lecturer: Moscato Francesco, fmoscato@unisa.it
#
# License: GPLv3 (see LICENSE file)
# Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
# Purpose: Script di automazione per la compilazione di tutte le versioni del progetto (Seq, OMP, MPI, CUDA) e pulizia dei binari.
CC = gcc
CFLAGS = -O3 -std=c11 -Wall
LDFLAGS =
MPICC = mpicc
NVCC = nvcc

SRC = src
BIN = build

all: $(BIN)/lcs_seq $(BIN)/lcs_hirschberg $(BIN)/lcs_omp $(BIN)/lcs_mpi
	@echo "Build complete"

$(BIN)/lcs_seq: $(SRC)/lcs_seq.c $(SRC)/lcs_core.c | $(BIN)
	$(CC) $(CFLAGS) $(SRC)/lcs_seq.c $(SRC)/lcs_core.c -o $@

$(BIN)/lcs_hirschberg: $(SRC)/lcs_hirschberg_cli.c $(SRC)/lcs_hirschberg.c | $(BIN)
	$(CC) $(CFLAGS) $(SRC)/lcs_hirschberg_cli.c $(SRC)/lcs_hirschberg.c -o $@

$(BIN)/lcs_omp: $(SRC)/lcs_omp.c $(SRC)/lcs_core.c | $(BIN)
	$(CC) $(CFLAGS) -fopenmp $(SRC)/lcs_omp.c $(SRC)/lcs_core.c -o $@

$(BIN)/lcs_mpi: $(SRC)/lcs_mpi.c $(SRC)/lcs_hirschberg.c | $(BIN)
	$(MPICC) $(CFLAGS) $(SRC)/lcs_mpi.c $(SRC)/lcs_hirschberg.c -o $@

$(BIN)/lcs_cuda: $(SRC)/lcs_cuda.cu | $(BIN)
	$(NVCC) -O3 $< -o $@

$(BIN)/lcs_omp_cuda: $(SRC)/lcs_omp_cuda.c | $(BIN)
	$(CC) $(CFLAGS) -fopenmp $(SRC)/lcs_omp_cuda.c -o $@

clean:
	rm -f $(BIN)/lcs_* *.o

test: all
	@bash tests/run_tests.sh

$(BIN):
	mkdir -p $(BIN)

.PHONY: all clean test
