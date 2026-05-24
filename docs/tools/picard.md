# Picard

**Source:** [broadinstitute.github.io/picard](https://broadinstitute.github.io/picard/)  
**License:** MIT  
**Category:** BAM manipulation / QC metrics

## Purpose

Java-based toolkit from the Broad Institute for manipulating SAM/BAM files and collecting sequencing metrics. Key functions include duplicate marking, BAM sorting/merging, collecting insert size and alignment metrics, and format validation. Core component of GATK best-practices pipelines — many GATK tools require Picard-prepared inputs (read groups, duplicates marked, sequence dictionary present).

## Installation

```bash
conda install -c bioconda picard
# or (via GATK which bundles Picard)
conda install -c bioconda gatk4
```

## Key Tools

| Tool                             | Description                            | When to Use                        |
| -------------------------------- | -------------------------------------- | ---------------------------------- |
| `MarkDuplicates`                 | Mark/remove PCR and optical duplicates | Always before variant calling      |
| `CollectAlignmentSummaryMetrics` | Alignment QC metrics                   | Post-alignment QC                  |
| `CollectInsertSizeMetrics`       | Insert size distribution               | PE library validation              |
| `CollectWgsMetrics`              | Whole-genome coverage metrics          | WGS coverage assessment            |
| `CollectRnaSeqMetrics`           | RNA-seq specific metrics               | RNA-seq QC                         |
| `CollectGcBiasMetrics`           | GC bias analysis                       | Library quality assessment         |
| `SortSam`                        | Sort SAM/BAM by coordinate or name     | Pipeline preparation               |
| `MergeSamFiles`                  | Merge multiple BAM files               | Combining lanes/replicates         |
| `AddOrReplaceReadGroups`         | Add/fix read group headers             | GATK compatibility                 |
| `CreateSequenceDictionary`       | Create .dict for reference FASTA       | Required by GATK                   |
| `ValidateSamFile`                | Validate BAM file correctness          | Debugging pipeline issues          |
| `BuildBamIndex`                  | Create BAI index                       | When samtools index is unavailable |
| `ReorderSam`                     | Reorder BAM to match reference dict    | Cross-reference compatibility      |
| `FixMateInformation`             | Fix mate pair information              | After BAM manipulation             |

## MarkDuplicates (In Depth)

### What Are Duplicates?

PCR duplicates are read pairs originating from the same original DNA fragment, amplified during library preparation:

```text
Original fragment:     ──────────────────────
                       ↓ PCR amplification
PCR copies (identical):──────────────────────
                       ──────────────────────
                       ──────────────────────

All copies align to same position with same insert size
→ Count as ONE observation, not four
```

**Why mark them:** Duplicates inflate coverage at specific positions, biasing variant allele frequencies and creating false confidence in variant calls.

### Detection Algorithm

Picard identifies duplicates by comparing:
1. **5' position** of both mates (or single read)
2. **Orientation** (F1R2 vs F2R1)
3. **Library** (from read group @RG LB tag)

Reads with identical (position, orientation, library) tuple are duplicates. The read with the **highest sum of base qualities** is kept as the representative; others are flagged (FLAG 0x400).

### Optical Duplicates

A subset of duplicates caused by optical/sensor proximity on the flowcell (not PCR):

```bash
# Mark duplicates with optical duplicate distance (for patterned flowcells)
picard MarkDuplicates \
  I=aligned.sorted.bam \
  O=marked.bam \
  M=dup_metrics.txt \
  OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500   # For HiSeq 4000 / NovaSeq

# Default pixel distance is 100 (appropriate for older non-patterned flowcells)
```

| Platform                  | Recommended Pixel Distance |
| ------------------------- | -------------------------- |
| HiSeq 2500 (non-patterned) | 100 (default)            |
| HiSeq 4000 / X (patterned) | 2500                     |
| NovaSeq 6000              | 2500                       |
| NextSeq 500/550           | 100                        |

### MarkDuplicates Usage

```bash
# Standard duplicate marking
picard MarkDuplicates \
  I=aligned.sorted.bam \
  O=marked.bam \
  M=dup_metrics.txt \
  REMOVE_DUPLICATES=false \
  ASSUME_SORTED=true

# Remove duplicates entirely (for some analyses)
picard MarkDuplicates \
  I=aligned.sorted.bam \
  O=deduped.bam \
  M=dup_metrics.txt \
  REMOVE_DUPLICATES=true

# Handle multiple input BAMs (merged before dedup)
picard MarkDuplicates \
  I=lane1.sorted.bam \
  I=lane2.sorted.bam \
  O=merged_marked.bam \
  M=dup_metrics.txt
```

### MarkDuplicates Metrics

```text
LIBRARY  UNPAIRED_READS_EXAMINED  READ_PAIRS_EXAMINED  UNMAPPED_READS  ...
lib1     123456                   15000000             50000           ...

...  UNPAIRED_READ_DUPLICATES  READ_PAIR_DUPLICATES  READ_PAIR_OPTICAL_DUPLICATES  PERCENT_DUPLICATION
...  12345                     2250000               150000                        0.15
```

**Key metrics:**
- `PERCENT_DUPLICATION`: Overall duplicate rate (WGS: 5-30% typical; >50% = library issue)
- `READ_PAIR_OPTICAL_DUPLICATES`: Should be small fraction of total duplicates
- `ESTIMATED_LIBRARY_SIZE`: Extrapolated unique fragments in library

## Collecting Metrics

### CollectAlignmentSummaryMetrics

```bash
picard CollectAlignmentSummaryMetrics \
  I=aligned.sorted.bam \
  R=reference.fa \
  O=alignment_metrics.txt
```

Output includes metrics per category (PAIR, FIRST_OF_PAIR, SECOND_OF_PAIR, UNPAIRED):

| Metric                     | Description                              | Healthy Range |
| -------------------------- | ---------------------------------------- | ------------- |
| PF_ALIGNED_BASES           | Total aligned bases (PF = passing filter) | —            |
| PCT_PF_READS_ALIGNED       | % reads aligned                           | >95%         |
| PCT_READS_ALIGNED_IN_PAIRS | % aligned as proper pairs                 | >90%         |
| PF_MISMATCH_RATE           | Mismatch rate vs reference                | <1%          |
| PF_INDEL_RATE              | Indel rate                                | <0.1%        |
| MEAN_READ_LENGTH           | Average read length post-alignment        | —            |
| PCT_CHIMERAS               | Chimeric read rate                        | <5%          |

### CollectInsertSizeMetrics

```bash
picard CollectInsertSizeMetrics \
  I=aligned.sorted.bam \
  O=insert_size_metrics.txt \
  H=insert_size_histogram.pdf
```

**Interpretation:**
- **MEDIAN_INSERT_SIZE**: Should match library prep target (typically 200-500bp)
- **Standard deviation**: Tight distribution = good library. Wide/bimodal = problem
- **Histogram shape**: Single Gaussian peak = healthy. Multiple peaks = mixed libraries or adapter contamination

```text
MEDIAN_INSERT_SIZE  MODE_INSERT_SIZE  MEAN_INSERT_SIZE  STANDARD_DEVIATION
350                 345               352.5             75.3
```

### CollectWgsMetrics

```bash
picard CollectWgsMetrics \
  I=aligned.sorted.bam \
  R=reference.fa \
  O=wgs_metrics.txt
```

| Metric                 | Description                                | Healthy WGS 30× |
| ---------------------- | ------------------------------------------ | ---------------- |
| MEAN_COVERAGE          | Mean depth across genome                   | ~30              |
| SD_COVERAGE            | Coverage standard deviation                | <15              |
| PCT_EXC_DUPE           | % bases excluded due to duplicates         | <15%             |
| PCT_EXC_MAPQ           | % bases excluded due to low MAPQ           | <5%              |
| PCT_10X / PCT_20X / PCT_30X | % genome covered at ≥10/20/30×       | >95% / >90% / >70% |

### CollectRnaSeqMetrics

```bash
picard CollectRnaSeqMetrics \
  I=aligned.sorted.bam \
  REF_FLAT=refFlat.txt \
  STRAND=SECOND_READ_TRANSCRIPTION_STRAND \
  O=rnaseq_metrics.txt
```

| Metric                    | Description                          | Healthy Range |
| ------------------------- | ------------------------------------ | ------------- |
| PCT_CODING_BASES          | % bases in CDS                       | 40-60%        |
| PCT_UTR_BASES             | % bases in UTR                       | 20-40%        |
| PCT_INTRONIC_BASES        | % bases in introns                   | 10-30%        |
| PCT_INTERGENIC_BASES      | % bases in intergenic regions        | <15%          |
| PCT_RIBOSOMAL_BASES       | % rRNA contamination                 | <5%           |
| MEDIAN_5PRIME_TO_3PRIME_BIAS | Uniformity of transcript coverage | 0.8-1.2       |

## Reference Preparation

```bash
# Create sequence dictionary (required by GATK/Picard)
picard CreateSequenceDictionary \
  R=reference.fa \
  O=reference.dict

# Result: reference.dict contains @SQ headers with lengths and MD5 checksums
# Most GATK tools require: reference.fa + reference.fa.fai + reference.dict
```

## Read Groups

Read groups are **mandatory** for GATK variant calling. They identify which sequencing run/lane/library/sample a read came from:

```bash
# Add read groups to a BAM missing them
picard AddOrReplaceReadGroups \
  I=aligned.bam \
  O=with_rg.bam \
  RGID=flowcell1.lane2 \
  RGLB=library1 \
  RGPL=ILLUMINA \
  RGPU=flowcell1.lane2.ACGTACGT \
  RGSM=sample1
```

| Tag  | Meaning           | Example               | Used By                     |
| ---- | ----------------- | --------------------- | --------------------------- |
| `ID` | Read group ID     | `H0164.2`            | Distinguishing runs/lanes   |
| `SM` | Sample name       | `patient_001`         | GATK sample identification  |
| `LB` | Library           | `lib_WGS_01`         | Duplicate detection scope   |
| `PL` | Platform          | `ILLUMINA`            | Base quality recalibration  |
| `PU` | Platform unit     | `H0164ALXX140820.2`  | BQSR model grouping        |

## Validation

```bash
# Quick validation (summary mode)
picard ValidateSamFile I=aligned.bam MODE=SUMMARY

# Verbose validation (every error)
picard ValidateSamFile I=aligned.bam MODE=VERBOSE MAX_OUTPUT=100

# Ignore specific warnings
picard ValidateSamFile I=aligned.bam \
  IGNORE=MISSING_TAG_NM \
  IGNORE=MATE_NOT_FOUND
```

Common validation errors and fixes:

| Error                        | Meaning                              | Fix                             |
| ---------------------------- | ------------------------------------ | ------------------------------- |
| MISSING_READ_GROUP           | No @RG header                        | AddOrReplaceReadGroups          |
| MATE_NOT_FOUND               | Mate record missing                  | FixMateInformation or re-sort   |
| RECORD_MISSING_READ_GROUP    | Read lacks RG tag                    | AddOrReplaceReadGroups          |
| MISMATCH_FLAG_MATE_NEG_STRAND | Mate strand info inconsistent      | FixMateInformation              |
| INVALID_CIGAR                | Malformed CIGAR string               | Re-align                        |

## Java Memory

Picard is Java-based. For large BAMs, increase heap size:

```bash
# Set Java heap memory (default may be too low)
picard -Xmx16g MarkDuplicates I=large.bam O=marked.bam M=metrics.txt

# Or via environment variable
export _JAVA_OPTIONS="-Xmx16g"
picard MarkDuplicates ...

# Specify temp directory for large sorts (avoid /tmp filling up)
picard MarkDuplicates \
  I=large.bam O=marked.bam M=metrics.txt \
  TMP_DIR=/scratch/tmp
```

## Produces

- Marked/sorted/merged BAM files
- `.dict` — Sequence dictionary for FASTA reference
- `.bai` — BAM index files
- Metrics text files (tab-delimited, parseable by MultiQC)
- PDF histograms (insert size, GC bias)

## Related Tools

| Tool                         | Relationship                                      |
| ---------------------------- | ------------------------------------------------- |
| [samtools](samtools.md)      | Lighter-weight alternative for sort/index/markdup |
| [GATK](gatk.md)             | Downstream; requires Picard-prepared inputs       |
| [MultiQC](multiqc.md)       | Aggregates all Picard metrics into HTML reports   |
| [deepTools](deeptools.md)   | Complements with coverage-based QC                |
