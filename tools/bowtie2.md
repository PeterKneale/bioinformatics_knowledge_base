# Bowtie2

**Source:** [bowtie-bio.sourceforge.net/bowtie2](https://bowtie-bio.sourceforge.net/bowtie2/)  
**License:** GPL-3.0  
**Category:** Short-read alignment

## Purpose

Ultrafast short-read aligner optimised for aligning sequencing reads to long reference genomes. Particularly suited for ChIP-seq and other applications where gapped alignment and local alignment modes are beneficial. Uses FM-index based on the Burrows-Wheeler Transform.

## Installation

```bash
conda install -c bioconda bowtie2
```

## Key Commands

| Command | Description |
|---------|-------------|
| `bowtie2-build` | Build index from reference FASTA |
| `bowtie2` | Align reads to indexed reference |
| `bowtie2-inspect` | Display index information |

## Usage Examples

```bash
# Build the genome index
bowtie2-build reference.fa bt2_index

# Align paired-end reads (end-to-end mode, default)
bowtie2 -x bt2_index -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --threads 8 | samtools sort -o aligned.sorted.bam

# Local alignment mode (soft-clipping allowed)
bowtie2 --local -x bt2_index -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --threads 8 | samtools sort -o aligned.sorted.bam

# Very sensitive alignment (slower but more accurate)
bowtie2 --very-sensitive -x bt2_index -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --threads 8 | samtools sort -o aligned.sorted.bam

# Align single-end reads
bowtie2 -x bt2_index -U reads.fastq.gz --threads 8 | \
  samtools sort -o aligned.sorted.bam

# Align from unaligned BAM
bowtie2 -x bt2_index -b unaligned.bam --threads 8 | \
  samtools sort -o aligned.sorted.bam
```

## Produces

- SAM output to stdout (pipe to samtools for BAM)
- `.bt2` / `.bt2l` — Index files from `bowtie2-build`

## Related Tools

- [bwa](bwa.md) — Alternative short-read aligner (preferred for WGS)
- [hisat2](hisat2.md) — Splice-aware aligner (RNA-seq)
- [samtools](samtools.md) — Post-alignment processing
