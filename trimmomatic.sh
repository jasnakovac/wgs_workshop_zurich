#!/bin/bash
#Usage: sh trimmomatic.sh <path to input files>

cd $1
echo | pwd
for f in *.fastq.gz
do
if [ -f "${f%_1.fastq.gz}_1.trimmedP.fastq.gz}" ]
then
echo 'skip'${f}
continue
fi
echo 'trim' ${f}
trimmomatic PE -threads 8 -phred33 -trimlog log $f ${f%_1.fastq.gz}_2.fastq.gz ${f%_1.fastq.gz}_1.trimmedP.fastq.gz ${f%_1.fastq.gz}_1.trimmedS.fastq.gz ${f%_1.fastq.gz}_2.trimmedP.fastq.gz ${f%_1.fastq.gz}_2.trimmedS.fastq.gz ILLUMINACLIP:/misc/fgcz02/data/workshop_2018/wgs/1_sra/adapters/NexteraPE-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36;
done;
