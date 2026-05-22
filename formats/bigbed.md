# BigBed Format

**Extension:** `.bb`, `.bigbed`  
**Type:** Binary (indexed)  
**Specification:** [UCSC BigBed](https://genome.ucsc.edu/goldenPath/help/bigBed.html)

## Purpose

Binary indexed version of BED format. Enables fast random access to interval data in genome browsers without loading entire files. Used for large annotation datasets (peaks, repeats, regulatory elements) that need efficient display.

## Structure

BigBed files contain:
- Compressed BED records
- Built-in R-tree spatial index
- Summary statistics at multiple zoom levels
- AutoSQL schema (field descriptions)

## Indexing

BigBed files are **self-indexed** — no separate index file needed. Random access is built into the format.

## Creating BigBed

```bash
# Sort BED file
sort -k1,1 -k2,2n regions.bed > sorted.bed

# Create chromosome sizes file
cut -f1,2 reference.fa.fai > chrom.sizes

# Convert to BigBed
bedToBigBed sorted.bed chrom.sizes output.bb

# With extra fields (custom BED format)
bedToBigBed -type=bed6 sorted.bed chrom.sizes output.bb

# BED12 (gene structures)
bedToBigBed -type=bed12 genes.bed chrom.sizes genes.bb
```

## Reading BigBed

```bash
# Convert back to BED
bigBedToBed input.bb output.bed

# Extract specific region
bigBedToBed -chrom=chr1 -start=1000000 -end=2000000 input.bb region.bed

# Summary info
bigBedInfo input.bb

# Summary statistics
bigBedSummary input.bb chr1 1000000 2000000 10
```

## BigBed vs BED

| Property        | BigBed      | BED (bgzipped+tabix) |
| --------------- | ----------- | -------------------- |
| Type            | Binary      | Text                 |
| Index           | Built-in    | Separate .tbi        |
| Browser support | Native      | Limited              |
| File size       | Smaller     | Larger               |
| Editable        | No          | Yes                  |
| Creation        | bedToBigBed | bgzip + tabix        |

## Tools That Create This Format

| Tool               | Context                 |
| ------------------ | ----------------------- |
| UCSC `bedToBigBed` | BED → BigBed conversion |
| ENCODE pipeline    | Peak file delivery      |

## Tools That Read This Format

| Tool                    | Purpose             |
| ----------------------- | ------------------- |
| UCSC Genome Browser     | Track display       |
| [IGV](https://igv.org/) | Visualisation       |
| UCSC `bigBedToBed`      | Convert to text BED |

## See Also

- [BED](bed.md) — text interval format
- [BigWig](bigwig.md) — similar binary format for continuous data
