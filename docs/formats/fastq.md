# FASTQ Format

**Extension:** `.fastq`, `.fq`, `.fastq.gz`, `.fq.gz`  
**Type:** Text (often gzip-compressed)  
**Encoding:** ASCII  
**Specification:** [Cock et al. 2010, NAR 38:1767-1771](https://doi.org/10.1093/nar/gkp1137)

## Purpose

Stores raw sequencing reads with per-base quality scores. The standard output format from Illumina, PacBio, and Oxford Nanopore sequencing platforms. Each record contains a sequence identifier, the nucleotide sequence, and base-call quality values.

## Structure

Each record consists of exactly 4 lines:

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

| Line | Content                                  |
| ---- | ---------------------------------------- |
| 1    | `@` + Sequence ID + optional description |
| 2    | Raw nucleotide sequence (A, C, G, T, N)  |
| 3    | `+` (optionally followed by ID again)    |
| 4    | Quality scores (same length as line 2)   |

## Quality Encoding

Quality scores represent the probability of an incorrect base call:

$$Q = -10 \log_{10}(P_{error})$$

| Encoding                    | Offset | Range | Platforms                         |
| --------------------------- | ------ | ----- | --------------------------------- |
| Phred+33 (Sanger)           | 33     | 0-41  | Modern Illumina, PacBio, Nanopore |
| Phred+64 (Illumina 1.3-1.7) | 64     | 0-41  | Legacy Illumina (pre-2011)        |

ASCII character `I` (ASCII 73) with Phred+33 = quality score 40 (99.99% accuracy).

## Paired-End Reads

Paired-end data is typically stored in two files with matching read order:
- `sample_R1.fastq.gz` — Forward reads (Read 1)
- `sample_R2.fastq.gz` — Reverse reads (Read 2)

Read names must match between files. Some tools accept interleaved format (R1 and R2 alternating in one file).

## Indexing

FASTQ files are not typically indexed. For random access, convert to BAM (after alignment) or use tools like `seqkit faidx` on FASTA.

## Compression

- Always store compressed (`.fastq.gz`) — typically 3-5× size reduction
- Use `pigz` for parallel compression: `pigz -p 8 reads.fastq`

## Tools That Create This Format

| Tool                                   | Context                    |
| -------------------------------------- | -------------------------- |
| Sequencing platforms                   | Primary output             |
| [fastp](../tools/fastp.md)             | Trimmed/filtered reads     |
| [Trimmomatic](../tools/trimmomatic.md) | Trimmed reads              |
| [Cutadapt](../tools/cutadapt.md)       | Adapter-removed reads      |
| [samtools fastq](../tools/samtools.md) | Extracted from BAM         |
| [SeqKit](../tools/seqkit.md)           | Filtered/transformed reads |

## Tools That Read This Format

| Tool                             | Purpose                   |
| -------------------------------- | ------------------------- |
| [FastQC](../tools/fastqc.md)     | Quality assessment        |
| [BWA](../tools/bwa.md)           | Alignment                 |
| [Bowtie2](../tools/bowtie2.md)   | Alignment                 |
| [STAR](../tools/star.md)         | RNA-seq alignment         |
| [HISAT2](../tools/hisat2.md)     | RNA-seq alignment         |
| [minimap2](../tools/minimap2.md) | Long-read alignment       |
| [Kallisto](../tools/kallisto.md) | Pseudoalignment           |
| [Salmon](../tools/salmon.md)     | Transcript quantification |
| [SeqKit](../tools/seqkit.md)     | Manipulation              |

## See Also

- [FASTA](fasta.md) — sequence without quality scores
- [BAM](bam.md) — aligned reads (downstream of FASTQ)
