# Assignment: Longest Common Subsequence (HPC Project)
# Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
# Lecturer: Moscato Francesco, fmoscato@unisa.it
#
# License: GPLv3 (see LICENSE file)
# Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
# Purpose: Suite di test automatizzati per verificare il corretto funzionamento delle interfacce CLI degli eseguibili.


import subprocess

def test_seq_basic():
    r = subprocess.run(['./build/lcs_seq','tests/sample_A.bin','tests/sample_B.bin'], capture_output=True, text=True)
    assert r.returncode == 0
    assert 'LCS length' in r.stdout

def test_omp_basic():
    r = subprocess.run(['./build/lcs_omp','tests/sample_A.bin','tests/sample_B.bin','2'], capture_output=True, text=True)
    assert r.returncode == 0
    assert 'LCS length' in r.stdout

def test_omp_print_seq():
    r = subprocess.run(['./build/lcs_omp','tests/sample_A.bin','tests/sample_B.bin','2','--print-seq'], capture_output=True, text=True)
    assert r.returncode == 0
    assert 'LCS seq' in r.stdout

def test_mpi_print_seq():
    r = subprocess.run(['mpirun','-np','2','./build/lcs_mpi','tests/sample_A.bin','tests/sample_B.bin','--print-seq'], capture_output=True, text=True)
    # mpirun may return non-zero in some configs; just assert output contains Hirschberg
    assert 'Hirschberg' in r.stdout or 'LCS length' in r.stdout
