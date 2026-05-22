# Picard

**Source:** [broadinstitute.github.io/picard](https://broadinstitute.github.io/picard/)  
**License:** MIT  
**Category:** BAM manipulation / QC metrics

## Purpose

Java-based toolkit from the Broad Institute for manipulating SAM/BAM files and collecting sequencing metrics. Key functions include duplicate marking, BAM sorting/merging, collecting insert size and alignment metrics, and format validation. Frequently used in GATK best-practices pipelines.

## Installation

```bash
conda install -c bioconda picard
```

## Key Tools

| Tool | Description |
|------|-------------|
| `MarkDuplicates` | Mark/remove PCR and optical duplicates |
| `CollectAlignmentSummaryMetrics` | Alignment QC metrics |
| `CollectInsertSizeMetrics` | Insert size distribution |
| `CollectWgsMetrics` | Whole-genome coverage metrics |
| `SortSam` | Sort SAM/BAM by coordinate or name |
| `MergeSamFiles` | Merge multiple BAM files |
| `AddOrReplaceReadGroups` | Add/fix read group headers |
| `CreateSequenceDictionary` | Create .dict for reference FASTA |
| `ValidateSamFile` | Validate BAM file correctness |
| `CollectGcBiasMetrics` | GC bias analysis |

## Usage Examples

```bash
# Mark PCR duplicates
picard MarkDuplicates \
  I=aligned.sorted.bam \
  O=marked.bam \
  M=dup_metrics.txt

# Collect alignment summary metrics
picard CollectAlignmentSummaryMetrics \
  I=aligned.sorted.bam \
  R=reference.fa \
  O=alignment_metrics.txt

# Collect insert size metrics
picard CollectInsertSizeMetrics \
  I=aligned.sorted.bam \
  O=insert_size_metrics.txt \
  H=insert_size_histogram.pdf

# Create sequence dictionary for reference (required by GATK)
picard CreateSequenceDictionary \
  R=reference.fa \
  O=reference.dict

# Add read groups
picard AddOrReplaceReadGroups \
  I=aligned.bam \
  O=with_rg.bam \
  RGID=1 RGLB=lib1 RGPL=ILLUMINA RGPU=unit1 RGSM=sample1

# Validate BAM file
picard ValidateSamFile I=aligned.bam MODE=SUMMARY
```

## Produces

- Marked/sorted BAM files
- `.dict` — Sequence dictionary for FASTA reference
- Metrics text files (tab-delimited, parseable by MultiQC)
- PDF histograms

## Related Tools

- [samtools](samtools.md) — Lighter-weight BAM manipulation (markdup, sort)
- [gatk](gatk.md) — Uses Picard internally; downstream variant calling
- [multiqc](multiqc.md) — Aggregates Picard metrics into reports
