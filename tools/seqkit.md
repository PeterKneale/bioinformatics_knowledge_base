# SeqKit

**Source:** [bioinf.shenwei.me/seqkit](https://bioinf.shenwei.me/seqkit/)  
**License:** MIT  
**Category:** FASTA/FASTQ toolkit

## Purpose

Ultrafast cross-platform toolkit for FASTA/FASTQ file manipulation. Provides a comprehensive set of subcommands for searching, filtering, converting, splitting, and summarising sequence files. Written in Go — single binary, no dependencies.

## Installation

```bash
conda install -c bioconda seqkit
# or
brew install seqkit
```

## Key Subcommands

| Command | Description |
|---------|-------------|
| `stats` | Sequence statistics (count, length, GC) |
| `grep` | Search by name, sequence, or motif |
| `seq` | Transform sequences (revcomp, translate, filter) |
| `subseq` | Extract subsequences by region/BED/GTF |
| `fx2tab` / `tab2fx` | Convert to/from tabular format |
| `split` / `split2` | Split files by count, size, or ID |
| `sample` | Random subsample |
| `sort` | Sort by name, length, or sequence |
| `rmdup` | Remove duplicate sequences |
| `replace` | Regex find/replace in headers or sequences |
| `convert` | Convert quality encoding (Phred33/64) |
| `pair` | Match paired-end reads |
| `head` / `range` | Extract first N or range of sequences |
| `faidx` | FASTA index and random access |

## Usage Examples

```bash
# Sequence statistics
seqkit stats *.fastq.gz

# Detailed statistics (N50, L50, GC)
seqkit stats -a genome.fa

# Extract sequences by name/pattern
seqkit grep -n -r -p "^chr[0-9]+" genome.fa > autosomes.fa

# Search by sequence motif
seqkit grep -s -r -p "ATGCGATCGA" sequences.fa

# Reverse complement
seqkit seq -r -p sequences.fa > revcomp.fa

# Filter by length
seqkit seq -m 1000 contigs.fa > long_contigs.fa

# Extract subsequence by BED
seqkit subseq --bed regions.bed genome.fa > extracted.fa

# Convert FASTQ to FASTA
seqkit fq2fa reads.fastq.gz > reads.fa

# Random subsample (10,000 reads)
seqkit sample -n 10000 reads.fastq.gz -o subset.fastq.gz

# Split FASTQ into chunks of 1M reads
seqkit split2 -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz -s 1000000

# Remove duplicate sequences
seqkit rmdup -s sequences.fa > unique.fa

# Sort by sequence length (descending)
seqkit sort -l -r contigs.fa > sorted.fa

# Tab-delimited output (name, seq, qual)
seqkit fx2tab reads.fastq.gz | head
```

## Produces

- FASTA/FASTQ files (various transformations)
- Tab-delimited output
- Statistics tables

## Related Tools

- [samtools faidx](samtools.md) — FASTA indexing and extraction
- [bioawk](https://github.com/lh3/bioawk) — Awk for biological formats
