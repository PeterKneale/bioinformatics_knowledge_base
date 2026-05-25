# Trimmomatic

**Source:** [usadellab.org/cms/?page=trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic)  
**License:** GPL-3.0  
**Category:** Read preprocessing  
**Citation:** Bolger A.M., Lohse M., Usadel B. (2014) *Bioinformatics* 30:2114-2120

## Purpose

Java-based flexible read trimming tool for Illumina sequencing data. Applies a series of trimming steps **in order**: adapter removal, quality trimming (sliding window or leading/trailing), minimum length filtering, and crop/headcrop operations. The step ordering is critical — operations are applied sequentially to each read, and the order you specify them determines the result.

## Installation

```bash
conda install -c bioconda trimmomatic
```

## How It Works

### Processing Model

```text
Input Read:  AAAAACGTACGTACGTACGTACGTACGTACGT (with adapter + low quality end)
                 ↓
Step 1 (ILLUMINACLIP):  Remove adapter match
             CGTACGTACGTACGTACGTACGTACGT
                 ↓
Step 2 (LEADING:3):     Trim low-quality leading bases (none here)
             CGTACGTACGTACGTACGTACGTACGT
                 ↓
Step 3 (TRAILING:3):    Trim low-quality trailing bases
             CGTACGTACGTACGTACGT
                 ↓
Step 4 (SLIDINGWINDOW:4:20):  Scan 4bp window, trim when avg < Q20
             CGTACGTACGTACGT
                 ↓
Step 5 (MINLEN:36):     Drop if shorter than 36bp
             [DROPPED - too short]
```

**Key principle:** Steps execute left-to-right. ILLUMINACLIP should almost always be first (adapters interfere with quality assessment). MINLEN should be last (applied after all trimming).

### Paired-End Output

For paired-end data, Trimmomatic produces **four** output files:

```text
Input:   R1.fastq.gz  +  R2.fastq.gz

Output:  paired_R1.fastq.gz     ← Both mates survived
         unpaired_R1.fastq.gz   ← R1 survived, R2 was dropped
         paired_R2.fastq.gz     ← Both mates survived
         unpaired_R2.fastq.gz   ← R2 survived, R1 was dropped
```

For most downstream tools, you use only the **paired** files. Unpaired files can sometimes be used as additional single-end reads.

## Trimming Steps (Detailed)

### ILLUMINACLIP (Adapter Removal)

```text
ILLUMINACLIP:<fastaFile>:<seed_mismatches>:<palindrome_threshold>:<simple_threshold>[:<minAdapterLength>:<keepBothReads>]
```

| Parameter              | Description                                        | Typical |
| ---------------------- | -------------------------------------------------- | ------- |
| fastaFile              | FASTA of adapter sequences                         | See below |
| seed_mismatches        | Max mismatches in initial 16bp seed match          | 2       |
| palindrome_threshold   | Score threshold for PE palindrome detection        | 30      |
| simple_threshold       | Score threshold for simple adapter match           | 10      |
| minAdapterLength       | Min adapter fragment to detect (PE palindrome)     | 2       |
| keepBothReads          | Keep both reads in PE palindrome (True/False)      | True    |

**Two detection modes:**

1. **Simple mode** — Aligns adapter sequence against read. Each matching base scores +0.6; threshold of 10 requires ~17bp match.

2. **Palindrome mode** (PE only) — Detects adapter read-through where R1 and R2 overlap. When insert < read length, reads extend into the adapter of the opposite mate:

```text
Insert:    =============================
R1 read:   =============================>>>adapter>>>
R2 read:   <<<adapter<<<=============================

When insert is short, R1 reads into R2 adapter and vice versa.
Palindrome detection aligns R1 and reverse-complement of R2 to find this.
```

### Bundled Adapter Files

| File                    | Use For                                   |
| ----------------------- | ----------------------------------------- |
| `TruSeq2-SE.fa`        | TruSeq v2 single-end                      |
| `TruSeq2-PE.fa`        | TruSeq v2 paired-end (simple mode)        |
| `TruSeq3-SE.fa`        | TruSeq v3 single-end                      |
| `TruSeq3-PE.fa`        | TruSeq v3 paired-end (simple mode)        |
| `TruSeq3-PE-2.fa`      | TruSeq v3 paired-end (palindrome mode)    |
| `NexteraPE-PE.fa`      | Nextera paired-end                        |

**Finding adapter files:**

```bash
# Conda installation
ls $(dirname $(which trimmomatic))/../share/trimmomatic*/adapters/

# Or specify full path
ADAPTERS=$(dirname $(which trimmomatic))/../share/trimmomatic-0.39-2/adapters
trimmomatic PE ... ILLUMINACLIP:$ADAPTERS/TruSeq3-PE-2.fa:2:30:10:2:True
```

### SLIDINGWINDOW

```text
SLIDINGWINDOW:<windowSize>:<requiredQuality>
```

Scans the read from 5' to 3' with a sliding window. Once the **average quality within the window** drops below the threshold, the read is clipped at that position.

| Parameter       | Description                      | Typical |
| --------------- | -------------------------------- | ------- |
| windowSize      | Window width in bases            | 4       |
| requiredQuality | Minimum average quality in window| 15-25   |

```text
Quality:  30 30 28 25 22 18 15 12 10 8
Window=4: [30 30 28 25]=28.3 PASS
              [30 28 25 22]=26.3 PASS
                  [28 25 22 18]=23.3 PASS
                      [25 22 18 15]=20.0 PASS (if threshold=20)
                          [22 18 15 12]=16.8 FAIL -> CLIP HERE
Result:   30 30 28 25 22 18 15  (trailing bases removed)
```

### LEADING / TRAILING

```text
LEADING:<quality>     ← Remove bases from start if below quality
TRAILING:<quality>    ← Remove bases from end if below quality
```

Simpler than SLIDINGWINDOW: trims individual bases from either end if below threshold. Less aggressive than sliding window.

### CROP / HEADCROP

```text
CROP:<length>         ← Cut read to exactly this length (from 3' end)
HEADCROP:<length>     ← Remove N bases from the start of the read
```

Used for:
- `HEADCROP:12` — Remove random hexamer priming bias (first 12bp in RNA-seq)
- `CROP:100` — Truncate all reads to uniform length (for some tools)

### MINLEN

```text
MINLEN:<length>       ← Drop reads shorter than this after all trimming
```

**Always put last.** Reads below this length after all other processing are discarded entirely.

### AVGQUAL

```text
AVGQUAL:<quality>     ← Drop read if average quality is below threshold
```

A read-level filter (the whole read passes or is dropped). Less common than SLIDINGWINDOW.

### MAXINFO (Adaptive)

```text
MAXINFO:<targetLength>:<strictness>
```

An adaptive quality trimmer that balances read length vs quality. Strictness 0.0-1.0: lower = keep longer reads with some errors; higher = prefer shorter but cleaner.

## Usage Examples

### Standard Paired-End (Most Common)

```bash
trimmomatic PE -threads 8 -phred33 \
  reads_R1.fastq.gz reads_R2.fastq.gz \
  paired_R1.fastq.gz unpaired_R1.fastq.gz \
  paired_R2.fastq.gz unpaired_R2.fastq.gz \
  ILLUMINACLIP:TruSeq3-PE-2.fa:2:30:10:2:True \
  LEADING:3 \
  TRAILING:3 \
  SLIDINGWINDOW:4:20 \
  MINLEN:36
```

### For Variant Calling (Aggressive Quality)

```bash
trimmomatic PE -threads 8 \
  reads_R1.fastq.gz reads_R2.fastq.gz \
  paired_R1.fastq.gz unpaired_R1.fastq.gz \
  paired_R2.fastq.gz unpaired_R2.fastq.gz \
  ILLUMINACLIP:TruSeq3-PE-2.fa:2:30:10:2:True \
  LEADING:10 \
  TRAILING:10 \
  SLIDINGWINDOW:4:25 \
  MINLEN:50
```

### For RNA-Seq (Remove Priming Bias)

```bash
trimmomatic PE -threads 8 \
  reads_R1.fastq.gz reads_R2.fastq.gz \
  paired_R1.fastq.gz unpaired_R1.fastq.gz \
  paired_R2.fastq.gz unpaired_R2.fastq.gz \
  ILLUMINACLIP:TruSeq3-PE-2.fa:2:30:10:2:True \
  HEADCROP:12 \
  SLIDINGWINDOW:4:20 \
  MINLEN:36
```

### Single-End

```bash
trimmomatic SE -threads 8 -phred33 \
  reads.fastq.gz trimmed.fastq.gz \
  ILLUMINACLIP:TruSeq3-SE.fa:2:30:10 \
  SLIDINGWINDOW:4:20 \
  MINLEN:36
```

### Nextera Library

```bash
trimmomatic PE -threads 8 \
  reads_R1.fastq.gz reads_R2.fastq.gz \
  paired_R1.fastq.gz unpaired_R1.fastq.gz \
  paired_R2.fastq.gz unpaired_R2.fastq.gz \
  ILLUMINACLIP:NexteraPE-PE.fa:2:30:10:2:True \
  SLIDINGWINDOW:4:20 \
  MINLEN:36
```

## Step Order Recommendations

| Pipeline Type     | Recommended Order                                         |
| ----------------- | --------------------------------------------------------- |
| General purpose   | ILLUMINACLIP → LEADING → TRAILING → SLIDINGWINDOW → MINLEN |
| Variant calling   | ILLUMINACLIP → LEADING → TRAILING → SLIDINGWINDOW → MINLEN |
| RNA-seq           | ILLUMINACLIP → HEADCROP → SLIDINGWINDOW → MINLEN          |
| Max length retention | ILLUMINACLIP → MAXINFO → MINLEN                        |

**Why order matters:**
- ILLUMINACLIP first: adapters affect quality scores at read ends
- LEADING/TRAILING before SLIDINGWINDOW: clear obvious junk before averaging
- MINLEN last: only apply after all length-reducing operations complete

## Output Statistics

Trimmomatic reports processing statistics to stderr:

```text
Input Read Pairs: 20000000
Both Surviving: 18500000 (92.50%)
Forward Only Surviving: 800000 (4.00%)
Reverse Only Surviving: 500000 (2.50%)
Dropped: 200000 (1.00%)
```

**Interpretation:**

| Metric               | Healthy Range | Concern If...                      |
| -------------------- | ------------- | ---------------------------------- |
| Both Surviving       | >85%          | <80% = too aggressive or bad data  |
| Forward/Reverse Only | <10% each     | >15% = asymmetric quality issues   |
| Dropped              | <5%           | >10% = very low quality library    |

## Choosing Quality Thresholds

| Application             | SLIDING Window Q | MINLEN | Rationale                          |
| ----------------------- | ---------------- | ------ | ---------------------------------- |
| Variant calling (SNPs)  | 25               | 50     | High accuracy needed for SNP calls |
| Variant calling (indels)| 20               | 50     | Balance sensitivity/specificity    |
| RNA-seq quantification  | 20               | 36     | Moderate quality sufficient        |
| De novo assembly        | 20               | 36     | Keep length for overlap detection  |
| Metagenomics            | 15-20            | 50     | Length important for classification|

## Performance

| Metric      | Value                                        |
| ----------- | -------------------------------------------- |
| Speed       | ~5-10 min per 50M PE reads (8 threads)       |
| Memory      | ~500MB (independent of file size)            |
| Parallelism | Good scaling to 8-16 threads                 |
| I/O         | Can be bottleneck with slow storage          |

## Trimmomatic vs fastp

| Feature               | Trimmomatic         | fastp                      |
| --------------------- | ------------------- | -------------------------- |
| Language              | Java                | C++                        |
| Speed                 | Moderate            | 2-5× faster                |
| QC reporting          | No (need FastQC)    | Built-in (HTML + JSON)     |
| Adapter detection     | Requires adapter file| Auto-detection             |
| Step ordering         | User-specified      | Fixed internal order       |
| Configurability       | Very flexible       | Less granular              |
| Deduplication         | No                  | Yes (optional)             |
| Poly-G/X trimming     | No                  | Yes (NovaSeq specific)     |
| UMI handling          | No                  | Yes                        |

**Recommendation:** Use fastp for most new projects (faster, simpler). Use Trimmomatic when you need fine-grained control over step ordering, or when reproducing published pipelines that specify Trimmomatic.

## Common Issues

| Problem                          | Symptom                         | Solution                            |
| -------------------------------- | ------------------------------- | ----------------------------------- |
| Adapter file not found           | FileNotFoundException           | Use full path or set $ADAPTERS var  |
| Wrong adapter file               | Low adapter removal             | Check library prep kit documentation|
| Too aggressive trimming          | >20% reads dropped              | Lower quality thresholds            |
| No quality improvement           | FastQC still fails              | Check if correct adapter file used  |
| Output reads shorter than expected| CROP applied before SLIDINGWINDOW| Check step order                  |

## Produces

- Trimmed FASTQ files (gzip-compressed if input was)
- Paired and unpaired outputs for PE mode (4 files total)
- Processing statistics to stderr

## Related Tools

| Tool                       | Relationship                                     |
| -------------------------- | ------------------------------------------------ |
| [fastp](fastp.md)          | Faster all-in-one alternative (recommended)      |
| [cutadapt](cutadapt.md)   | More flexible adapter removal (Python)           |
| [FastQC](fastqc.md)       | QC before/after trimming                         |
| [MultiQC](multiqc.md)     | Aggregates Trimmomatic statistics                |
