# FastQC

**Source:** [bioinformatics.babraham.ac.uk/projects/fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)  
**License:** GPL-2.0+  
**Category:** Quality control

## Purpose

Quality assessment tool for high-throughput sequencing data. Produces visual HTML reports showing per-base quality scores, GC content, sequence duplication levels, adapter contamination, overrepresented sequences, and other QC metrics. Essential first step before and after read preprocessing. Does **not** modify data — it is purely diagnostic.

## Installation

```bash
conda install -c bioconda fastqc
# or
brew install fastqc
```

## Usage Examples

```bash
# Analyse a single FASTQ file
fastqc reads.fastq.gz

# Analyse multiple files with output directory and threads
fastqc -o qc_reports/ -t 8 reads_R1.fastq.gz reads_R2.fastq.gz

# Analyse all FASTQ files in a directory
fastqc -o qc_reports/ -t 8 raw_data/*.fastq.gz

# Run on BAM file (extracts sequences internally)
fastqc aligned.bam

# Non-interactive mode (suppress GUI), don't extract zip
fastqc --noextract -o qc_reports/ reads.fastq.gz

# Specify custom adapter file
fastqc --adapters custom_adapters.txt -o qc_reports/ reads.fastq.gz

# Specify custom contaminant list
fastqc --contaminants custom_contaminants.txt reads.fastq.gz

# Set memory limit (default 512MB)
fastqc --memory 1024 reads.fastq.gz
```

## Key Options

| Option             | Description                                         |
| ------------------ | --------------------------------------------------- |
| `-o DIR`           | Output directory                                    |
| `-t INT`           | Number of files to process simultaneously           |
| `--noextract`      | Don't unzip output files                            |
| `--nogroup`        | Disable grouping of bases for reads >50bp           |
| `-f FORMAT`        | Force input format: fastq, bam, sam                 |
| `--adapters FILE`  | Custom adapter file (tab: `name\tsequence`)         |
| `--contaminants FILE` | Custom contaminant file                          |
| `--limits FILE`    | Custom warn/fail thresholds for each module         |
| `--kmers INT`      | K-mer length (default 7, max 10)                    |
| `-q`               | Quiet mode (errors only)                            |

## Produces

- `*_fastqc.html` — Interactive HTML report (self-contained, no dependencies)
- `*_fastqc.zip` — Zip containing images, summary.txt, and fastqc_data.txt

### Inside the ZIP

```text
sample_fastqc/
├── fastqc_data.txt      ← Machine-parseable raw data (all modules)
├── fastqc_report.html   ← HTML report (same as standalone)
├── summary.txt          ← PASS/WARN/FAIL per module (tab-delimited)
└── Images/
    ├── per_base_quality.png
    ├── per_sequence_quality.png
    └── ...
```

The `summary.txt` file is useful for automated pass/fail decisions:

```bash
# Quick check: any module failures?
unzip -p sample_fastqc.zip sample_fastqc/summary.txt | grep FAIL
```

## QC Modules — Detailed Interpretation

### Per Base Sequence Quality

**What it shows:** Box plot of Phred quality scores at each position across all reads.

**Healthy pattern:** Scores ≥28 across all positions (slight decline at read ends is normal for Illumina).

**Problem indicators:**

| Pattern                         | Likely Cause                     | Action                       |
| ------------------------------- | -------------------------------- | ---------------------------- |
| Steady decline after position X | Sequencing chemistry degradation | Trim with SLIDINGWINDOW      |
| Low quality at positions 1-5    | Calibration instability          | LEADING trim or HEADCROP     |
| Sudden drop at specific cycle   | Bubble/focus issue on flowcell   | Consider re-sequencing       |
| All bases low (<20)             | Overclustering, reagent failure  | Check sequencing run metrics |

### Per Sequence Quality Scores

**What it shows:** Distribution of mean quality per read.

**Healthy pattern:** Single peak at Q≥30. Most reads should have mean quality ≥27.

**Problem indicators:** Bimodal distribution suggests a subset of reads failed (lane issue, mixed library).

### Per Base Sequence Content

**What it shows:** Proportion of A/T/G/C at each position.

**Healthy pattern:** Lines roughly parallel (each ~25% for random library), except positions 1-12 which often show bias from random hexamer priming.

**Expected failures (not a problem):**

- RNA-seq: first 10-12bp show priming bias (normal for random hexamers)
- Bisulfite-seq: extreme C/T bias (by design — C→T conversion)
- Amplicon/targeted: non-random start positions

### Per Sequence GC Content

**What it shows:** GC% distribution of all reads, overlaid with theoretical normal distribution.

**Healthy pattern:** Bell curve matching the expected genome GC content (~40% for human).

**Problem indicators:**

| Pattern                    | Likely Cause                                 |
| -------------------------- | -------------------------------------------- |
| Sharp secondary peak       | Adapter contamination or specific contaminant|
| Broad shift from expected  | Library contamination (different organism)    |
| Wide/multi-modal           | Mixed species contamination                  |

### Sequence Duplication Levels

**What it shows:** Percentage of reads appearing multiple times (exact duplicates).

**Healthy pattern:** Most sequences appear once (high proportion in "1" bin).

**Context-dependent interpretation:**

| Library Type       | Expected Duplication | Why                               |
| ------------------ | -------------------- | --------------------------------- |
| WGS (deep)         | 5-30%                | PCR duplicates, depends on depth  |
| RNA-seq            | 30-80%               | Highly expressed genes = real dups |
| ChIP-seq           | 5-50%                | Enrichment = real duplicates      |
| Amplicon           | >90%                 | Expected (all reads from same amplicon) |
| Low-input library  | 30-60%               | Limited starting material → more PCR |

**Key insight:** FastQC only counts exact sequence matches. For RNA-seq, "duplicates" are often independent transcripts from highly-expressed genes — they are **not** PCR artifacts.

### Overrepresented Sequences

**What it shows:** Sequences comprising >0.1% of total reads. FastQC checks against a database of common contaminants.

**Action items:**

| Identified As              | Action                                          |
| -------------------------- | ----------------------------------------------- |
| TruSeq Adapter             | Adapter trimming needed                         |
| Nextera Transposase        | Adapter trimming needed                         |
| No hit (poly-A)            | Poly-A trimming or rRNA depletion issue         |
| No hit (check BLAST)       | BLAST the sequence to identify contaminant      |

```bash
# BLAST an overrepresented sequence to identify it
echo "AGATCGGAAGAGCACACGTCTGAACTCCAGTCA" | \
  blastn -db nt -remote -outfmt 6 | head -5
```

### Adapter Content

**What it shows:** Cumulative percentage of reads containing adapter sequence at each position.

**Healthy pattern:** All lines near 0% (no adapter contamination).

**Problem patterns:**

| Pattern                          | Meaning                                       |
| -------------------------------- | --------------------------------------------- |
| Lines rising from right side     | Reads longer than inserts (standard adapters) |
| Lines rising from left side      | Adapter-dimer / very short inserts            |
| Plateau at high percentage       | Severe adapter contamination                  |

**Adapters checked by default:** Illumina Universal, Illumina Small RNA 3', Illumina Small RNA 5', Nextera Transposase, SOLID Small RNA.

### Other Modules

| Module                       | Checks                                      | Common Cause of Failure          |
| ---------------------------- | ------------------------------------------- | -------------------------------- |
| Per base N content           | Proportion of uncalled bases (N) per position | Flowcell issues, degradation    |
| Sequence length distribution | Variation in read lengths                    | Post-trimming data, variable length sequencing |
| K-mer content                | Positional k-mer bias                        | Adapters, library prep artifacts |

## Interpreting Results — Decision Framework

```text
                    ┌─────────────────────┐
                    │    Run FastQC        │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
      All modules PASS    Warnings only    Failures present
              │                │                 │
              ▼                ▼                 ▼
       Proceed to         Check if expected   Identify root cause:
       alignment          for library type    ├─ Adapter Content → trim
                          (RNA-seq, ChIP)     ├─ Base Quality → trim
                                              ├─ GC Content → contamination?
                                              ├─ Overrep seqs → adapter/rRNA
                                              └─ Duplication → library issue?
```

### Which Failures Are OK to Ignore?

| Module                      | OK to ignore when...                            |
| --------------------------- | ----------------------------------------------- |
| Per base sequence content   | RNA-seq (first 12bp bias is normal)             |
| Sequence duplication levels | RNA-seq, ChIP-seq (biological duplicates)       |
| Per sequence GC content     | RNA-seq (transcriptome ≠ genome GC)             |
| K-mer content               | Any enrichment library (by design)              |
| Sequence length distribution| Post-trimming data (expected variation)         |

## Automation — Parsing FastQC Output

```bash
# Extract pass/fail summary from multiple reports
for zip in qc_reports/*_fastqc.zip; do
  sample=$(basename "$zip" _fastqc.zip)
  echo "=== $sample ==="
  unzip -p "$zip" "*/summary.txt"
done

# Find samples with adapter contamination
for zip in qc_reports/*_fastqc.zip; do
  result=$(unzip -p "$zip" "*/summary.txt" | grep "Adapter" | cut -f1)
  if [ "$result" = "FAIL" ]; then
    echo "ADAPTER PROBLEM: $(basename "$zip")"
  fi
done

# Extract numeric data for custom analysis
unzip -p sample_fastqc.zip sample_fastqc/fastqc_data.txt | \
  sed -n '/>>Per base sequence quality/,/>>END_MODULE/p'
```

## Performance

| Metric        | Typical Value                          |
| ------------- | -------------------------------------- |
| Speed         | ~3 minutes per 50M read FASTQ         |
| Memory        | 512MB default (adjustable)             |
| Parallelism   | `-t N` processes N files simultaneously|
| Input formats | FASTQ, BAM, SAM (auto-detected)       |

**Note:** `-t` parallelises across **files**, not within a single file. For a single large file, FastQC is single-threaded.

## Related Tools

| Tool                           | Relationship                                     |
| ------------------------------ | ------------------------------------------------ |
| [MultiQC](multiqc.md)         | Aggregates multiple FastQC reports into one       |
| [fastp](fastp.md)             | Combined QC + trimming (produces similar metrics) |
| [trimmomatic](trimmomatic.md) | Trimming to fix issues found by FastQC            |
| [cutadapt](cutadapt.md)       | Adapter removal identified by FastQC              |
