# Bioinformatics File Formats Index

A reference collection of file formats used in bioinformatics analysis pipelines, including indexing strategies and tool relationships.

## Sequence Data

| Format | Extension | Description | Index |
|--------|-----------|-------------|-------|
| [FASTQ](fastq.md) | `.fastq.gz` | Raw sequencing reads with quality scores | None (not indexed) |
| [FASTA](fasta.md) | `.fa`, `.fasta` | Nucleotide/protein sequences | `.fai` (samtools faidx) |

## Alignment Data

| Format | Extension | Description | Index |
|--------|-----------|-------------|-------|
| [SAM](sam.md) | `.sam` | Text alignment format | None (convert to BAM) |
| [BAM](bam.md) | `.bam` | Binary alignment (compressed) | `.bai` (samtools index) or `.csi` |
| [CRAM](cram.md) | `.cram` | Reference-based compressed alignment | `.crai` (samtools index) |

## Variant Data

| Format | Extension | Description | Index |
|--------|-----------|-------------|-------|
| [VCF](vcf.md) | `.vcf.gz` | Variant calls (SNPs, indels, SVs) | `.tbi` (tabix) or `.csi` (bcftools) |
| [BCF](bcf.md) | `.bcf` | Binary VCF (faster I/O) | `.csi` (bcftools index) |

## Genomic Intervals / Annotation

| Format | Extension | Description | Index |
|--------|-----------|-------------|-------|
| [BED](bed.md) | `.bed` | Genomic intervals (0-based) | `.tbi` (tabix, after bgzip) |
| [GFF/GTF](gff-gtf.md) | `.gtf`, `.gff3` | Gene annotation (1-based) | `.tbi` (tabix, after bgzip) |
| [BigBed](bigbed.md) | `.bb` | Binary indexed BED | Self-indexed |

## Coverage / Signal Data

| Format | Extension | Description | Index |
|--------|-----------|-------------|-------|
| [BigWig](bigwig.md) | `.bw` | Binary normalised coverage signal | Self-indexed |
| [BedGraph](bedgraph.md) | `.bedgraph` | Text coverage (BED + value) | `.tbi` (tabix, after bgzip) |
| [WIG](wig.md) | `.wig` | Text wiggle (fixed/variable step) | None (convert to BigWig) |

## Indexing Summary

Quick reference for which index types apply to which formats:

| Index Type | Extension | Created By | Formats |
|------------|-----------|------------|---------|
| BAI | `.bai` | `samtools index` | BAM |
| CSI | `.csi` | `samtools index -c` / `bcftools index` | BAM, VCF, BCF |
| CRAI | `.crai` | `samtools index` | CRAM |
| TBI | `.tbi` | `tabix -p <fmt>` | VCF, BED, GFF (bgzipped) |
| FAI | `.fai` | `samtools faidx` | FASTA |
| Self-indexed | (built-in) | `bedToBigBed` / `bamCoverage` | BigWig, BigBed |

### Index Decision Tree

```
Is it alignment data?
├── BAM → .bai (or .csi for large chroms)
├── CRAM → .crai
└── SAM → convert to BAM first

Is it variant data?
├── VCF.gz → .tbi (tabix) or .csi (bcftools)
└── BCF → .csi (bcftools index)

Is it interval/annotation?
├── BED (bgzipped) → .tbi (tabix -p bed)
├── GFF (bgzipped) → .tbi (tabix -p gff)
└── BigBed → self-indexed

Is it coverage/signal?
├── BigWig → self-indexed
├── BedGraph (bgzipped) → .tbi
└── WIG → convert to BigWig
```

## Coordinate Systems

| System | Formats | Example (first 100bp of chr1) |
|--------|---------|-------------------------------|
| 0-based, half-open | BED, BedGraph, BAM (internal) | `chr1 0 100` |
| 1-based, inclusive | VCF, GFF/GTF, SAM (display), WIG | `chr1:1-100` |

## Format Conversion Paths

```
FASTQ → (align) → SAM → BAM → CRAM
                            ↓
                        VCF/BCF (variant calling)
                            ↓
                        BED (regions of interest)

BAM → BedGraph → BigWig (coverage)
BAM → BED (intervals)
BED → BigBed (indexed intervals)
```
