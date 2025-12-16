#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --output=fragment-counts-%A_%a.out

# exit when any command fails
set -e

if [[ -n "$CC_CLUSTER" ]]
then
  module purge
  module load StdEnv/2023
  module load samtools/1.22.1
  module load bedtools/2.31.0
  module load kent_tools/486
  echo
fi

index=${SLURM_ARRAY_TASK_ID:-0}
index=$((index+1))
threads=${SLURM_CPUS_PER_TASK:-1}
tmpdir=${SLURM_TMPDIR:-/tmp}

samplesheet=samplesheet.csv
genome=hg38.chrom.sizes
output=output/bowtie2/merged_library
suffix=.counts

# Usage function
usage() {
  echo
  echo "Usage: genome-coverage.sh [-i int] [-s samplesheet.csv] [-g hg38.chrom.sizes] " \
       "[-o output/star_salmon] [-f .counts]"
  echo "  -i: Index of sample in samplesheet (default: 1 or SLURM_ARRAY_TASK_ID+1 if present)"
  echo "  -s: Samplesheet file (default: samplesheet.csv)"
  echo "  -g: Genome chromosome sizes file (default: hg38.chrom.sizes)"
  echo "  -o: Output folder where BAM files are located (default: output/bowtie2/merged_library)"
  echo "  -f: Output file suffix (default: .counts)"
  echo "  -h: Show this help"
}

# Parsing arguments.
while getopts 'i:s:g:o:f:h' OPTION; do
  case "$OPTION" in
    i)
       index="$OPTARG"
       ;;
    s)
       samplesheet="$OPTARG"
       ;;
    g)
       genome="$OPTARG"
       ;;
    o)
       output="$OPTARG"
       ;;
    f)
       suffix="$OPTARG"
       ;;
    h)
       usage
       exit 0
       ;;
    :)
       usage
       exit 1
       ;;
    ?)
       usage
       exit 1
       ;;
  esac
done

# Validating arguments.
if ! [[ "$index" =~ ^[0-9]+$ ]]
then
  >&2 echo "Error: -i parameter '$index' is not an integer."
  usage
  exit 1
fi
if ! [[ -f "$samplesheet" ]]
then
  >&2 echo "Error: -s file parameter '$samplesheet' does not exists."
  usage
  exit 1
fi
if ! [[ -f "$genome" ]]
then
  >&2 echo "Error: -g file parameter '$genome' does not exists."
  usage
  exit 1
fi
if ! [[ -d "$output" ]]
then
  >&2 echo "Error: -o folder parameter '$output' does not exists."
  usage
  exit 1
fi


sample=$(awk -F ',' -v sample_index="$index" \
    'NR > 1 && !seen[$1"_REP"$4] {ln++; seen[$1"_REP"$4]++; if (ln == sample_index) {print $1"_REP"$4}}' "$samplesheet")
sample="${sample%%[[:cntrl:]]}"

bam="${output}/${sample}.mLb.clN.sorted.bam"
if [[ ! -f "$bam" ]]
then
  >&2 echo "Error: BAM file '${sample}.mLb.clN.sorted.bam' does not exists in output folder '$output', exiting..."
  exit 1
fi

echo "Computing fragment middle counts for sample $sample using BAM $bam"
samtools sort -n \
    --threads "$threads" \
    -T "${tmpdir}/${sample}.sortreadname" \
    -o "${tmpdir}/${sample}.sortreadname.bam" \
    "$bam"
bedtools bamtobed \
    -bedpe \
    -i "${tmpdir}/${sample}.sortreadname.bam" \
    | awk -v OFS='\t' '
    {if ($2 < $5) {start=$2} else {start=$5}};
    {if ($3 > $6) {end=$3} else {end=$6}};
    {print $1,start,end,$7,$8,$9}' \
    | awk -v OFS='\t' '
    {middle=int($2+($3-$2)/2); print $1,middle,middle+1,$4,$5,$6}' \
    | LC_ALL=C sort --parallel="$threads" -k1,1 -k2,2n \
    > "${tmpdir}/${sample}.fragment-middle.bed"
bedtools genomecov \
    -dz \
    -g "$genome" \
    -i "${tmpdir}/${sample}.fragment-middle.bed" \
    | awk -v OFS='\t' '
    {print $1,$2,$2+1,$3}' \
    | LC_ALL=C sort --parallel="$threads" -k1,1 -k2,2n \
    > "${tmpdir}/${sample}.bedGraph"
bedClip \
    "${tmpdir}/${sample}.bedGraph" \
    "$genome" \
    "${tmpdir}/${sample}.clip.bedGraph"
bedGraphToBigWig \
    "${tmpdir}/${sample}.clip.bedGraph" \
    "$genome" \
    "${output}/bigwig/${sample}${suffix}.bigWig"
