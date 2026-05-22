# fastp

**Source:** [github.com/OpenGene/fastp](https://github.com/OpenGene/fastp)  
**License:** MIT  
**Category:** Read preprocessing / QC

## Purpose

All-in-one FASTQ preprocessor: adapter trimming, quality filtering, read deduplication, base correction, polyG/polyX trimming, UMI processing, and HTML/JSON quality reports. Faster than running FastQC + Trimmomatic separately.

## Installation

```bash
conda install -c bioconda fastp
# or
brew install fastp
```

## Key Features

- Automatic adapter detection (no adapter sequences needed)
- Per-read quality filtering
- Per-base quality trimming (sliding window)
- PolyG tail trimming (common in NextSeq/NovaSeq)
- Read deduplication
- UMI preprocessing
- Overrepresented sequence analysis
- HTML + JSON quality reports

## Usage Examples

```bash
# Basic paired-end preprocessing (auto adapter detection)
fastp -i reads_R1.fastq.gz -I reads_R2.fastq.gz \
  -o clean_R1.fastq.gz -O clean_R2.fastq.gz \
  --thread 8

# With quality filtering thresholds
fastp -i reads_R1.fastq.gz -I reads_R2.fastq.gz \
  -o clean_R1.fastq.gz -O clean_R2.fastq.gz \
  --qualified_quality_phred 20 \
  --length_required 50 \
  --thread 8

# Single-end with adapter trimming
fastp -i reads.fastq.gz -o clean.fastq.gz \
  --adapter_sequence AGATCGGAAGAGC

# With deduplication
fastp -i reads_R1.fastq.gz -I reads_R2.fastq.gz \
  -o clean_R1.fastq.gz -O clean_R2.fastq.gz \
  --dedup

# UMI preprocessing (extract UMI from read)
fastp -i reads_R1.fastq.gz -I reads_R2.fastq.gz \
  -o clean_R1.fastq.gz -O clean_R2.fastq.gz \
  --umi --umi_loc read1 --umi_len 8

# Custom report output
fastp -i reads_R1.fastq.gz -I reads_R2.fastq.gz \
  -o clean_R1.fastq.gz -O clean_R2.fastq.gz \
  --html report.html --json report.json
```

## Produces

- Trimmed FASTQ files (`.fastq.gz`)
- `fastp.html` — Interactive HTML quality report
- `fastp.json` — Machine-readable QC metrics

## Related Tools

- [fastqc](fastqc.md) — Standalone quality assessment
- [trimmomatic](trimmomatic.md) — Alternative trimmer (Java-based)
- [cutadapt](cutadapt.md) — Flexible adapter trimming
- [multiqc](multiqc.md) — Aggregate fastp JSON reports
