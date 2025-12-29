#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=40
#SBATCH --mem=40G
#SBATCH --output=fasterq-dump-%A.out

# exit when any command fails
set -e

if [[ -n "$CC_CLUSTER" ]]
then
  module purge
  module load StdEnv/2023
  module load sra-toolkit/3.0.9
fi

awk -F ',' 'NR > 1 {print $8}' samplesheet.csv | parallel -t fasterq-dump --threads 2
ls -1 SRR*.fastq | parallel -t gzip
rename _1.fastq.gz _R1.fastq.gz *.fastq.gz
rename _2.fastq.gz _R2.fastq.gz *.fastq.gz
awk -F ',' 'NR > 1 {print $8"\n"$2}' samplesheet.csv | parallel -N 2 mv {1}_R1.fastq.gz {2}
awk -F ',' 'NR > 1 {print $8"\n"$3}' samplesheet.csv | parallel -N 2 mv {1}_R2.fastq.gz {2}

rm -r SRR*
