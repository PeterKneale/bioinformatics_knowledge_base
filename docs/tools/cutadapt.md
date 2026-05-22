# Cutadapt

**Purpose:** Finds and removes adapter sequences, primers, poly-A tails, and other unwanted sequences from high-throughput sequencing reads. Supports paired-end, linked adapters, and demultiplexing.

**Source:** [cutadapt.readthedocs.io](https://cutadapt.readthedocs.io/)  
**Citation:** Martin M. (2011) *EMBnet.journal* 17:10-12

## Installation

```bash
conda install -c bioconda cutadapt
# or
pip install cutadapt
```

## Usage Examples

```bash
# Remove 3' adapter (single-end)
cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA \
    -o trimmed.fq.gz reads.fq.gz

# Remove 3' adapters (paired-end)
cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA \
         -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT \
         -o trimmed_R1.fq.gz -p trimmed_R2.fq.gz \
         read1.fq.gz read2.fq.gz

# Quality trimming + adapter removal
cutadapt -a AGATCGGAAGAGC -q 20 --minimum-length 25 \
    -o trimmed.fq.gz reads.fq.gz

# Remove 5' adapter (e.g., for RACE)
cutadapt -g ADAPTER_SEQUENCE -o trimmed.fq.gz reads.fq.gz

# Linked adapters (5' then 3')
cutadapt -a "ADAPTER1...ADAPTER2" -o trimmed.fq.gz reads.fq.gz

# Trim fixed number of bases from ends
cutadapt -u 10 -u -5 -o trimmed.fq.gz reads.fq.gz

# Demultiplex by inline barcodes
cutadapt -g ^BARCODE1=ACGT -g ^BARCODE2=TGCA \
    -o {name}.fq.gz reads.fq.gz

# Poly-A tail removal
cutadapt -a "A{20}" --minimum-length 25 -o trimmed.fq.gz reads.fq.gz

# Multiple adapters
cutadapt -a ADAPTER1 -a ADAPTER2 -a ADAPTER3 \
    -o trimmed.fq.gz reads.fq.gz

# Multi-core processing
cutadapt -j 8 -a AGATCGGAAGAGC -o trimmed.fq.gz reads.fq.gz
```

## Adapter Types

| Flag | Position | Description                  |
| ---- | -------- | ---------------------------- |
| `-a` | 3' end   | Regular 3' adapter           |
| `-g` | 5' end   | Regular 5' adapter           |
| `-b` | Both     | Adapter anywhere             |
| `-A` | 3' (R2)  | Paired-end read 2 adapter    |
| `-G` | 5' (R2)  | Paired-end read 2 5' adapter |

## Key Options

| Option              | Description                    |
| ------------------- | ------------------------------ |
| `-o FILE`           | Output file (R1)               |
| `-p FILE`           | Output file (R2, paired-end)   |
| `-q INT`            | Quality trim threshold         |
| `-m INT`            | Minimum read length after trim |
| `-M INT`            | Maximum read length            |
| `-j INT`            | Number of cores                |
| `--discard-trimmed` | Discard reads with adapter     |
| `--times INT`       | Remove adapter up to N times   |
| `-e FLOAT`          | Error rate (default: 0.1)      |
| `--overlap INT`     | Min overlap for detection      |

## Formats Consumed/Produced

| Format                       | Description        |
| ---------------------------- | ------------------ |
| [FASTQ](../formats/fastq.md) | Input/output reads |

## See Also

- [fastp](fastp.md) — all-in-one preprocessing (faster)
- [trimmomatic](trimmomatic.md) — alternative trimmer
- [FastQC](fastqc.md) — assess adapter contamination
