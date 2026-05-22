# FastQC

**Source:** [bioinformatics.babraham.ac.uk/projects/fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)  
**License:** GPL-2.0+  
**Category:** Quality control

## Purpose

Quality assessment tool for high-throughput sequencing data. Produces visual HTML reports showing per-base quality scores, GC content, sequence duplication levels, adapter contamination, overrepresented sequences, and other QC metrics. Essential first step before and after read preprocessing.

## Installation

```bash
conda install -c bioconda fastqc
# or
brew install fastqc
```

## QC Modules

| Module                       | What it checks                        |
| ---------------------------- | ------------------------------------- |
| Per base sequence quality    | Quality scores across all bases       |
| Per sequence quality scores  | Distribution of mean quality per read |
| Per base sequence content    | A/T/G/C proportion per position       |
| Per sequence GC content      | GC distribution vs theoretical        |
| Per base N content           | Uncalled bases per position           |
| Sequence length distribution | Read length distribution              |
| Sequence duplication levels  | Library complexity                    |
| Overrepresented sequences    | Contaminants / adapters               |
| Adapter content              | Known adapter sequence presence       |

## Usage Examples

```bash
# Analyse a single FASTQ file
fastqc reads.fastq.gz

# Analyse multiple files with output directory
fastqc -o qc_reports/ -t 8 reads_R1.fastq.gz reads_R2.fastq.gz

# Analyse all FASTQ files in a directory
fastqc -o qc_reports/ -t 8 raw_data/*.fastq.gz

# Run on BAM file (extracts sequences internally)
fastqc aligned.bam

# Non-interactive mode (suppress GUI)
fastqc --noextract -o qc_reports/ reads.fastq.gz
```

## Produces

- `*_fastqc.html` — Interactive HTML report
- `*_fastqc.zip` — Zip containing images + summary data

## Interpreting Results

- **Green tick** — Pass
- **Yellow exclamation** — Warning (review recommended)
- **Red cross** — Fail (investigate further)

Note: Some "failures" are expected (e.g., RNA-seq often fails GC content and duplication checks).

## Related Tools

- [multiqc](multiqc.md) — Aggregate multiple FastQC reports
- [fastp](fastp.md) — Combined QC + trimming in one step
- [trimmomatic](trimmomatic.md) — Trimming to fix issues found by FastQC
