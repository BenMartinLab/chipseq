#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=16
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

samplesheet=${1:-samplesheet.csv}

# Validating arguments.
if ! [[ -f "$samplesheet" ]]
then
  >&2 echo "Error: samplesheet file '$samplesheet' does not exists."
  usage
  exit 1
fi

srr_column=$(awk -F ',' \
    'NR == 1 {for (i = 1; i <= NF; i++) if ($i == "srr") {print i; exit(0)}}' \
    "$samplesheet")
if [[ -z "$srr_column" ]]
then
  >&2 echo "Error: no 'srr' column found in samplesheet $samplesheet."
  exit 1
fi

awk -F ',' -v srr_column="$srr_column" 'NR > 1 {print $srr_column}' "$samplesheet" \
    | parallel -t fasterq-dump --threads 2
find ./SRR*.fastq | parallel -t gzip

find . -maxdepth 1 -type d -name "SRR*" -exec rm -r {} \;
