#!/bin/bash
cd $(dirname "$(realpath $0)")
cd $1
nasm -felf64 -g -F dwarf -Wall day$1.asm && ld -o solve_day day$1.o

shift 1
./solve_day $@
