# BWA (Burrows-Wheeler Aligner)

**Source:** [github.com/lh3/bwa](https://github.com/lh3/bwa)  
**License:** GPL-3.0  
**Category:** Short-read alignment

## Purpose

Maps short sequencing reads (Illumina) to a reference genome using the Burrows-Wheeler Transform. The `bwa mem` algorithm is the standard for reads 70bp–1Mbp and is the recommended aligner for most Illumina whole-genome and exome sequencing projects.

## Installation

```bash
conda install -c bioconda bwa
# or
brew install bwa
```

## Key Commands

| Command | Description |
|---------|-------------|
| `index` | Build BWT index from reference FASTA |
| `mem` | Align reads (preferred for 70bp+) |
| `aln` | Align short reads (<70bp, legacy) |
| `samse/sampe` | Generate SAM from aln output |

## Usage Examples

```bash
# Index the reference genome (one-time step)
bwa index reference.fa

# Align paired-end reads (standard pipeline)
bwa mem -t 8 reference.fa reads_R1.fastq.gz reads_R2.fastq.gz | \
  samtools sort -o aligned.sorted.bam

# Align with read group information (required for GATK)
bwa mem -t 8 -R '@RG\tID:sample1\tSM:sample1\tPL:ILLUMINA\tLB:lib1' \
  reference.fa reads_R1.fastq.gz reads_R2.fastq.gz | \
  samtools sort -o aligned.sorted.bam

# Align single-end reads
bwa mem -t 8 reference.fa reads.fastq.gz | samtools sort -o aligned.sorted.bam
```

## Produces

- SAM output to stdout (pipe to samtools for BAM)
- `.amb`, `.ann`, `.bwt`, `.pac`, `.sa` — Index files from `bwa index`

## Related Tools

- [bwa-mem2](https://github.com/bwa-mem2/bwa-mem2) — Faster SIMD-accelerated reimplementation
- [bowtie2](bowtie2.md) — Alternative short-read aligner
- [minimap2](minimap2.md) — Long-read and assembly alignment
- [samtools](samtools.md) — Post-alignment BAM processing
