# ChIP-seq data analysis

This repository contains scripts to analyse ChIP-seq data using [nf-core pipeline](https://nf-co.re/chipseq) on Alliance Canada servers.

To install the scripts on Alliance Canada servers and download genomes, see [INSTALL.md](INSTALL.md)

### Steps

1. [Transfer data to scratch](#Transfer-data-to-scratch)
2. [Prepare working environment](#Prepare-working-environment)
    1. [Set additional variables](#Set-additional-variables)
3. [Run the nf-core pipeline](#Run-the-nf-core-pipeline)
4. [Computing scale factors](#Computing-scale-factors)
5. [Genome coverage](#Genome-coverage)
6. [Split BAM (Optional)](#Split-BAM-Optional)

## Transfer data to scratch

You will need to transfer the following files on the server in the `scratch` folder.

* FASTQ files.
* Genome files (FASTA and GTF). See [Genomes](https://github.com/BenMartinLab/genomes).
    * Copy `bowtie2` folder for your genome.
* Samplesheet file. See [Samplesheet for ChIP-seq pipeline](https://nf-co.re/chipseq/2.1.0/docs/usage/#samplesheet-input)
    * [Here is an example of a samplesheet file](samplesheet.csv)
* Any additional files that are needed for your analysis.

There are many ways to transfer data to the server. Here are some suggestions.

* Use an FTP software like [WinSCP](https://winscp.net) (Windows), [Cyberduck](https://cyberduck.io) (Mac), [FileZilla](https://filezilla-project.org).
* Use command line tools like `rsync` or `scp`.

## Prepare working environment

Add ChIP-seq scripts folder to your PATH.

```shell
export PATH=~/projects/def-bmartin/scripts/chipseq:$PATH
```

For Rorqual server, use

```shell
export PATH=~/links/projects/def-bmartin/scripts/chipseq:$PATH
```

### Set additional variables

> [!IMPORTANT]
> Change `samplesheet.csv` by your actual samplesheet filename.

```shell
samplesheet=samplesheet.csv
```

```shell
samples_array=$(awk -F ',' \
    'NR > 1 && !seen[$1"_REP"$4] {ln++; seen[$1"_REP"$4]++} END {print "0-"ln-1}' \
    "$samplesheet")
```

> [!IMPORTANT]
> Change `hg38-spike-dm6` by your actual genome name.

```shell
genome=hg38-spike-dm6
```

> [!IMPORTANT]
> Change `dm6` by your actual spike-in genome name.

```shell
spike=dm6
```

> [!IMPORTANT]
> Change `100` by the actual length of the reads.

```shell
read_length=100
```

## Run the nf-core pipeline

```shell
sbatch nfcore-chipseq.sh -profile alliance_canada \
    --input $samplesheet \
    --outdir output \
    --fasta $genome.fa \
    --gtf $genome.gtf \
    --aligner bowtie2 \
    --bowtie2_index bowtie2 \
    --read_length $read_length
```

## Computing scale factors

```shell
sbatch scale-factors.sh \
    --bam output/bowtie2/merged_library/*.bam \
    --output output/bowtie2/merged_library/scale-factors.txt \
    --samplesheet $samplesheet \
    --spike_fasta $spike.fa \
    --mean
```

## Genome coverage

Create BigWig containing middle base fragment counts.

```shell
sbatch --array=$samples_array fragment-counts.sh \
    -s $samplesheet \
    -g $genome.chrom.sizes
```

Genome coverage using scale factors based on sequencing depth.

```shell
sbatch --array=$samples_array genome-coverage.sh \
    -s $samplesheet \
    -g $genome.chrom.sizes
```

Genome coverage using spike-in scale factors.

```shell
sbatch --array=$samples_array genome-coverage.sh \
    -s $samplesheet \
    -g $genome.chrom.sizes \
    -c 5 \
    -f .spike_scaled
```

## Split BAM (Optional)

To split BAM files between main genome and spike-in genome, use the following command.

```shell
sbatch --array=$samples_array split-bam.sh \
    -s $samplesheet \
    -k $spike.fa
```
