# MultiQC

**Source:** [multiqc.info](https://multiqc.info/)  
**License:** GPL-3.0  
**Category:** QC report aggregation

## Purpose

Aggregates results from multiple bioinformatics tools into a single interactive HTML report. Searches a directory for analysis logs and compiles them into plots and tables comparing all samples. Supports 100+ tools including FastQC, STAR, samtools, Picard, featureCounts, and many more.

## Installation

```bash
conda install -c bioconda multiqc
# or
pip install multiqc
```

## Supported Tools (Selection)

| Category | Tools |
|----------|-------|
| QC | FastQC, fastp, Cutadapt |
| Alignment | STAR, HISAT2, Bowtie2, BWA, samtools |
| Duplicates | Picard MarkDuplicates |
| Quantification | featureCounts, HTSeq, Salmon, Kallisto |
| Variant calling | bcftools stats, GATK, VCFtools |
| Trimming | Trimmomatic, fastp |

## Usage Examples

```bash
# Run on current directory (recursive search for tool outputs)
multiqc .

# Specify output directory and filename
multiqc . -o multiqc_output/ -n my_project_report

# Search specific directories
multiqc fastqc_results/ star_logs/ picard_metrics/

# Force overwrite existing report
multiqc . --force

# Flat image output (no interactive plots)
multiqc . --flat

# Export data tables as TSV
multiqc . --export

# Exclude specific modules
multiqc . --exclude fastqc

# Include only specific modules
multiqc . -m star -m featureCounts
```

## Produces

- `multiqc_report.html` — Interactive HTML report
- `multiqc_data/` — Parsed data tables (JSON, TSV)

## Related Tools

- [fastqc](fastqc.md) — Per-sample QC (input to MultiQC)
- [fastp](fastp.md) — Preprocessing with JSON reports (input to MultiQC)
