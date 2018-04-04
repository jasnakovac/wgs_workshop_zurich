#!/bin/bash
#Usage: sh spades_loop.sh <path to input files>

cd $1

for f in *_1.trimmedP.fastq.gz
do
if [ -d "${f%_1.trimmedP.fastq.gz}" ]
then
echo 'skip'${f}
continue
fi
echo 'assemble'${f%_1.trimmedP.fastq.gz}
spades.py -k 99,127 --careful -1 $f -2 ${f%_1.trimmedP.fastq.gz}_2.trimmedP.fastq.gz -o ${f%_1.trimmedP.fastq.gz} -t 50 -m 100;
done

mkdir contigs  
for f in *_1.trimmedP.fastq.gz
do
	cd ${f%_1.trimmedP.fastq.gz}/K127
	cat contigs.fasta > ${f%_1.trimmedP.fastq.gz}_contigs.fasta
	cp ${f%_1.trimmedP.fastq.gz}_contigs.fasta ../../contigs
	cd ..;
done

mkdir scaffolds  
for f in *_1.trimmedP.fastq.gz
do
	cd ${f%_1.trimmedP.fastq.gz}/K127
	cat scaffolds.fasta > ${f%_1.trimmedP.fastq.gz}_scaffolds.fasta
	cp ${f%_1.trimmedP.fastq.gz}_scaffolds.fasta ../../scaffolds
	cd ..;
done
