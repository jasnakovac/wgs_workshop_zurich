#!/bin/bash
#Usage: sh btyper.sh <path to input files>

cd $1
mkdir btyper_out

for f in *.fasta
do
btyper -i $f -o btyper_out -t seq --draft_genome --panC_database latest
done

