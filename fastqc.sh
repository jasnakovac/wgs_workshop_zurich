
#!/bin/bash
#Usage: sh fastqc.sh <path to input files> <output directory>

cd $1
for file in *.trimmedP.fastq.gz
    do 
	cd $2	
	if [ -d "${file%.trimmedP.fastq.gz}_fastqc" ]
	then
	echo 'skip'${file}
	continue
	fi
	cd $1
    echo 'fastqc 1'${file}
    fastqc $file -o $2;
done
