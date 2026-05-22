# BED Format (Browser Extensible Data)

**Extension:** `.bed`  
**Type:** Text (tab-delimited)  
**Specification:** [UCSC BED Format](https://genome.ucsc.edu/FAQ/FAQformat.html#format1)

## Purpose

Simple tab-delimited format for representing genomic intervals (regions). Used for gene annotations, peaks (ChIP-seq), target regions (capture kits), blacklists, and any set of genomic coordinates. The foundation for interval arithmetic operations.

## Structure

### Mandatory Fields (BED3)

```
chr1    1000    2000
chr1    3000    4000
chr2    5000    6000
```

| Column | Field      | Description              |
| ------ | ---------- | ------------------------ |
| 1      | chrom      | Chromosome name          |
| 2      | chromStart | Start position (0-based) |
| 3      | chromEnd   | End position (exclusive) |

**Important:** BED is **0-based, half-open** — `chr1 0 100` means bases 1-100 in 1-based coordinates.

### Extended Fields (BED6, BED12)

| Column | Field       | Description                     |
| ------ | ----------- | ------------------------------- |
| 4      | name        | Feature name                    |
| 5      | score       | Score (0-1000)                  |
| 6      | strand      | `+` or `-`                      |
| 7      | thickStart  | Display start (e.g., CDS start) |
| 8      | thickEnd    | Display end (e.g., CDS end)     |
| 9      | itemRgb     | Display colour (R,G,B)          |
| 10     | blockCount  | Number of blocks (exons)        |
| 11     | blockSizes  | Comma-separated block sizes     |
| 12     | blockStarts | Comma-separated block starts    |

### Examples

```
# BED3 — simple regions
chr1    0       1000
chr1    2000    3000

# BED6 — with name, score, strand
chr1    0       1000    peak_1    500    +
chr1    2000    3000    peak_2    300    -

# BED12 — gene structure (exons as blocks)
chr1    11873   14409   NR_046018   0   +   11873   11873   0   3   354,109,1189,   0,739,1347,
```

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
2. Must be bgzip-compressed (not gzip)
3. Chromosome sort order must be consistent

## Coordinate System Note

| Format      | System             | Example (first 100 bases of chr1) |
| ----------- | ------------------ | --------------------------------- |
| BED         | 0-based, half-open | `chr1 0 100`                      |
| VCF/GFF/SAM | 1-based, inclusive | `chr1:1-100`                      |

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

- [GFF/GTF](gff-gtf.md) — richer annotation format
- [BedGraph](bedgraph.md) — BED with coverage scores
- [BigBed](bigbed.md) — indexed binary BED
