#!/usr/bin/env bash
set -e

# Assignment: Longest Common Subsequence (HPC Project)
# Student: Parrella Marco
# Purpose: Script di test automatico per la validazione del progetto

# Colori per l'output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/build"
DATA="$ROOT/tests"

mkdir -p "$DATA"

echo -e "${GREEN}=== 1. GENERATING TEST DATA ===${NC}"
# Generiamo dati freschi
python3 "$ROOT/data/generate_input.py" --size-per-file 5000 --prefix "$DATA/test_data" --seed 123
FILE_A="$DATA/test_data_A.bin"
FILE_B="$DATA/test_data_B.bin"

echo -e "\n${GREEN}=== 2. RUNNING VERIFY.SH (CORRECTNESS CHECK) ===${NC}"

# Verifica OMP
echo -n "Checking OpenMP (1 thread)... "
bash "$ROOT/scripts/verify.sh" "$BIN/lcs_omp" "$FILE_A" "$FILE_B" 1

echo -n "Checking OpenMP (4 threads)... "
bash "$ROOT/scripts/verify.sh" "$BIN/lcs_omp" "$FILE_A" "$FILE_B" 4

# Verifica Auto-consistenza Sequenziale (opzionale ma utile)
echo -n "Checking Sequential Baseline... "
bash "$ROOT/scripts/verify.sh" "$BIN/lcs_seq" "$FILE_A" "$FILE_B"

echo -e "\n${GREEN}=== 3. CHECKING MPI ===${NC}"
# MPI Manual Check
MPI_CMD="mpirun --allow-run-as-root -np 2 \"$BIN/lcs_mpi\" \"$FILE_A\" \"$FILE_B\""
MPI_OUT=$(eval $MPI_CMD)

# FIX: Estraiamo RESULT_LEN
MPI_LEN=$(echo "$MPI_OUT" | grep "RESULT_LEN:" | awk '{print $2}')

# Calcoliamo la verità con lcs_seq
REF_OUT=$("$BIN/lcs_seq" "$FILE_A" "$FILE_B")
REF_LEN=$(echo "$REF_OUT" | grep "RESULT_LEN:" | awk '{print $2}')

if [ "$MPI_LEN" == "$REF_LEN" ] && [ ! -z "$MPI_LEN" ]; then
    echo -e "MPI (2 procs): ${GREEN}PASS${NC} (len=$MPI_LEN)"
else
    echo -e "MPI (2 procs): ${RED}FAIL${NC} (MPI=$MPI_LEN, REF=$REF_LEN)"
    # Debug output se fallisce
    if [ -z "$MPI_LEN" ]; then echo "Output MPI vuoto o malformato:"; echo "$MPI_OUT"; fi
    exit 1
fi

echo -e "\n${GREEN}=== ALL TESTS COMPLETED SUCCESSFULLY ===${NC}"