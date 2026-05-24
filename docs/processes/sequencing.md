# Sequencing Process

## Overview

The sequencing process converts biological DNA/RNA molecules into digital sequence data. From a computational perspective, the sequencer is an analog-to-digital converter: it transforms chemical signals (fluorescence, electrical current, or light pulses) into strings over the alphabet `{A, C, G, T, N}` with associated per-base error probabilities.

This page covers the end-to-end process from sample to FASTQ files — the raw digital input for all downstream bioinformatics.

## Sequencing Technologies

### Illumina (Sequencing by Synthesis)

The dominant short-read platform. Produces high-accuracy reads (Q30+ = <0.1% error per base) in paired-end mode.

| Platform    | Max Read Length | Output/Run | Typical Use                 |
| ----------- | --------------- | ---------- | --------------------------- |
| MiSeq       | 2×300 bp        | ~15 Gb     | Targeted, amplicon, 16S     |
| NextSeq     | 2×150 bp        | ~120 Gb    | RNA-seq, exomes             |
| NovaSeq 6000 | 2×250 bp       | ~6000 Gb   | WGS at population scale     |
| NovaSeq X   | 2×150 bp        | ~16000 Gb  | Ultra-high throughput       |

**How it works:**

1. DNA fragments bind to a flow cell and undergo bridge amplification into clusters
2. Each cycle, fluorescently-labeled nucleotides are incorporated one base at a time
3. A camera images the flow cell — each cluster emits a colour corresponding to the incorporated base
4. Software (RTA / DRAGEN) performs **base calling**: converting raw intensity images into nucleotide sequences with quality scores

**Key computational concepts:**

- **Phred quality scores** — Logarithmic encoding of error probability: $Q = -10 \log_{10}(P_{\text{error}})$. A Q30 base has a 1-in-1000 chance of being wrong.
- **Paired-end sequencing** — Both ends of a fragment are sequenced, producing R1 (forward) and R2 (reverse complement). The unsequenced middle is the "insert."
- **Index reads** — Short reads of barcode sequences used for demultiplexing pooled samples.

### PacBio (SMRT Sequencing)

Single-molecule real-time sequencing. A polymerase incorporates fluorescent nucleotides while a zero-mode waveguide detects the signal.

| Platform    | Read Length  | Accuracy (HiFi) | Output/Cell |
| ----------- | ------------ | ---------------- | ----------- |
| Sequel II   | 10–25 kb     | >Q30 (HiFi)     | ~30 Gb      |
| Revio       | 15–25 kb     | >Q30 (HiFi)     | ~90 Gb      |

**Key concepts:**

- **HiFi reads** — Circular consensus sequences (CCS) from multiple passes of the same molecule, achieving >99.9% accuracy with long reads.
- **Subreads** — Individual passes before CCS correction; higher error rate (~10-15%).

### Oxford Nanopore (Nanopore Sequencing)

DNA/RNA strands pass through a protein nanopore; changes in ionic current correspond to k-mer sequences.

| Platform  | Read Length    | Raw Accuracy | Output    |
| --------- | ------------- | ------------ | --------- |
| MinION    | Up to 4 Mb    | ~95-99%      | ~50 Gb    |
| PromethION | Up to 4 Mb   | ~95-99%      | ~290 Gb   |

**Key concepts:**

- **Real-time sequencing** — Data streams as molecules transit the pore; reads can be analysed during sequencing.
- **Base calling is a neural network problem** — Current signal → k-mer → bases. Tools: Guppy, Dorado. Accuracy improves with model updates without hardware changes.
- **Ultra-long reads** — Routinely >100 kb; useful for resolving repetitive regions and structural variants.

## Library Construction

Library construction converts source DNA/RNA into sequencer-compatible fragments. This is the wet-lab step but has major computational implications:

```text
Source DNA/RNA
  │
  ├─ Fragmentation (mechanical/enzymatic → target insert size)
  │
  ├─ End repair + A-tailing (blunt ends for adapter ligation)
  │
  ├─ Adapter ligation (platform-specific sequences)
  │     ├─ P5/P7 adapters (Illumina) — enable flow cell binding
  │     └─ Index sequences (i7/i5) — enable demultiplexing
  │
  ├─ Size selection (gel or beads → narrow size distribution)
  │
  └─ PCR amplification (optional — introduces duplicates)
        └─ PCR-free libraries preferred for WGS (reduces bias)
```

**Computational implications:**

| Library Parameter | Downstream Effect                                |
| ----------------- | ------------------------------------------------ |
| Insert size       | Determines read overlap (short) vs gap (long)    |
| PCR cycles        | More cycles → more duplicates → more to remove   |
| Adapter type      | Must be correctly trimmed or causes misalignment |
| Index sequences   | Incorrect assignment → sample cross-contamination |

## Demultiplexing

When multiple samples are pooled on one sequencing run, **demultiplexing** assigns each read to its sample of origin based on index (barcode) sequences.

```bash
# Illumina: bcl2fastq or DRAGEN demultiplexes BCL files into per-sample FASTQs
bcl2fastq --runfolder-dir /path/to/run \
  --output-dir /path/to/fastqs \
  --sample-sheet SampleSheet.csv

# Result: one pair of FASTQ files per sample
# SampleA_S1_L001_R1_001.fastq.gz  (forward reads)
# SampleA_S1_L001_R2_001.fastq.gz  (reverse reads)
```

**Naming convention:** `{SampleName}_S{number}_L{lane}_R{read}_001.fastq.gz`

## Base Calling and Phred Scores

### The Phred Quality System

Every base in a FASTQ file has an associated quality score encoding the probability of a base-call error:

| Phred Score | Error Probability | Accuracy  | ASCII (Sanger/Illumina 1.8+) |
| ----------- | ----------------- | --------- | ----------------------------- |
| Q10         | 1 in 10           | 90%       | `+`                           |
| Q20         | 1 in 100          | 99%       | `5`                           |
| Q30         | 1 in 1,000        | 99.9%     | `?`                           |
| Q40         | 1 in 10,000       | 99.99%    | `I`                           |

**Encoding:** ASCII character = quality score + 33 (Phred+33, the current standard).

```
Quality:  0  10  20  30  40
ASCII:    !   +   5   ?   I
```

### FASTQ Format — The Primary Output

Each read is 4 lines:

```
@SEQ_ID                          ← Read identifier
GATCGATCGATCGATCGATC             ← Nucleotide sequence
+                                ← Separator
IIIIIHHHHHGGGGGFFFFF             ← Quality scores (one per base)
```

See [FASTQ format](../formats/fastq.md) for full specification.

## Data Volume and Storage

Understanding data volumes is critical for planning compute and storage:

| Experiment       | Samples | Reads/Sample  | Size/Sample (gz) | Total    |
| ---------------- | ------- | ------------- | ---------------- | -------- |
| WGS 30× human   | 1       | ~900M PE      | ~90 GB           | ~90 GB   |
| WES 100×         | 1       | ~100M PE      | ~10 GB           | ~10 GB   |
| RNA-seq          | 1       | ~30-50M PE    | ~3-5 GB          | ~3-5 GB  |
| ChIP-seq         | 1       | ~20-40M SE    | ~2-4 GB          | ~2-4 GB  |
| 16S amplicon     | 100     | ~100K PE      | ~50 MB           | ~5 GB    |

**Compression:** Raw FASTQ files are always gzip-compressed (`.fastq.gz`). Expect ~3-4× compression ratio.

## End-to-End Pipeline: Sequencer to Clean FASTQ

```text
┌─────────────────┐
│   Sequencer     │  Raw signal (BCL, FAST5, BAM)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Base Calling   │  bcl2fastq, DRAGEN, Dorado, Guppy
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Demultiplexing  │  Assign reads to samples via index
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Quality Control │  FastQC → assess raw data quality
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Preprocessing  │  fastp / Trimmomatic / Cutadapt
│  (trim+filter)  │  Remove adapters, low-quality bases
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Post-trim QC    │  FastQC → verify improvement
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    MultiQC      │  Aggregate all QC into one report
└────────┬────────┘
         │
         ▼
   Clean FASTQ files ready for alignment
```

## Practical Commands

```bash
# 1. Run initial QC on raw reads
fastqc -o qc_raw/ -t 8 raw/*.fastq.gz

# 2. Preprocess with fastp (recommended: does QC + trim in one pass)
fastp -i raw/sample_R1.fastq.gz -I raw/sample_R2.fastq.gz \
  -o clean/sample_R1.fastq.gz -O clean/sample_R2.fastq.gz \
  --detect_adapter_for_pe \
  --qualified_quality_phred 20 \
  --length_required 50 \
  --thread 8 \
  --html reports/sample_fastp.html \
  --json reports/sample_fastp.json

# 3. Verify improvement with post-trim QC
fastqc -o qc_clean/ -t 8 clean/*.fastq.gz

# 4. Aggregate all reports
multiqc qc_raw/ qc_clean/ reports/ -o multiqc_output/
```

## Tools Involved

| Tool                                   | Role                                                  |
| -------------------------------------- | ----------------------------------------------------- |
| [FastQC](../tools/fastqc.md)           | Quality assessment (before and after trimming)        |
| [fastp](../tools/fastp.md)             | All-in-one preprocessing (adapter trim + QC + filter) |
| [Trimmomatic](../tools/trimmomatic.md) | Java-based trimming (legacy, still widely used)       |
| [Cutadapt](../tools/cutadapt.md)       | Precise adapter removal (handles complex adapters)    |
| [MultiQC](../tools/multiqc.md)         | Aggregates QC reports across all samples              |
| [SeqKit](../tools/seqkit.md)           | FASTQ statistics, filtering, format conversion        |

## Key Concepts for Computer Scientists

| Concept              | Analogy / Explanation                                                               |
| -------------------- | ----------------------------------------------------------------------------------- |
| Phred score          | Confidence level as $-10 \log_{10}(p)$; like a log-likelihood ratio                |
| Coverage depth       | Redundancy factor — how many independent reads cover each genome position           |
| Paired-end reads     | Two observations of the same fragment — constrains insert size during alignment     |
| PCR duplicates       | Copies of the same original molecule — redundant data that inflates variant support |
| Multiplexing         | Time-division multiplexing analogy — multiple samples share one sequencing run      |
| GC bias              | Systematic sampling bias — some sequence compositions are over/under-represented    |