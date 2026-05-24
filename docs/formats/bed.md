# BED Format (Browser Extensible Data)

**Extension:** `.bed`  
**Type:** Text (tab-delimited)  
**Specification:** [UCSC BED Format](https://genome.ucsc.edu/FAQ/FAQformat.html#format1)

## Purpose

Simple tab-delimited format for representing genomic intervals (regions). Used for gene annotations, peaks (ChIP-seq), target regions (capture kits), blacklists, and any set of genomic coordinates. The foundation for interval arithmetic operations.

## Coordinate System (Critical)

BED uses a **0-based, half-open** coordinate system — identical to Python slice semantics and C array indexing:

```text
Genome:     A  C  G  T  A  C  G  T
0-based:    0  1  2  3  4  5  6  7
1-based:    1  2  3  4  5  6  7  8

BED "chr1  2  5" selects:  G  T  A  (positions 2,3,4 — end is exclusive)
                           ^-----^
                           start  end (not included)

SAM/VCF equivalent:  chr1:3-5  (1-based, inclusive)
```

This is the **#1 source of off-by-one errors** in bioinformatics. The key insight: `length = end - start` (no +1 needed).

### Coordinate System Comparison

| Format       | System             | First base | Example (bases 1-100 of chr1) | Length Formula |
| ------------ | ------------------ | ---------- | ----------------------------- | -------------- |
| BED          | 0-based, half-open | 0          | `chr1  0  100`                | end - start    |
| VCF          | 1-based, inclusive | 1          | `chr1  1  .  (POS column)`   | —              |
| SAM          | 1-based, inclusive | 1          | `POS=1, CIGAR=100M`          | sum(CIGAR)     |
| GFF/GTF      | 1-based, inclusive | 1          | `chr1  .  .  1  100`         | end - start + 1|
| UCSC browser | 1-based, inclusive | 1          | `chr1:1-100`                 | end - start + 1|

### Common Conversion Errors

```bash
# VCF → BED: subtract 1 from start only
# VCF POS=1000, REF=A (SNP)
# BED: chr1  999  1000  (length = 1)

# VCF → BED: deletion POS=1000, REF=ACG, ALT=A
# BED: chr1  1000  1003  (positions of deleted bases, not anchor)

# GFF → BED: subtract 1 from start only
# GFF: chr1  1  100 (1-based inclusive, 100 bases)
# BED: chr1  0  100 (0-based half-open, 100 bases)

# BED → GFF: add 1 to start only
# BED: chr1  0  100
# GFF: chr1  1  100
```

## Structure

### Mandatory Fields (BED3)

```tsv
chr1    1000    2000
chr1    3000    4000
chr2    5000    6000
```

| Column | Field      | Description                    |
| ------ | ---------- | ------------------------------ |
| 1      | chrom      | Chromosome name                |
| 2      | chromStart | Start position (0-based)       |
| 3      | chromEnd   | End position (exclusive)       |

### Extended Fields (BED4/BED6/BED12)

| Column | Field       | Description                     | Required In |
| ------ | ----------- | ------------------------------- | ----------- |
| 4      | name        | Feature name                    | BED4+       |
| 5      | score       | Score (0-1000)                  | BED6+       |
| 6      | strand      | `+` or `-`                      | BED6+       |
| 7      | thickStart  | Display start (e.g., CDS start) | BED12       |
| 8      | thickEnd    | Display end (e.g., CDS end)     | BED12       |
| 9      | itemRgb     | Display colour (R,G,B)          | BED12       |
| 10     | blockCount  | Number of blocks (exons)        | BED12       |
| 11     | blockSizes  | Comma-separated block sizes     | BED12       |
| 12     | blockStarts | Comma-separated relative starts | BED12       |

**Important:** You cannot use columns 4-6 selectively. If you want strand (col 6), you must provide name (col 4) and score (col 5) — even if meaningless (use `.` and `0`).

### Examples

```tsv
# BED3 — simple regions
chr1    0       1000
chr1    2000    3000

# BED6 — with name, score, strand
chr1    0       1000    peak_1    500    +
chr1    2000    3000    peak_2    300    -

# BED12 — gene structure (exons as blocks)
chr1    11873   14409   NR_046018   0   +   11873   11873   0   3   354,109,1189,   0,739,1347,
```

### BED12 for Gene Structures

BED12 represents spliced features (genes with introns) using blocks:

```text
chromStart                                              chromEnd
|                                                       |
|==exon1==|--------intron-----------|==exon2==|------|==exon3==|
|<-block1->                          <-block2->       <-block3->|

blockCount:  3
blockSizes:  354,109,1189,
blockStarts: 0,739,1347,        (relative to chromStart)
```

Block starts are **relative** to chromStart. First block always starts at 0.

## Sort Requirements

Different tools require different sort orders. Getting this wrong is a common error source:

```bash
# Standard lexicographic sort (most tools, bedtools, tabix)
sort -k1,1 -k2,2n input.bed > sorted.bed

# Natural chromosome sort (chr1, chr2, ... chr10, not chr1, chr10, chr2)
sort -k1,1V -k2,2n input.bed > sorted_natural.bed

# Sort matching a reference genome's contig order (for GATK)
# Use Picard's BedToIntervalList or manually match reference .dict order
```

| Tool/Context | Required Sort Order                 |
| ------------ | ----------------------------------- |
| bedtools     | Lexicographic (`sort -k1,1 -k2,2n`)|
| tabix        | Same as bedtools                    |
| GATK `-L`   | Must match reference dict order     |
| UCSC tools   | Lexicographic                       |
| IGV          | Any (handles internally)            |

## Indexing

### Tabix Index (`.tbi`)

For random access to bgzip-compressed BED:

```bash
# Sort, compress, and index
sort -k1,1 -k2,2n regions.bed | bgzip > regions.bed.gz
tabix -p bed regions.bed.gz

# Query a region
tabix regions.bed.gz chr1:1000000-2000000
```

### Requirements for Indexing

1. File must be sorted by chromosome and position
2. Must be bgzip-compressed (NOT gzip — block compression required)
3. Chromosome sort order must be consistent throughout file

### Indexed vs Unindexed Trade-offs

| Use Case               | Indexed (`.bed.gz` + `.tbi`) | Plain text (`.bed`)       |
| ---------------------- | ---------------------------- | ------------------------- |
| Whole-file processing  | Slightly slower (decompress) | Fast (no overhead)        |
| Region queries         | O(log n) — instant           | O(n) — scan entire file   |
| File size              | ~30-50% smaller              | Baseline                  |
| Disk I/O              | Minimal (seek to block)      | Read entire file          |
| Editability            | Cannot edit directly         | Text editor friendly      |

## Interval Arithmetic

BED's simplicity makes it the standard input for set operations on genomic regions:

```bash
# Intersection: regions present in both files
bedtools intersect -a peaks.bed -b promoters.bed > overlap.bed

# Subtraction: regions in A but not B
bedtools subtract -a peaks.bed -b blacklist.bed > filtered.bed

# Merge overlapping intervals
sort -k1,1 -k2,2n peaks.bed | bedtools merge > merged.bed

# Complement: gaps between intervals
bedtools complement -i regions.bed -g genome.txt > gaps.bed

# Window: features within N bp of each other
bedtools window -a genes.bed -b variants.bed -w 10000 > nearby.bed

# Closest feature
bedtools closest -a variants.bed -b genes.bed > nearest_gene.bed
```

### Overlap Detection Algorithm

bedtools uses a **sweep-line algorithm** on sorted input — O(n log n) sort + O(n + k) sweep where k = number of overlaps. This is why sort order matters: it enables single-pass processing.

## Common Use Cases

| Use Case              | BED Variant | Example                                          |
| --------------------- | ----------- | ------------------------------------------------ |
| Target capture kit    | BED3/BED4   | Exome panel regions for WES variant calling      |
| ChIP-seq peaks        | BED6        | MACS2 narrowPeak output                          |
| Blacklist regions     | BED3        | ENCODE blacklist (exclude from analysis)         |
| Gene annotations      | BED12       | Exon structure for transcript models             |
| CpG islands           | BED4        | UCSC annotation track                            |
| Variant regions       | BED3        | Regions for targeted variant calling             |
| Coverage windows      | BED3        | Tiled genome for coverage analysis               |

## Validation and Common Issues

```bash
# Check for invalid coordinates (start >= end)
awk '$2 >= $3' input.bed  # should return nothing

# Check for negative coordinates
awk '$2 < 0 || $3 < 0' input.bed

# Check for consistent column count
awk -F'\t' '{print NF}' input.bed | sort -u
# Should return a single number

# Remove header/comment lines (some tools choke on them)
grep -v '^#\|^track\|^browser' input.bed > clean.bed

# Verify sorted order
sort -k1,1 -k2,2n -c input.bed
```

### Common Gotchas

| Issue                          | Symptom                                | Fix                                |
| ------------------------------ | -------------------------------------- | ---------------------------------- |
| Space-delimited (not tabs)     | bedtools fails silently or wrong results | Convert: `sed 's/ /\t/g'`        |
| Windows line endings (`\r\n`)  | Extra characters, parse failures        | `dos2unix` or `tr -d '\r'`       |
| Unsorted input                 | bedtools errors or wrong results        | `sort -k1,1 -k2,2n`              |
| Mixed chr naming (`chr1` vs `1`)| No intersections found                 | Match naming convention           |
| start > end                    | Tool crashes or skips records           | Filter: `awk '$2 < $3'`          |
| 1-based coordinates in BED     | Off-by-one in all downstream results   | Subtract 1 from start column      |
| Header lines                   | Parse errors                           | Remove `track`/`browser` lines    |

## Tools That Create This Format

| Tool                                      | Context                 |
| ----------------------------------------- | ----------------------- |
| [bedtools](../tools/bedtools.md)          | All interval operations |
| [bedtools bamtobed](../tools/bedtools.md) | BAM → BED conversion    |
| Peak callers (MACS2, etc.)                | ChIP-seq/ATAC-seq peaks |
| [UCSC tools](https://genome.ucsc.edu/)    | Annotation downloads    |

## Tools That Read This Format

| Tool                                       | Purpose                   |
| ------------------------------------------ | ------------------------- |
| [bedtools](../tools/bedtools.md)           | Interval arithmetic       |
| [tabix](../tools/tabix.md)                 | Region queries            |
| [samtools](../tools/samtools.md)           | Region specification (-L) |
| [GATK](../tools/gatk.md)                   | Target intervals          |
| [deepTools](../tools/deeptools.md)         | Region matrices           |
| [featureCounts](../tools/featurecounts.md) | Custom regions (SAF)      |
| [FreeBayes](../tools/freebayes.md)         | Target regions (-t)       |
| [IGV](https://igv.org/)                    | Visualisation             |

## See Also

- [GFF/GTF](gff-gtf.md) — richer annotation format (1-based inclusive)
- [BedGraph](bedgraph.md) — BED with coverage scores
- [BigBed](bigbed.md) — indexed binary BED for genome browsers
- [SAM](sam.md) — alignment format (1-based inclusive coordinates)
