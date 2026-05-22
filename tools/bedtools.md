# bedtools

**Source:** [bedtools.readthedocs.io](https://bedtools.readthedocs.io/)  
**License:** MIT  
**Category:** Interval arithmetic

## Purpose

Genome arithmetic toolkit for comparing, manipulating, and querying genomic intervals in BED, GFF, VCF, and BAM format. Enables intersection, subtraction, merging, coverage calculation, and other set operations on genomic coordinate ranges.

## Installation

```bash
conda install -c bioconda bedtools
# or
brew install bedtools
```

## Key Commands

| Command      | Description                                  |
| ------------ | -------------------------------------------- |
| `intersect`  | Find overlapping intervals between two files |
| `subtract`   | Remove intervals overlapping another file    |
| `merge`      | Merge overlapping intervals                  |
| `complement` | Return regions NOT covered                   |
| `coverage`   | Compute depth and breadth of coverage        |
| `genomecov`  | Genome-wide coverage histogram/BedGraph      |
| `closest`    | Find nearest feature                         |
| `window`     | Find features within a window                |
| `getfasta`   | Extract FASTA sequences for BED intervals    |
| `sort`       | Sort BED by chromosome and position          |
| `flank`      | Create flanking intervals                    |
| `slop`       | Extend intervals by a fixed size             |
| `multicov`   | Count alignments across multiple BAMs        |

## Usage Examples

```bash
# Find peaks overlapping promoters
bedtools intersect -a peaks.bed -b promoters.bed > overlapping.bed

# Intersect with original entry details from both files
bedtools intersect -a peaks.bed -b genes.bed -wa -wb > detailed.bed

# Subtract blacklist regions from peaks
bedtools subtract -a peaks.bed -b blacklist.bed > clean_peaks.bed

# Merge overlapping intervals
bedtools merge -i sorted_peaks.bed > merged.bed

# Genome-wide coverage in BedGraph format
bedtools genomecov -ibam aligned.sorted.bam -bg > coverage.bedgraph

# Extract FASTA sequences for BED regions
bedtools getfasta -fi reference.fa -bed regions.bed -fo regions.fasta

# Find closest gene for each peak
bedtools closest -a peaks.bed -b genes.bed > nearest_gene.bed

# Compute per-base coverage of features
bedtools coverage -a genes.bed -b aligned.sorted.bam > gene_coverage.bed
```

## Produces

- `.bed` — Interval output files
- `.bedgraph` — Coverage tracks
- `.fasta` — Extracted sequences

## Related Tools

- [samtools](samtools.md) — BAM depth calculation
- [deeptools](deeptools.md) — BAM to BigWig coverage
