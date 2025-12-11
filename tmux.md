## Run the nf-core pipeline using tmux

### Create tmux session

You need to remember on which login node you started the tmux session in case you get disconnected from the server. If you have trouble remembering the login node, connect to the first login node.

To connect to the first login node on Narval, use this command.

```shell
ssh narval1
```

To connect to the first login node on Rorqual, use this command.

```shell
ssh rorqual1
```

### Start a new tmux session

```shell
tmux new -s chipseq
```

Once inside the tmux session, you may find it difficult to return to your regular shell. Use Ctrl+b than d to detach from the tmux session.

To reattach to the tmux session, use this command (must be executed from the same login node on which you started the session).

```shell
tmux a -t chipseq
```

You can see active tmux sessions using this command.

```shell
tmux ls
```

For more information on tmux, see [tmux documentation](https://github.com/tmux/tmux/wiki).

Cheatsheet for tmux [https://tmuxcheatsheet.com](https://tmuxcheatsheet.com).

### Run the pipeline

Follow the instructions in [Prepare working environment of README.md](README.md#prepare-working-environment)

From the tmux session, start the pipeline using the following command.

```shell
nfcore-chipseq.sh -profile alliance_canada \
    --input $samplesheet \
    --outdir output \
    --fasta $genome.fa \
    --gtf $genome.gtf \
    --aligner bowtie2 \
    --bowtie2_index bowtie2/$genome.1.bt2 \
    --read_length $read_length
```
