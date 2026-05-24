# FASTQ Format

**Extension:** `.fastq`, `.fq`, `.fastq.gz`, `.fq.gz`  
**Type:** Text (often gzip-compressed)  
**Encoding:** ASCII  
**Specification:** [Cock et al. 2010, NAR 38:1767-1771](https://doi.org/10.1093/nar/gkp1137)

## Purpose

Stores raw sequencing reads with per-base quality scores. The standard output format from Illumina, PacBio, and Oxford Nanopore sequencing platforms. Each record contains a sequence identifier, the nucleotide sequence, and base-call quality values. This is the starting point of virtually every bioinformatics pipeline.

## Structure

Each record consists of exactly **4 lines** (not variable — this is a hard constraint exploited by parsers):

```text
@SEQ_ID optional_description
SEQUENCE
+
QUALITY
```

### Example

```text
@SRR001666.1 071112_SLXA-EAS1_s_7:5:1:817:345 length=72
GGGTGATGGCCGCTGCCGATGGCGTCAAATCCCACCAAGTTACCCTTAACAACTTAAGGGTTTTCAAATAGA
+
IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII9IG9ICIIIIIIIIIIIIIIIIIIIIDIIIIIII>IIIIII/
```

### Fields

| Line | Content                                  | Constraint                                 |
| ---- | ---------------------------------------- | ------------------------------------------ |
| 1    | `@` + Sequence ID + optional description | Must start with `@`; ID is first whitespace-delimited token |
| 2    | Raw nucleotide sequence (A, C, G, T, N)  | No line breaks within a single read        |
| 3    | `+` (optionally followed by ID again)    | Separator; usually just `+` to save space  |
| 4    | Quality scores (same length as line 2)   | **Must be exactly same length as line 2**  |

### Illumina Read Identifier Format

Modern Illumina platforms produce structured read IDs:

```text
@Instrument:RunID:FlowcellID:Lane:Tile:X:Y Read:Filtered:ControlBits:IndexSequence
@A00516:245:HVFMYDSXY:2:1101:1247:1000 1:N:0:ATCACGAT+AGATCTCG
```

| Field        | Example       | Meaning                                      |
| ------------ | ------------- | -------------------------------------------- |
| Instrument   | A00516        | Sequencer serial number                      |
| RunID        | 245           | Run counter for this instrument              |
| FlowcellID   | HVFMYDSXY     | Unique flow cell barcode                     |
| Lane         | 2             | Flow cell lane (1-8)                         |
| Tile         | 1101          | Tile within lane                             |
| X:Y          | 1247:1000     | Cluster coordinates on tile                  |
| Read         | 1             | Read 1 or Read 2 (paired-end)               |
| Filtered     | N             | Y = failed quality filter, N = passed       |
| ControlBits  | 0             | 0 when not control; nonzero for spike-in     |
| Index        | ATCACGAT+AGATCTCG | i7+i5 sample barcode sequences          |

## Quality Encoding

Quality scores represent the probability of an incorrect base call:

$$Q = -10 \log_{10}(P_{\text{error}})$$

### Phred Score Reference Table

| Phred Score | P(error) | Accuracy | ASCII (Phred+33) | Char |
| ----------- | --------- | -------- | ----------------- | ---- |
| 0           | 1.0       | 0%       | 33                | `!`  |
| 10          | 0.1       | 90%      | 43                | `+`  |
| 20          | 0.01      | 99%      | 53                | `5`  |
| 30          | 0.001     | 99.9%    | 63                | `?`  |
| 37          | 0.0002    | 99.98%   | 70                | `F`  |
| 40          | 0.0001    | 99.99%   | 73                | `I`  |
| 41          | 0.00008   | 99.992%  | 74                | `J`  |

### Encoding History

| Encoding                    | Offset | Q Range | ASCII Range | Era                         |
| --------------------------- | ------ | ------- | ----------- | --------------------------- |
| Phred+33 (Sanger/Illumina 1.8+) | 33 | 0-41   | `!` to `J`  | **Current standard** (2011+) |
| Phred+64 (Illumina 1.3-1.7) | 64    | 0-41    | `@` to `h`  | Legacy (2006-2011)          |
| Phred+33 (Solexa)           | 33     | -5 to 40 | `;` to `h` | Very old Solexa data         |

**How to detect encoding:** If quality line contains characters below `@` (ASCII 64), it's Phred+33. If the lowest character is `@` or above, it may be Phred+64.

```bash
# Quick encoding check — show the ASCII range in quality lines
zcat reads.fastq.gz | awk 'NR%4==0' | head -1000 | fold -w1 | sort | uniq | head -5
```

## Paired-End Reads

Paired-end data is typically stored in two files with matching read order:
- `sample_R1.fastq.gz` — Forward reads (Read 1)
- `sample_R2.fastq.gz` — Reverse reads (Read 2)

### Ordering Contract

Records in R1 and R2 files must be in **exactly the same order** — the Nth record in R1 is the mate of the Nth record in R2. This is a strict invariant; violating it causes silent mispairing. Tools like `fastp --detect_adapter_for_pe` and `bbtools repair.sh` can fix broken pairing.

### Interleaved Format

Some tools accept both mates interleaved in one file (R1, R2, R1, R2...):

```bash
# Create interleaved FASTQ
seqkit pair -1 sample_R1.fastq.gz -2 sample_R2.fastq.gz -o interleaved.fastq.gz

# BWA accepts interleaved input with -p flag
bwa mem -p reference.fa interleaved.fastq.gz | samtools sort -o aligned.bam
```

### Insert Size and Read Orientation

```text
5'──── Read 1 ────→                    ←──── Read 2 ────5'
|================|-------- gap --------|================|
|<──────────────── Insert Size (TLEN) ──────────────────>|
```

The **insert** is the original DNA fragment between adapters. For typical Illumina libraries:
- Insert size: 300-500 bp
- Read length: 150 bp
- If insert < 2 × read length, reads overlap (adapter trimming needed)

## Compression

### Standard gzip (`.fastq.gz`)

Most common; produced by `gzip` or `pigz` (parallel gzip):

```bash
# Compress (single-threaded)
gzip reads.fastq

# Parallel compression (much faster)
pigz -p 8 reads.fastq

# Parallel decompression
pigz -d -p 8 reads.fastq.gz
```

**Compression ratio:** Typically 3-5× (a 30GB FASTQ → ~8GB compressed).

### Block gzip (bgzip) — For Indexable FASTQ

```bash
# bgzip enables random access with an index
bgzip reads.fastq          # → reads.fastq.gz (bgzip format)
# NOT the same as gzip internally (block structure), but compatible for reading
```

bgzip produces gzip-compatible output but with a block structure that enables random access (see [BAM](bam.md) for BGZF details). This is rarely needed for FASTQ but is required for tabix-indexed formats.

## Validation and Common Issues

| Issue                        | Symptom                           | Fix                                   |
| ---------------------------- | --------------------------------- | ------------------------------------- |
| Truncated file               | Tool crashes mid-read             | Re-download; `gzip -t file.gz`        |
| Broken pairing               | Mismatched read names between R1/R2 | `bbtools repair.sh`                 |
| Mixed encodings              | Negative quality scores           | Convert with `seqkit convert`          |
| Line breaks in sequence      | 5+ lines per record               | Reformat (not valid FASTQ)            |
| Qual length ≠ seq length     | Parser error                      | Corrupt record — filter/remove        |
| `@` in quality line          | Ambiguous record boundary         | This is valid; parsers use 4-line rule |

```bash
# Validate FASTQ integrity
seqkit stats reads.fastq.gz          # Basic stats + detects errors
gzip -t reads.fastq.gz               # Check gzip integrity
zcat reads.fastq.gz | wc -l | awk '{print $1/4}'  # Count reads (must be exact /4)
```

## Indexing

FASTQ files are **not indexed** for random access. This is by design — they represent a stream of reads in arbitrary order. For positional access to sequences, align to BAM (indexed) or convert to FASTA (indexable with `.fai`).

## File Size Reference

| Experiment          | Reads (PE)   | Raw FASTQ Size | Compressed (.gz) |
| ------------------- | ------------ | -------------- | ---------------- |
| WGS 30× human      | ~900M pairs  | ~270 GB        | ~70-90 GB        |
| WES 100×            | ~100M pairs  | ~30 GB         | ~8-12 GB         |
| RNA-seq (standard)  | ~30M pairs   | ~9 GB          | ~2-4 GB          |
| ChIP-seq            | ~30M SE      | ~4.5 GB        | ~1-2 GB          |
| Amplicon/16S        | ~100K pairs  | ~30 MB         | ~8-15 MB         |

## Tools That Create This Format

| Tool                                   | Context                    |
| -------------------------------------- | -------------------------- |
| Sequencing platforms (bcl2fastq/DRAGEN) | Primary output from sequencer |
| [fastp](../tools/fastp.md)             | Trimmed/filtered reads     |
| [Trimmomatic](../tools/trimmomatic.md) | Trimmed reads              |
| [Cutadapt](../tools/cutadapt.md)       | Adapter-removed reads      |
| [samtools fastq](../tools/samtools.md) | Extracted from BAM         |
| [SeqKit](../tools/seqkit.md)           | Filtered/transformed reads |
| SRA Toolkit (`fasterq-dump`)           | Downloaded from NCBI SRA   |

## Tools That Read This Format

| Tool                             | Purpose                   |
| -------------------------------- | ------------------------- |
| [FastQC](../tools/fastqc.md)     | Quality assessment        |
| [fastp](../tools/fastp.md)       | QC + trimming             |
| [BWA](../tools/bwa.md)           | DNA alignment             |
| [Bowtie2](../tools/bowtie2.md)   | DNA alignment             |
| [STAR](../tools/star.md)         | RNA-seq alignment         |
| [HISAT2](../tools/hisat2.md)     | RNA-seq alignment         |
| [minimap2](../tools/minimap2.md) | Long-read alignment       |
| [Kallisto](../tools/kallisto.md) | Pseudoalignment           |
| [Salmon](../tools/salmon.md)     | Transcript quantification |
| [SeqKit](../tools/seqkit.md)     | Manipulation/stats        |

## Downloading FASTQ from Public Repositories

```bash
# From NCBI SRA (most common public sequencing archive)
# Install: conda install -c bioconda sra-tools
fasterq-dump --split-files SRR12345678 -O output_dir/
# Produces: SRR12345678_1.fastq, SRR12345678_2.fastq (paired-end)

# From ENA (European Nucleotide Archive — often faster)
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR123/008/SRR12345678/SRR12345678_1.fastq.gz
```

## See Also

- [FASTA](fasta.md) — sequence without quality scores
- [BAM](bam.md) — aligned reads (downstream of FASTQ)
- [Sequencing process](../processes/sequencing.md) — how FASTQ files are generated
- [Quality control](../processes/quality-control.md) — interpreting FASTQ quality metrics
