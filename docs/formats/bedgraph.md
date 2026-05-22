# BedGraph Format

**Extension:** `.bedgraph`, `.bg`  
**Type:** Text (tab-delimited)  
**Specification:** [UCSC BedGraph](https://genome.ucsc.edu/goldenPath/help/bedgraph.html)

## Purpose

BED-like format for displaying continuous-valued data (genome coverage, signal intensity) as a genome browser track. Each line specifies a genomic interval and an associated value. More flexible than WIG for non-uniform intervals.

## Structure

Four columns, tab-delimited:

```
chromA  chromStartA  chromEndA  dataValueA
```

### Example

```
chr1    0       1000    1.5
chr1    1000    2000    3.2
chr1    2000    2500    0.0
chr1    2500    3000    2.1
```

| Column | Description        |
| ------ | ------------------ |
| 1      | Chromosome         |
| 2      | Start (0-based)    |
| 3      | End (exclusive)    |
| 4      | Data value (float) |

## Coordinate System

BedGraph uses **0-based, half-open** coordinates (same as BED).

## Indexing

### Tabix Index

```bash
# Sort and compress
sort -k1,1 -k2,2n coverage.bedgraph | bgzip > coverage.bedgraph.gz

# Create tabix index
tabix -p bed coverage.bedgraph.gz

# Query region
tabix coverage.bedgraph.gz chr1:1000000-2000000
```

### Convert to BigWig (recommended for large files)

```bash
# Generate chromosome sizes
cut -f1,2 reference.fa.fai > chrom.sizes

# Convert to BigWig (self-indexed, smaller, faster)
bedGraphToBigWig coverage.bedgraph chrom.sizes coverage.bw
```

## Tools That Create This Format

| Tool                                           | Context               |
| ---------------------------------------------- | --------------------- |
| [bedtools genomecov -bg](../tools/bedtools.md) | Coverage from BAM/BED |
| Various signal processing tools                | Normalised scores     |

## Tools That Read This Format

| Tool                             | Purpose             |
| -------------------------------- | ------------------- |
| UCSC `bedGraphToBigWig`          | Convert to BigWig   |
| [tabix](../tools/tabix.md)       | Region queries      |
| [bedtools](../tools/bedtools.md) | Interval operations |
| Genome browsers                  | Track display       |

## BedGraph vs BigWig

| Property        | BedGraph     | BigWig       |
| --------------- | ------------ | ------------ |
| Type            | Text         | Binary       |
| Indexed         | Via tabix    | Self-indexed |
| Random access   | With tabix   | Built-in     |
| File size       | Larger       | Smaller      |
| Editable        | Yes          | No           |
| Browser display | Must convert | Direct       |

## See Also

- [BigWig](bigwig.md) — indexed binary version (preferred for production)
- [WIG](wig.md) — alternative text coverage format
- [BED](bed.md) — interval format (without values)
