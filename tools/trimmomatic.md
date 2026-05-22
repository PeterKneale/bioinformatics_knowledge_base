# Trimmomatic

**Source:** [usadellab.org/cms/?page=trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic)  
**License:** GPL-3.0  
**Category:** Read preprocessing

## Purpose

Java-based flexible read trimming tool for Illumina sequencing data. Applies a series of trimming steps in order: adapter removal, quality trimming (sliding window or leading/trailing), minimum length filtering, and crop/headcrop operations.

## Installation

```bash
conda install -c bioconda trimmomatic
```

## Trimming Steps

| Step | Description |
|------|-------------|
| `ILLUMINACLIP` | Remove adapter sequences |
| `SLIDINGWINDOW` | Trim once average quality in window drops below threshold |
| `LEADING` | Remove low-quality bases from start |
| `TRAILING` | Remove low-quality bases from end |
| `MINLEN` | Drop reads shorter than threshold |
| `CROP` | Cut read to specified length |
| `HEADCROP` | Remove N bases from start |
| `AVGQUAL` | Drop reads below average quality |

## Usage Examples

```bash
# Paired-end trimming
trimmomatic PE -threads 8 -phred33 \
  reads_R1.fastq.gz reads_R2.fastq.gz \
  paired_R1.fastq.gz unpaired_R1.fastq.gz \
  paired_R2.fastq.gz unpaired_R2.fastq.gz \
  ILLUMINACLIP:TruSeq3-PE-2.fa:2:30:10:2:True \
  SLIDINGWINDOW:4:20 \
  LEADING:3 \
  TRAILING:3 \
  MINLEN:36

# Single-end trimming
trimmomatic SE -threads 8 -phred33 \
  reads.fastq.gz trimmed.fastq.gz \
  ILLUMINACLIP:TruSeq3-SE.fa:2:30:10 \
  SLIDINGWINDOW:4:20 \
  MINLEN:36

# Aggressive quality trimming for variant calling
trimmomatic PE -threads 8 \
  reads_R1.fastq.gz reads_R2.fastq.gz \
  paired_R1.fastq.gz unpaired_R1.fastq.gz \
  paired_R2.fastq.gz unpaired_R2.fastq.gz \
  ILLUMINACLIP:TruSeq3-PE-2.fa:2:30:10:2:True \
  SLIDINGWINDOW:4:25 \
  LEADING:10 \
  TRAILING:10 \
  MINLEN:50
```

## Notes

- Trimming steps are applied **in order** — sequence matters
- Adapter FASTA files are bundled with the installation
- `2:30:10` in ILLUMINACLIP = seed mismatches : palindrome threshold : simple threshold

## Produces

- Trimmed FASTQ files (paired and unpaired outputs for PE mode)

## Related Tools

- [fastp](fastp.md) — Faster all-in-one alternative (C++)
- [cutadapt](cutadapt.md) — Flexible adapter removal
- [fastqc](fastqc.md) — QC before/after trimming
