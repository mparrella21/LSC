# Makefile for LCS project
CC = gcc
CFLAGS = -O2 -std=c11 -Wall
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
	$(NVCC) -O2 $< -o $@

$(BIN)/lcs_omp_cuda: $(SRC)/lcs_omp_cuda.c | $(BIN)
	$(CC) $(CFLAGS) -fopenmp $(SRC)/lcs_omp_cuda.c -o $@

clean:
	rm -f $(BIN)/lcs_* *.o

test: all
	@bash tests/run_tests.sh

$(BIN):
	mkdir -p $(BIN)

.PHONY: all clean test
