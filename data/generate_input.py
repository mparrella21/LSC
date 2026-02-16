# Assignment: Longest Common Subsequence (HPC Project)
# Student: Parrella Marco, Matricola: 0622702536, Email: m.parrella21@studenti.unisa.it
# Lecturer: Moscato Francesco, fmoscato@unisa.it
#
# License: GPLv3 (see LICENSE file)
# Requirements: Implement Parallel LCS (OpenMP, MPI, CUDA)
# Purpose: Generatore di input casuali (sequenze ASCII/DNA) di dimensioni configurabili per test e benchmark.

#!/usr/bin/env python3
"""
Input generator for LCS project.
Generates two files containing random ASCII letters (or bytes) of target size.
Usage examples:
  ./generate_input.py --size-per-file 1048576 --prefix sample
  ./generate_input.py --total-bytes 2097152 --prefix sample --alphabet bytes
"""
import argparse
import os
import random
import string

parser = argparse.ArgumentParser()
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('--size-per-file', type=int, help='bytes per file')
group.add_argument('--total-bytes', type=int, help='total bytes (split between the two files)')
parser.add_argument('--prefix', default='input', help='prefix for output files')
parser.add_argument('--alphabet', choices=['ascii','small','bytes'], default='ascii', help='alphabet to use')
parser.add_argument('--seed', type=int, default=None)
args = parser.parse_args()

if args.seed is not None:
    random.seed(args.seed)

if args.total_bytes:
    s = args.total_bytes // 2
else:
    s = args.size_per_file

def gen_chars(n, alphabet):
    CHUNK = 1 << 20
    if alphabet == 'bytes':
        for _ in range(n // CHUNK):
            yield os.urandom(CHUNK)
        r = n % CHUNK
        if r: yield os.urandom(r)
    else:
        pool = string.ascii_letters if alphabet == 'ascii' else 'ACGT'
        for _ in range(n // CHUNK):
            yield ''.join(random.choice(pool) for _ in range(CHUNK)).encode('ascii')
        r = n % CHUNK
        if r: yield ''.join(random.choice(pool) for _ in range(r)).encode('ascii')

out1 = args.prefix + '_A.bin'
out2 = args.prefix + '_B.bin'
with open(out1, 'wb') as f:
    for chunk in gen_chars(s, args.alphabet): f.write(chunk)
with open(out2, 'wb') as f:
    for chunk in gen_chars(s, args.alphabet): f.write(chunk)

print(f'Wrote {out1} and {out2} ({s} bytes each).')
