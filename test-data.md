## Download test data

### Prepare working environment

Add ChIP-seq scripts folder to your PATH.

```shell
export PATH=~/projects/def-bmartin/scripts/chipseq:$PATH
```

For Rorqual server, use

```shell
export PATH=~/links/projects/def-bmartin/scripts/chipseq:$PATH
```

### Download samplesheet

Download the [samplesheet.csv](samplesheet.csv) file.

```shell
wget https://raw.githubusercontent.com/BenMartinLab/chipseq/refs/heads/main/samplesheet.csv
```

### Fetch FASTQ files.

> [!TIP]
> If connected to a server, you should use `tmux` to allow download to complete even if you get disconnected.

```shell
bash prefetch.sh
```

After running `prefetch.sh` completes, you should see the following message for each sample:
`Database 'SRR29290337.sra' is consistent`.

If you don't see this message for each sample, or you see an error, you can just restart `prefetch.sh` using the previous command -
`bash prefetch.sh`.

Once you see this message for each sample, run `fasterq-dump.sh`.

```shell
sbatch fasterq-dump.sh
```
