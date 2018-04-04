ssh fgcz-176.uzh.ch
ssh fgcz-h-515

#ENVIRONMENT

#Locally installed programs
/misc/fgcz02/local

#Working directory
/misc/fgcz02/data/workshop_2018/wgs

#WORKFLOW
#Load module system with installed programs
lmodInit

#Check available modules
module avail

#Add following modules and programs in your path environment
module add Aligner/BWA/0.7.15
module add Assembly/SPAdes/3.10.1
module add Dev/Python2
module add QC/FastQC/0.11.5
module add QC/QUAST/4.5
module add QC/Trimmomatic/0.36
module add Tools/samtools
module add Aligner/ncbi-blast
module add Tools/htslib
export PATH="/misc/fgcz02/local/kSNP3:$PATH"
export PATH="/misc/fgcz02/local/snpbac:$PATH"
export PATH="/misc/fgcz02/local/btyper:$PATH"

screen -S mytest #Screen mode
screen -r mytest #Re-connect to your screen
Ctrl-A Ctrl-D #Disconnect from the screen

#Go to the working directory
cd /misc/fgcz02/data/workshop_2018/wgs/participants

#Create a directory with your name
mkdir <myname>

#Go to your directory and create a directory called 1_sra
cd <myname>
mkdir 1_sra
cd 1_sra

# Download whole genome sequence reads and split them in forward and reverse sequences
##Programs needed: sra toolkit (https://ncbi.github.io/sra-tools/install_config.html)
	###Replace the SRR accession number with the one assigned to you (do not use fastq-dump -I; bwa mem requires identical PE read names)
#Command:
wget http://sra-download.ncbi.nlm.nih.gov/srapub/SRR6825046 | fastq-dump --gzip --split-files SRR6825046

#Script:
sh wget_dump.sh

#Trimm adapters (Nextera XT library, paired end sequences, 250 bp long reads)
##Program needed: Trimmomatic

#Command:
trimmomatic PE -threads 8 -phred33 -trimlog log SRR6825046_1.fastq.gz SRR6825046_2.fastq.gz SRR6825046_1.trimmedP.fastq.gz SRR6825046_1.trimmedS.fastq.gz SRR6825046_2.trimmedP.fastq.gz SRR6825046_2.trimmedS.fastq.gz ILLUMINACLIP:/misc/fgcz02/data/workshop_2018/wgs/0_scripts/adapters/NexteraPE-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
#Adapters: /misc/fgcz02/data/workshop_2018/wgs/0_scripts/adapters
#trimmedP.fastq.gz is file with trimmed read sequences
#trimmedS.fastq.gz is file with adapter sequences

# Script:
sh trimmomatic.sh <path to directory with input .trimmedP.fastq.gz files>

#Create a 2_trimmedP directory for trimmed sequences and copy trimmedP.fastq.gz files in 2_trimmedP
mkdir ../2_trimmedP
cp *.trimmedP.fastq.gz ../2_trimmedP

#Asses quality of trimmed reads 
##Program needed: FastQC
##Move to your directory and create a directory 3_fastqc for output files of fastQC
cd ..
mkdir 3_fastqc
cd 2_trimmedP
cd ../2_trimmedP

#Command:
mkdir ../3_fastqc
fastqc SRR6825046_1.trimmedP.fastq.gz -o ../3_fastqc
fastqc SRR6825046_2.trimmedP.fastq.gz -o ../3_fastqc

#Script: 
sh fastqc.sh <path to directory with input .trimmed.fastq.gz files> <path to output directory>

#Move to directory 3_fastqc, download and view the output html files
cd ../3_fastqc
ip addr show
scp <server_IP_address>:/<path_to_the_html_file> .
#Example: scp 172.23.44.16:/misc/fgcz02/data/workshop_2018/wgs/participants/jasna/3_fastqc/SRR6825046_1.trimmedP_fastqc.html .

#Assemble genomes de novo
## Program needed: SPAdes
cd ../2_trimmedP

#Command:
spades.py -k 99,127 --careful -1 SRR6825046_1.trimmedP.fastq.gz -2 SRR6825046_2.trimmedP.fastq.gz -o SRR6825046 -t 8 -m 32

#Move to the output directory SRR6825046/K127 and rename final_contigs.fasta into SRR6825046_contigs.fasta
cd SRR6825046/K127
mv final_contigs.fasta SRR6825046_contigs.fasta
mkdir ../../../4_contigs
cp SRR6825046_contigs.fasta ../../../4_contigs/

#Script:
sh spades.sh <path to directory with input .trimmedP.fastq.gz files>

#Assess quality of assembled genomes
##Program needed: QUAST
cd ../../../4_contigs
#Command: 
quast -o ./quast_results/quast_SRR6825046 --min-contig 1 SRR6825046_contigs.fasta

#View the report file
cd quast_results/quast_SRR6825046
vim report.txt

#Script:
sh quast.sh <path_to_directory_with_input_contigs.fasta files>


#Determine average coverage of draft genomes
##Programs needed: bwa-mem, samtools (use -o with samtools 1.6)
#Copy trimmedP.fastq.gz into directory 4_contigs
cp ../2_trimmedP/*.trimmedP.fastq.gz .

#Commands:
bwa index SRR6825046_contigs.fasta #Index assembled genome
bwa mem -t 8 SRR6825046_contigs.fasta SRR6825046_1.trimmedP.fastq.gz SRR6825046_2.trimmedP.fastq.gz > SRR6825046.sam #Align reads to the assembly
samtools view -Sb SRR6825046.sam -o SRR6825046.bam #Convert sam to bam
samtools sort SRR6825046.bam -o SRR6825046_sorted.bam #Sort bam file
samtools depth SRR6825046_sorted.bam | awk '{sum+=$3} END { print sum/NR}' #Calculate depth

#Script:
sh average_coverage.sh <path_to_directory_with_contigs_and_reads>

#Variant calling (1) and core genome phylogeny construction
##Programs needed: kSNP3, raxml
##Input file = in_list; optimal k-mer size for B. cereus group is k=21
	### in_list format: <path_to_the_file><tab><file_name>
mkdir ksnp_out
kSNP3 -in /misc/fgcz02/data/workshop_2018/wgs/7_variant_calling/assembled/in_list -k 21 -outdir <path_to_your_directory/ksnp_out> -core -CPU 8 -ML | tee logfile
#Example outdir: /misc/fgcz02/data/workshop_2018/wgs/7_variant_calling/assembled/ksnp_out

#Build maximum likelihood (ML) tree with RaxML
##Create a dirctory raxml in ksnp_out
mkdir raxml
cp core_SNPs_matrix.fasta raxml raxml
cd raxml
raxml -f a -x 165 -m ASC_GTRGAMMA --asc-corr=lewis -p 596 -N 1000 -s core_SNPs_matrix.fasta -n ASC_core_SNPs.tre
### -f a, rapid bootstrap analysis and search for best­scoring ML tree in one program run
### -x rapid bootstrap random seed
### -m GTR model with ascertainment correction
### -p parsimony random seed 
### -N number of bootstraps
### -s input fasta file
### -n output tre file

#Download to your computer and view tree in Figtree
#RAxML_bipartitions.ASC_core_SNPs.tre is a tree file with bootstrap values
scp 172.23.44.16:/misc/fgcz02/data/workshop_2018/wgs/7_variant_calling/assembled/ksnp_out/raxml/RAxML_bipartitions.ASC_core_SNPs.tre .

#Variant calling (2) and core genome phylogeny construction
##Pipeline needed: bacsnp (https://github.com/lmc297/SNPBac)
	### Programs needed: python, biopython, bwa-mem, samtools/bcftools, vcftools, gubbins, raxml
#Create a sample_list.txt file
make_snpbac_infile.py --input /misc/fgcz02/data/workshop_2018/wgs/1_sra --out /misc/fgcz02/data/workshop_2018/wgs/7_variant_calling/non_assembled/sample_list.txt --forward "_1.fastq.gz" --reverse "_2.fastq.gz"

#Run the snpbac SNP calling pipeline
snpbac -i /misc/fgcz02/data/workshop_2018/wgs/7_variant_calling/non_assembled/sample_list.txt -o /misc/fgcz02/data/workshop_2018/wgs/7_variant_calling/non_assembled/out -r /misc/fgcz02/data/workshop_2018/wgs/7_variant_calling/non_assembled/B_cereus.fasta --aligner bwa --pipeline samtools --quality 30 --remove_recombination False --threads 8

#Genotyping and gene discovery
##Programs needed: BTyper, (optional BMiner)
###BTyper
#Command:
btyper -i SRR6825046_contigs.fasta -o btyper_out -t seq --draft_genome --panC_database latest

#View BTyper report
cd btyper_out/btyper_final_results
vim SRR6825046_contigs_final_results.txt

#Script:
sh btyper.sh <path_to_input_files>



	

