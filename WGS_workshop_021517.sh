#!/bin/bash
# jk2739@cornell.edu
# Feb 15, 2017
# NGS workshop - WGS analyses

# ssh connect to the fgcz general login node (if outside the university network) and then to fgcz-h-110 (Windows users use putty)
ssh <assigned IP address>

# copy a file from your computer to the server
scp -r my_local_directory 172.23.89.27:/fgczdata/data/wgs

# copy files from server to your computer (open a shell and navigate to the
scp -r 172.23.89.27:/fgczdata/data/wgs/directory_to_copy .

# data storage
fgcz-h-110:/fgczdata/data

# 1 extract sequences from SRA (download only an experiment assigned to you)

wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541537
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541601
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541602
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541603
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541604
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541605
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541606
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541607
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541613
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541639
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541640
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541641
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541651
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541662
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541668
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541674
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR2541680

# 2 convert SRR to fastq.gz (convert only a sequence assigned to you)

fastq-dump -I --gzip --split-files SRR2541537
fastq-dump -I --gzip --split-files SRR2541601
fastq-dump -I --gzip --split-files SRR2541602
fastq-dump -I --gzip --split-files SRR2541603
fastq-dump -I --gzip --split-files SRR2541604
fastq-dump -I --gzip --split-files SRR2541605
fastq-dump -I --gzip --split-files SRR2541606
fastq-dump -I --gzip --split-files SRR2541607
fastq-dump -I --gzip --split-files SRR2541613
fastq-dump -I --gzip --split-files SRR2541639
fastq-dump -I --gzip --split-files SRR2541640
fastq-dump -I --gzip --split-files SRR2541641
fastq-dump -I --gzip --split-files SRR2541651
fastq-dump -I --gzip --split-files SRR2541662
fastq-dump -I --gzip --split-files SRR2541668
fastq-dump -I --gzip --split-files SRR2541674
fastq-dump -I --gzip --split-files SRR2541680

# 3 Trimm the addapetrs (Nextera XT) with Trimmomatic
/usr/local/ngseq/bin/trimmomatic PE -phred33 SRR2541680_1.fastq.gz SRR2541680_2.fastq.gz SRR2541680_1.trimmedP.fastq.gz SRR2541680_1.trimmedS.fastq.gz SRR2541680_2.trimmedP.fastq.gz SRR2541680_2.trimmedS.fastq.gz ILLUMINACLIP:/fgczdata/data/wgs/adapters/NexteraPE-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

# 4 FastQC
/usr/local/ngseq/bin/fastqc SRR2541680_1.trimmedP.fastq.gz
/usr/local/ngseq/bin/fastqc SRR2541680_2.trimmedP.fastq.gz

# 5 Assemble genomes de novo with SPAdes 
python /usr/local/ngseq/bin/spades.py -k 21,33,55,77,99,127 --careful -1 SRR2541680_1.trimmedP.fastq.gz -2 SRR2541680_2.trimmedP.fastq.gz -o SRR2541680 –t 7 -m 20

# 6 Assembly quality control with QUAST
python /fgczdata/local/quast-4.4/quast.py –o SRR2541680_quast --min-contig 1 SRR2541680_contigs.fasta

# 7 Average coverage
#indexing with bbpam; use contigs file as a reference for read mapping
/fgczdata/local/bbmap/bbmap.sh ref=SRR2541680_contigs.fasta
#create a sam file with the alignment
/fgczdata/local/bbmap/bbmap.sh in=SRR2541680_1.trimmedP.fastq.gz in2=SRR2541680_2.trimmedP.fastq.gz out=SRR2541680.sam
#move sam file
mv ref/ SRR2541680_ref/
#covert sam file to bam file using samtools
/usr/local/ngseq/bin/samtools view -Sb SRR2541680.sam > SRR2541680.bam
#remove sam file
rm -r *.sam
#sort bam file using asmtools (note: do not use -o or output suffix with this version of samtools)
/usr/local/ngseq/bin/samtools sort SRR2541680.bam SRR2541680_sorted
#index sorted bam file
/usr/local/ngseq/bin/samtools index SRR2541680_sorted.bam
#use samtools depth to obtain average genome coverage
/usr/local/ngseq/bin/samtools depth SRR2541537_sorted.bam | awk '{sum+=$3} END { print sum/NR}' > average_coverage.txt

# 8 SNP calling with kSNP3
# 8a - create in_list file with paths to individual input files; each path is followed by a tab and isolate name as it appears in the sequence name; example:
# /fgczdata/data/wgs/jk2739/6_contigs/B_cereus_ATCC_14579_anno.fasta    B_cereus_ATCC_14579_anno

# 8c - run Kchooser to determine the optimal kmer size (optimal kmer size is 21)
/fgczdata/local/kSNP3/MakeFasta in_list VC.fasta
/fgczdata/local/kSNP3/Kchooser VC.fasta

# 4 - run kSNP; this uses all available CPUs detected - alternatively use; add -ML if you want maximum likelihood tree in the output (default is parsimony); add -core if you want only core SNPs; add -min_frac 0.9 if you want only SNPs identified in at least 90% of the genomes; add -vcf if you want vcf file in the output
/fgczdata/local/kSNP3/kSNP3 -in in_list -outdir out -k -21 -CPU 8 -vcf -ML -core | tee runlog.txt

# build ML tree with RaxML
/usr/local/ngseq/bin/raxml -f a -x 165 -m ASC_GTRGAMMA --asc-corr=lewis --no-bfgs -p 596 -N 1000 -s core_SNPs_matrix.fasta -n ASC_core_SNPs.tre

