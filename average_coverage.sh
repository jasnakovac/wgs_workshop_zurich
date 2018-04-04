#!/bin/bash
# Usage: sh average_coverage.sh <path to input files>

cd $1
for f in *_contigs.fasta
do

echo "Indexing $f..."
bwa index $f

echo "Mapping reads to $f..."
bwa mem -t 8 $f ${f%_contigs.fasta}_1.trimmedP.fastq.gz ${f%_contigs.fasta}_2.trimmedP.fastq.gz > ${f%_contigs.fasta}.sam
echo "SAM file created"

echo "Converting SAM to BAM with samtools..."
samtools view -Sb ${f%_contigs.fasta}.sam -o ${f%_contigs.fasta}.bam
echo "BAM file created."

echo "Removing sam file..."
rm *.sam

echo "Sorting BAM file with samtools..."
samtools sort ${f%_contigs.fasta}.bam -o ${f%_contigs.fasta}_sorted.bam
echo "Finished sorting."

echo "Indexing sorted BAM file..."
samtools index ${f%_contigs.fasta}_sorted.bam
echo "Index complete."

echo "Using samtools depth to obtain average genome coverage..."
X=$(samtools depth ${f%_contigs.fasta}_sorted.bam | awk '{sum+=$3} END { print sum/NR}');
echo "${f%_contigs.fasta}_sorted.bam";
echo "$X";
echo "${f%_contigs.fasta}_sorted.bam $X">> average_coverage.txt;
done

