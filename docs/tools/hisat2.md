# HISAT2

**Source:** [daehwankimlab.github.io/hisat2](http://daehwankimlab.github.io/hisat2/)  
**License:** GPL-3.0  
**Category:** RNA-seq alignment

## Purpose

Graph-based splice-aware aligner for RNA-seq reads. Uses a **Graph FM index (GFM)** that can incorporate known variants (SNPs) and splice sites directly into the index structure — reads align to a population graph rather than a single linear reference. Significantly lower memory footprint than STAR (~8GB vs ~30GB for human) while maintaining competitive alignment accuracy.

## Installation

```bash
conda install -c bioconda hisat2
```

## Algorithm

### Graph FM Index (GFM)

HISAT2's key innovation is encoding known genetic variation into the index:

```text
Traditional FM-index:  Reference:   ...ACGT[A]CGT...
                       Only matches reads with 'A' at this position

Graph FM-index:        Reference:   ...ACGT[A/G/T]CGT...
                       Known SNPs encoded as graph branches
                       Matches reads with A, G, or T without penalty
```

**Benefits:**
- Reads carrying known variants align correctly without mismatches
- Eliminates reference allele bias in variant-rich regions
- Index incorporates millions of known SNPs with minimal size increase

### Hierarchical Indexing

HISAT2 uses two levels of FM-index:

| Level   | Coverage              | Purpose                               |
| ------- | --------------------- | ------------------------------------- |
| Global  | Entire genome         | Initial seed placement (~64K intervals)|
| Local   | ~57K base regions     | Fine-grained alignment within region  |

The global index finds approximate positions, then local indices refine the alignment. This two-tier approach keeps memory low while maintaining speed.

### Splice-Aware Alignment

For RNA-seq, reads frequently span exon-exon junctions:

```text
Read:     ACGTACGT────────────────────ACGTACGT
Genome:   ACGTACGT[======intron======]ACGTACGT
                  ^                    ^
                  donor (GT)           acceptor (AG)

HISAT2 checks for canonical splice signals (GT-AG, GC-AG, AT-AC)
when a read cannot be fully aligned to a contiguous region.
```

## Key Commands

| Command                          | Description                   |
| -------------------------------- | ----------------------------- |
| `hisat2-build`                   | Build genome index            |
| `hisat2`                         | Align reads                   |
| `hisat2_extract_splice_sites.py` | Extract splice sites from GTF |
| `hisat2_extract_exons.py`        | Extract exons from GTF        |
| `hisat2-inspect`                 | Display index information     |

## Key Options

### Index Building

| Option     | Description                                          |
| ---------- | ---------------------------------------------------- |
| `--ss`     | Known splice sites file (from extract script)        |
| `--exon`   | Known exon coordinates (from extract script)         |
| `--snp`    | Known SNPs to incorporate into graph index           |
| `-p`       | Number of threads for building                       |

### Alignment

| Option              | Description                                          | Default |
| ------------------- | ---------------------------------------------------- | ------- |
| `-x`                | Index basename                                       | Required|
| `-1` / `-2`        | Paired-end read files                                | —       |
| `-U`                | Unpaired read files                                  | —       |
| `--dta`             | Downstream Transcriptome Assembly mode               | Off     |
| `--dta-cufflinks`   | Report alignments tailored for Cufflinks             | Off     |
| `-k INT`            | Report up to INT alignments per read                 | 5       |
| `--no-spliced-alignment` | Disable splice-aware alignment (DNA mode)       | Off     |
| `--known-splicesite-infile` | File of known splice sites                  | —       |
| `--novel-splicesite-outfile` | Output discovered novel splice sites       | —       |
| `--novel-splicesite-infile`  | Use previously discovered novel sites      | —       |
| `--min-intronlen`   | Minimum intron length                                | 20      |
| `--max-intronlen`   | Maximum intron length                                | 500000  |
| `--rna-strandness`  | Strand-specific: F, R, FR, RF                        | Unstranded |
| `--threads` / `-p`  | Number of threads                                    | 1       |
| `--summary-file`    | Write alignment summary to file                      | stderr  |
| `--new-summary`     | Machine-parseable summary format                     | Off     |

### Strand-Specific Libraries

| Library Protocol        | `--rna-strandness` value | Notes                        |
| ----------------------- | ------------------------ | ---------------------------- |
| Unstranded              | (don't specify)          | Default                      |
| dUTP (FR second-strand) | RF                       | Most common stranded protocol|
| Ligation (first-strand) | FR                       | Less common                  |
| Single-end stranded     | F or R                   | Depends on protocol          |

## Usage Examples

```bash
# Extract splice sites and exons from annotation
hisat2_extract_splice_sites.py annotation.gtf > splice_sites.txt
hisat2_extract_exons.py annotation.gtf > exons.txt

# Build index with known splice sites and exons
hisat2-build --ss splice_sites.txt --exon exons.txt \
  reference.fa hisat2_index

# Build index with SNPs (for variant-aware alignment)
hisat2-build --snp genome_snps.snp --haplotype genome_snps.haplotype \
  reference.fa hisat2_snp_index

# Basic paired-end RNA-seq alignment
hisat2 -x hisat2_index \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --dta \
  -p 8 | samtools sort -o aligned.sorted.bam

# Stranded library (dUTP protocol)
hisat2 -x hisat2_index \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --dta --rna-strandness RF \
  -p 8 | samtools sort -o aligned.sorted.bam

# Discovery mode: output novel splice junctions
hisat2 -x hisat2_index \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --dta \
  --novel-splicesite-outfile novel_splicesites.txt \
  -p 8 | samtools sort -o aligned.sorted.bam

# Two-pass approach: use discovered junctions in second pass
hisat2 -x hisat2_index \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --dta \
  --novel-splicesite-infile novel_splicesites.txt \
  -p 8 | samtools sort -o aligned.sorted.bam

# Single-end alignment
hisat2 -x hisat2_index -U reads.fastq.gz \
  -p 8 | samtools sort -o aligned.sorted.bam

# DNA alignment (no splicing)
hisat2 -x hisat2_index \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --no-spliced-alignment \
  -p 8 | samtools sort -o aligned.sorted.bam

# Write machine-parseable summary
hisat2 -x hisat2_index \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --dta -p 8 \
  --new-summary --summary-file alignment_summary.txt \
  | samtools sort -o aligned.sorted.bam
```

## Produces

| Output                        | Description                                   |
| ----------------------------- | --------------------------------------------- |
| SAM to stdout                 | Pipe to samtools for BAM conversion           |
| Alignment summary (stderr)    | Overall/concordant/discordant alignment rates |
| `.ht2` files (8 per index)   | Index files                                   |
| Novel splice site file        | Discovered junctions (if requested)           |

### Alignment Summary (Example)

```text
20000000 reads; of these:
  20000000 (100.00%) were paired; of these:
    1234567 (6.17%) aligned concordantly 0 times
    17654321 (88.27%) aligned concordantly exactly 1 time
    1111112 (5.56%) aligned concordantly >1 times
    ----
    1234567 pairs aligned concordantly 0 times; of these:
      234567 (19.00%) aligned discordantly 1 time
95.5% overall alignment rate
```

**Key metrics to check:**
- Overall alignment rate: >90% typical for good data against matching reference
- Concordant unique (1 time): should be the majority
- Concordantly 0 times: high value suggests wrong reference or contamination

## Pre-Built Indices

HISAT2 provides pre-built indices for common genomes (saves hours of build time):

```bash
# Download pre-built human GRCh38 index
wget https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz
tar -xzf grch38_genome.tar.gz

# With SNPs and transcripts included
wget https://genome-idx.s3.amazonaws.com/hisat/grch38_snptran.tar.gz
```

## Resource Requirements

| Operation     | Memory  | Time (human genome)    | Disk           |
| ------------- | ------- | ---------------------- | -------------- |
| Index build   | ~8 GB   | 1-2 hours              | ~4 GB (.ht2)  |
| Alignment     | ~8 GB   | ~20 min / 50M PE reads | —              |

## HISAT2 vs STAR

| Feature                | HISAT2           | STAR                     |
| ---------------------- | ---------------- | ------------------------ |
| Memory (human)         | ~8 GB            | ~30 GB                   |
| Speed                  | Moderate         | Faster                   |
| Variant-aware          | Yes (graph index)| No                       |
| Novel junction finding | Good             | Excellent (2-pass mode)  |
| Built-in quantification| No              | Yes (--quantMode)        |
| Downstream tool        | StringTie, featureCounts | featureCounts, RSEM |
| Best for               | Low-memory environments | Speed-critical pipelines |

## Related Tools

| Tool                                 | Relationship                            |
| ------------------------------------ | --------------------------------------- |
| [STAR](star.md)                      | Alternative RNA-seq aligner (faster, more RAM) |
| [featureCounts](featurecounts.md)    | Read quantification after alignment     |
| [samtools](samtools.md)              | BAM sorting and indexing                 |
| [StringTie](https://ccb.jhu.edu/software/stringtie/) | Transcript assembly (use with `--dta`) |
| [MultiQC](multiqc.md)               | Aggregates alignment statistics         |
