# Quality Control Process

## Overview

Quality control (QC) in bioinformatics is a systematic validation process applied at every stage of an NGS pipeline. Its purpose is to detect technical artefacts — adapter contamination, sequencing errors, GC bias, PCR duplicates, mapping failures — before they propagate into biological conclusions.

QC is not a single step; it is a **cross-cutting concern** applied at three checkpoints:

```text
Raw FASTQ ──→ [QC₁: Read-level] ──→ Trim/Filter ──→ [QC₂: Post-trim]
                                                            │
                                                            ▼
                                              Alignment (BAM)
                                                            │
                                                            ▼
                                              [QC₃: Alignment-level]
```

## QC Stage 1: Raw Read Quality

### What to Check

Run **FastQC** on raw FASTQ files immediately after demultiplexing. This establishes baseline quality and identifies problems that trimming must fix.

```bash
fastqc -o qc_raw/ -t 8 raw_data/*.fastq.gz
```

### Key Metrics and Interpretation

#### Per-Base Sequence Quality

Shows Phred quality score distribution at each position along the read.

| Pattern                          | Interpretation                           | Action                         |
| -------------------------------- | ---------------------------------------- | ------------------------------ |
| Uniformly high (>Q28)            | Good quality across all positions        | No trimming needed             |
| Declining at 3' end              | Normal Illumina degradation              | Quality-trim 3' tails          |
| Drop at specific cycle           | Bubble/air gap in flow cell              | Hard-clip affected positions   |
| Bimodal quality at 5' end        | Adapter read-through in short inserts    | Adapter trimming required      |

**Why quality drops at 3' ends:** Illumina's sequencing-by-synthesis accumulates phasing errors over cycles. Each cycle, a small fraction of clusters fall "behind" or "ahead," creating signal noise that grows with read length.

#### Per-Base Sequence Content

Shows the proportion of A, T, G, C at each position. In random genomic DNA, these should be approximately equal (~25% each).

| Pattern                         | Interpretation                           | Concern Level |
| ------------------------------- | ---------------------------------------- | ------------- |
| Flat lines at ~25%              | Unbiased random library                  | OK - Expected    |
| Bias in first 10-15 bp          | Random hexamer priming bias (RNA-seq)    | OK - Normal      |
| Strong A/T or G/C bias          | Contamination or extreme GC organism     | WARN - Investigate |
| Repeating pattern               | Adapter/barcode sequence contamination   | WARN - Trim        |

#### Adapter Content

Shows cumulative percentage of reads containing adapter sequences at each position.

```text
Position:   1    50   100  150
Adapter %:  0%   0%   2%   45%   ← insert size < read length!
```

**Root cause:** When the DNA insert is shorter than the read length, the sequencer reads through into the adapter on the other end. This is common in small-RNA libraries and over-fragmented DNA.

#### Sequence Duplication Levels

Estimates library complexity by counting how many times each unique sequence appears.

| Duplication Level | Typical Library | Implication                      |
| ----------------- | --------------- | -------------------------------- |
| >80% unique       | Good WGS        | High complexity, low PCR bias    |
| 50-80% unique     | Acceptable      | Moderate duplication             |
| <50% unique       | Concerning      | Low input / too many PCR cycles  |

**Note:** RNA-seq libraries will naturally show high duplication for highly-expressed genes — this is biological, not technical.

#### GC Content Distribution

Compares the observed GC content distribution per read against a theoretical normal distribution.

| Pattern                        | Interpretation                          |
| ------------------------------ | --------------------------------------- |
| Single peak matching theory    | Clean library                           |
| Shifted peak                   | Organism with unusual GC content (OK)   |
| Secondary peak                 | Contamination (another organism)        |
| Broad/flat distribution        | Multiple contaminating organisms        |

#### Overrepresented Sequences

Lists sequences appearing at >0.1% of total reads. Common hits:

| Sequence Source     | Typical Identity                    |
| ------------------- | ----------------------------------- |
| Illumina adapters   | TruSeq, Nextera adapter remnants    |
| PCR primers         | If target-enrichment protocol used  |
| rRNA                | Common in RNA-seq without depletion |
| PhiX spike-in       | Control library bleed-through       |
| Poly-A tails        | Oligo-dT primed RNA-seq             |

### Practical QC₁ Commands

```bash
# Run FastQC on all raw files
fastqc -o qc_raw/ -t 8 raw_data/*.fastq.gz

# Quick statistics with SeqKit (faster than FastQC for basic stats)
seqkit stats raw_data/*.fastq.gz

# Check for specific contamination
# (count reads matching PhiX genome)
bowtie2 -x phix_index -U sample.fastq.gz --no-unal -S /dev/null 2>&1 | \
  grep "overall alignment rate"
```

## QC Stage 2: Post-Trimming Validation

After preprocessing (adapter removal, quality trimming, length filtering), verify the improvement:

```bash
# Trim with fastp
fastp -i raw_R1.fastq.gz -I raw_R2.fastq.gz \
  -o clean_R1.fastq.gz -O clean_R2.fastq.gz \
  --detect_adapter_for_pe \
  --qualified_quality_phred 20 \
  --unqualified_percent_limit 40 \
  --length_required 36 \
  --thread 8 \
  --json sample_fastp.json --html sample_fastp.html

# Re-run FastQC on trimmed reads
fastqc -o qc_clean/ -t 8 clean_data/*.fastq.gz
```

### What to Verify After Trimming

| Check                    | Expected Outcome                         | If Fails                        |
| ------------------------ | ---------------------------------------- | ------------------------------- |
| Adapter content          | 0% at all positions                      | Adjust adapter sequences        |
| Per-base quality         | >Q20 across all positions                | Increase quality threshold      |
| Read count retention     | >80% of raw reads retained               | Relaxing filters if too strict  |
| Read length distribution | Consistent with insert size              | Check fragmentation protocol    |
| Sequence content bias    | Reduced (5' bias may persist in RNA-seq) | Soft-clip in aligner instead    |

### fastp JSON Metrics

fastp outputs machine-readable JSON that MultiQC can parse. Key fields:

```json
{
  "summary": {
    "before_filtering": {
      "total_reads": 50000000,
      "total_bases": 7500000000,
      "q20_rate": 0.97,
      "q30_rate": 0.92,
      "gc_content": 0.45
    },
    "after_filtering": {
      "total_reads": 47500000,
      "total_bases": 6800000000,
      "q20_rate": 0.99,
      "q30_rate": 0.96,
      "gc_content": 0.44
    }
  },
  "filtering_result": {
    "passed_filter_reads": 47500000,
    "low_quality_reads": 1500000,
    "too_many_N_reads": 50000,
    "too_short_reads": 950000
  },
  "adapter_cutting": {
    "adapter_trimmed_reads": 3200000,
    "adapter_trimmed_bases": 48000000
  }
}
```

## QC Stage 3: Alignment-Level Quality

After alignment, a different set of metrics validates that reads mapped correctly and that the library performed as expected.

### samtools flagstat

Quick overview of alignment rates:

```bash
samtools flagstat aligned.sorted.bam
```

Output interpretation:

```text
50000000 + 0 in total (QC-passed reads + QC-failed reads)
49000000 + 0 mapped (98.00% : N/A)        ← % mapped reads
48000000 + 0 properly paired (96.00% : N/A)← both mates map concordantly
25000000 + 0 read1
25000000 + 0 read2
  500000 + 0 singletons (1.00% : N/A)     ← only one mate mapped
  200000 + 0 with mate mapped to a different chr
```

| Metric              | Good WGS | Concern If              |
| ------------------- | -------- | ----------------------- |
| % mapped            | >95%     | <80% (contamination?)   |
| % properly paired   | >90%     | <70% (library issue)    |
| % singletons        | <5%      | >10% (degraded DNA)     |
| % chimeric          | <2%      | >5% (ligation artefact) |

### samtools stats

Comprehensive alignment statistics:

```bash
samtools stats aligned.sorted.bam > stats.txt

# Extract key numbers
grep ^SN stats.txt | head -30
```

Key fields from `samtools stats`:

| Field                     | What It Tells You                                    |
| ------------------------- | ---------------------------------------------------- |
| raw total sequences       | Total reads in BAM                                   |
| reads mapped              | Reads with successful alignment                      |
| reads duplicated          | PCR/optical duplicate count                          |
| reads MQ0                 | Reads with MAPQ=0 (ambiguous mapping)                |
| error rate                | Mismatch rate (expect ~0.1-1% for Illumina)          |
| average length            | Mean read length after alignment                     |
| insert size average       | Mean insert size (paired-end only)                   |
| insert size standard deviation | Insert size spread (expect <20% of mean)        |

### Picard Metrics

#### Duplicate Metrics

```bash
picard MarkDuplicates \
  I=aligned.sorted.bam \
  O=marked.bam \
  M=dup_metrics.txt

# Key line in dup_metrics.txt:
# PERCENT_DUPLICATION  0.12   ← 12% duplicates
```

| Duplication Rate | Assessment                                          |
| ---------------- | --------------------------------------------------- |
| <10%             | Excellent — high-complexity PCR-free library         |
| 10-30%           | Acceptable for standard PCR libraries               |
| 30-50%           | Low input or over-amplified — results still usable  |
| >50%             | Severe — consider re-sequencing with more input DNA |

**Why duplicates matter:** PCR duplicates are copies of the same original molecule. They don't provide independent evidence for variants and inflate apparent coverage, leading to false confidence in variant calls.

#### Insert Size Distribution

```bash
picard CollectInsertSizeMetrics \
  I=aligned.sorted.bam \
  O=insert_metrics.txt \
  H=insert_histogram.pdf
```

| Pattern                        | Interpretation                              |
| ------------------------------ | ------------------------------------------- |
| Tight normal distribution      | Well-controlled fragmentation               |
| Wide or bimodal distribution   | Inconsistent fragmentation or mixed library  |
| Peak much shorter than expected | Over-fragmentation or degraded DNA          |
| Secondary peak at ~120 bp      | Adapter dimers (very short inserts)          |

#### Alignment Summary Metrics

```bash
picard CollectAlignmentSummaryMetrics \
  I=aligned.sorted.bam \
  R=reference.fa \
  O=alignment_metrics.txt
```

Reports: total reads, % aligned, % chimeras, mismatch rate, indel rate — broken out by read pair (R1/R2/pair).

### Coverage Analysis

```bash
# Per-base depth (genome-wide)
samtools depth -a aligned.sorted.bam | \
  awk '{sum+=$3; n++} END {print "Mean depth:", sum/n}'

# Coverage statistics with mosdepth (faster than samtools depth)
mosdepth --threads 4 --by 500 output_prefix aligned.sorted.bam

# Picard WGS metrics (includes coverage histogram)
picard CollectWgsMetrics \
  I=aligned.sorted.bam \
  R=reference.fa \
  O=wgs_metrics.txt
```

| Metric             | Expected (30× WGS) | Issue If                           |
| ------------------ | ------------------- | ---------------------------------- |
| Mean coverage      | ~30×                | <20× (insufficient sequencing)     |
| % bases ≥ 10×     | >95%                | <90% (uneven coverage)             |
| % bases ≥ 20×     | >90%                | <80% (GC bias or capture issues)   |
| Median/Mean ratio  | ~1.0                | <0.8 (highly skewed coverage)      |

### MAPQ Score Distribution

Mapping quality (MAPQ) encodes the probability a read is misaligned: $\text{MAPQ} = -10 \log_{10}(P_{\text{wrong}})$

```bash
# MAPQ distribution
samtools view aligned.sorted.bam | \
  awk '{print $5}' | sort -n | uniq -c | sort -rn | head -10
```

| MAPQ Value | Meaning                                          |
| ---------- | ------------------------------------------------ |
| 0          | Mapped to multiple locations equally well        |
| 1-9        | Low confidence; may be in repetitive region      |
| 10-19      | Moderate confidence                              |
| 20-39      | Good confidence                                  |
| 40-60      | High confidence; unique mapping                  |

**Common filter:** `samtools view -q 20` removes reads with >1% chance of being misaligned.

## Aggregating QC with MultiQC

MultiQC collects outputs from all QC tools into a single interactive report:

```bash
# Run after all QC tools have generated their outputs
multiqc . -o multiqc_report/ -n project_qc

# Or specify exact input directories
multiqc fastqc_raw/ fastqc_clean/ fastp_reports/ \
  star_logs/ picard_metrics/ samtools_stats/ \
  -o multiqc_report/
```

MultiQC provides:
- **General Statistics table** — All samples side-by-side with key metrics
- **Per-tool sections** — Plots for each tool's output
- **Heatmaps** — Identify outlier samples visually

## QC Decision Flowchart

```text
FastQC: Adapter contamination?
├── YES → Run fastp/Cutadapt with appropriate adapter sequences
└── NO ──→ FastQC: Quality drop at 3' end?
            ├── YES → Quality-trim with fastp (--cut_tail)
            └── NO ──→ FastQC: Unusual GC distribution?
                        ├── YES → Check for contamination (map to known genomes)
                        └── NO ──→ Proceed to alignment
                                    │
                                    ▼
                         samtools flagstat: % mapped < 90%?
                         ├── YES → Wrong reference? Contamination? Adapter remnants?
                         └── NO ──→ Picard: Duplication > 30%?
                                    ├── YES → Low input DNA? Too many PCR cycles?
                                    └── NO ──→ Coverage: Mean depth sufficient?
                                                ├── NO → Sequence more
                                                └── YES → Proceed to analysis
```

## Sample-Level QC Thresholds (WGS Example)

| Metric                          | Pass       | Warning     | Fail       |
| ------------------------------- | ---------- | ----------- | ---------- |
| % reads passing filter (fastp)  | >85%       | 70-85%      | <70%       |
| % reads mapped                  | >95%       | 85-95%      | <85%       |
| % properly paired               | >90%       | 80-90%      | <80%       |
| % duplicates                    | <20%       | 20-40%      | >40%       |
| Mean coverage                   | ≥30×       | 20-30×      | <20×       |
| % genome ≥10× coverage         | >95%       | 90-95%      | <90%       |
| Insert size (median)            | 300-500 bp | 150-300 bp  | <150 bp    |
| Mismatch rate                   | <1%        | 1-3%        | >3%        |

## Tools Summary

| Tool                                   | QC Stage          | Key Output                              |
| -------------------------------------- | ----------------- | --------------------------------------- |
| [FastQC](../tools/fastqc.md)           | Read QC (1, 2)    | HTML report per sample                  |
| [fastp](../tools/fastp.md)             | Trim + QC (1→2)   | JSON/HTML metrics + cleaned FASTQ       |
| [samtools](../tools/samtools.md)        | Alignment QC (3)  | flagstat, stats, idxstats, depth        |
| [Picard](../tools/picard.md)           | Alignment QC (3)  | Duplicate, insert size, coverage metrics|
| [MultiQC](../tools/multiqc.md)         | All stages        | Aggregated interactive HTML report      |
| [deepTools](../tools/deeptools.md)     | Alignment QC (3)  | Correlation, PCA, fingerprint plots     |
| [SeqKit](../tools/seqkit.md)           | Read QC (1)       | Fast FASTQ statistics                   |

## Key Concepts for Computer Scientists

| Concept            | Explanation                                                                                   |
| ------------------ | --------------------------------------------------------------------------------------------- |
| Phred scores       | $Q = -10\log_{10}(P)$ — a log-scale confidence metric analogous to signal-to-noise ratio      |
| Library complexity | The number of unique original molecules in the library — analogous to effective sample size    |
| Coverage depth     | Number of independent reads overlapping a position — analogous to redundancy in error coding   |
| GC bias            | Systematic under/over-sampling of sequences by GC content — a form of sampling bias           |
| Batch effects      | Technical variation between sequencing runs — the bioinformatics equivalent of confounders     |
| MAPQ               | Posterior probability of mapping error — models the uniqueness of a read's alignment position  |
