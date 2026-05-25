# tabix

**Source:** [htslib.org](https://www.htslib.org/) (part of HTSlib)  
**License:** MIT  
**Category:** Indexing and region queries  
**Citation:** Li H. (2011) *Bioinformatics* 27:718-719

## Purpose

Indexes and queries tab-delimited genomic position files (VCF, BED, GFF, SAM). Enables fast O(log n) random access to records overlapping a given genomic region — without scanning the entire file. Works exclusively with **bgzip-compressed** files (block gzip), which support random access unlike standard gzip.

## Installation

```bash
conda install -c bioconda htslib
# or
brew install htslib
```

## How It Works

### The Problem

A 100GB VCF file. You need variants on chr7 between positions 100,000-200,000. Without an index, you must read the entire file sequentially — O(n) where n = file size.

### The Solution

tabix creates a **binning index** that maps genomic intervals to byte offsets in the compressed file:

```text
Step 1: bgzip compresses file into 64KB blocks (each independently decompressible)
Step 2: tabix builds an index mapping (chromosome, position) → block offset

Query "chr7:100000-200000":
  1. Look up chr7 in index → find relevant bins
  2. Bins point to specific bgzip blocks
  3. Seek directly to those blocks (skip everything else)
  4. Decompress only relevant blocks
  5. Filter records within those blocks by position
```

**Result:** Region query is O(log n) regardless of file size.

### bgzip vs gzip

| Property               | gzip              | bgzip                          |
| ---------------------- | ----------------- | ------------------------------ |
| Random access          | No (stream-only)  | Yes (per-block decompression)  |
| Block structure        | Single stream     | Concatenated 64KB blocks       |
| Compatible with gzip   | —                 | Yes (any gzip reader works)    |
| File extension         | `.gz`             | `.gz` (same, but different internal structure) |
| Can be indexed         | No                | Yes (by tabix)                 |

**Critical distinction:** A file compressed with `gzip` **cannot** be indexed by tabix. You must use `bgzip`. To tell them apart: `htslib` will error if you try to index a regular gzip file.

```bash
# Convert gzip to bgzip (must decompress and recompress)
gunzip variants.vcf.gz
bgzip variants.vcf

# Or in one step (pipe through)
zcat variants.vcf.gz | bgzip > variants.bgzip.vcf.gz
```

## Core Workflow

```bash
# 1. Sort the file (required: records must be position-ordered)
sort -k1,1 -k2,2n input.bed > sorted.bed

# 2. Compress with bgzip
bgzip sorted.bed        # → sorted.bed.gz (original removed)

# 3. Index with tabix
tabix -p bed sorted.bed.gz     # → sorted.bed.gz.tbi

# 4. Query regions
tabix sorted.bed.gz chr1:1000000-2000000
```

## Usage Examples

### VCF (Most Common Use Case)

```bash
# Compress and index a VCF
bgzip variants.vcf
tabix -p vcf variants.vcf.gz

# Query a region
tabix variants.vcf.gz chr1:1000000-2000000

# Query with VCF header included (essential for piping to other tools)
tabix -h variants.vcf.gz chr1:1000000-2000000

# Query multiple regions
tabix variants.vcf.gz chr1:100000-200000 chr2:300000-400000

# Query regions from a BED file
tabix -R regions.bed variants.vcf.gz

# Query from a positions file (1-based, one per line: chr\tpos)
tabix -T positions.txt variants.vcf.gz

# Pipe to bcftools for further filtering
tabix -h variants.vcf.gz chr1:1000000-2000000 | bcftools filter -i 'QUAL>30'
```

### BED

```bash
# Sort, compress, index
sort -k1,1 -k2,2n regions.bed | bgzip > regions.bed.gz
tabix -p bed regions.bed.gz

# Query
tabix regions.bed.gz chr1:5000000-6000000
```

### GFF/GTF

```bash
# Sort by position, compress, index
sort -k1,1 -k4,4n annotation.gff3 | bgzip > annotation.gff3.gz
tabix -p gff annotation.gff3.gz

# Query genes in a region
tabix annotation.gff3.gz chr1:1000000-2000000
```

### Custom Format

For non-standard tab-delimited files, specify column positions manually:

```bash
# Custom file with: col1=chrom, col4=start, col5=end
bgzip custom.tsv
tabix -s 1 -b 4 -e 5 custom.tsv.gz

# With comment lines starting with '#'
tabix -s 1 -b 4 -e 5 -c '#' custom.tsv.gz

# Zero-based coordinates (like BED)
tabix -s 1 -b 2 -e 3 --zero-based custom.bed.gz
```

## Key Options

### Indexing Options

| Option        | Description                          | Default         |
| ------------- | ------------------------------------ | --------------- |
| `-p FORMAT`   | Preset: vcf, bed, gff, sam          | —               |
| `--csi`       | Create CSI index (large genomes)     | TBI             |
| `-m INT`      | CSI minimum bin shift                | 14              |
| `-s INT`      | Column for sequence name             | Preset-dependent|
| `-b INT`      | Column for region start              | Preset-dependent|
| `-e INT`      | Column for region end                | Preset-dependent|
| `-S INT`      | Skip first N header lines           | 0               |
| `-c CHAR`     | Comment/header character             | #               |
| `--zero-based`| Coordinates are 0-based             | 1-based         |
| `-f`          | Force overwrite existing index       | —               |

### Query Options

| Option       | Description                              |
| ------------ | ---------------------------------------- |
| `-h`         | Include header lines in output           |
| `-H`         | Output only header                       |
| `-R FILE`    | Regions from BED file                    |
| `-T FILE`    | Targets from tab-delimited file          |
| `-l`         | List all sequence/chromosome names       |
| `-r`         | Reindex (recreate index)                 |
| `--separate-regions` | Add separator between regions   |

### Preset Column Definitions

| Preset | Seq Col | Start Col | End Col | Comment | Coord System |
| ------ | ------- | --------- | ------- | ------- | ------------ |
| vcf    | 1       | 2         | 2       | #       | 1-based      |
| bed    | 1       | 2         | 3       | #       | 0-based      |
| gff    | 1       | 4         | 5       | #       | 1-based      |
| sam    | 3       | 4         | 4       | @       | 1-based      |

## bgzip (Block GZIP)

bgzip is the companion compression tool. It must be used instead of gzip for any file you want to index.

```bash
# Compress (replaces original file)
bgzip file.vcf                    # → file.vcf.gz

# Compress keeping original
bgzip -c file.vcf > file.vcf.gz

# Decompress
bgzip -d file.vcf.gz             # → file.vcf

# Decompress to stdout
bgzip -cd file.vcf.gz            # same as zcat

# Reindex existing bgzip file (rebuild .gzi)
bgzip -r file.vcf.gz

# Compress with specific thread count
bgzip -@ 8 file.vcf

# Set compression level (1=fast, 9=best)
bgzip -l 9 file.vcf
```

### bgzip Internals

```text
┌──────────────────────────────────────────────────────────┐
│ bgzip file (.gz)                                          │
├────────────┬────────────┬────────────┬───────────────────┤
│  Block 1   │  Block 2   │  Block 3   │    ...            │
│  ≤64KB     │  ≤64KB     │  ≤64KB     │                   │
│  (gzip)    │  (gzip)    │  (gzip)    │                   │
└────────────┴────────────┴────────────┴───────────────────┘
     ↑              ↑            ↑
     │              │            │
  Can seek to and decompress any block independently
```

Each block is a valid gzip stream. A virtual file offset combines:
- **Block offset** (bits 16-63): byte position of the compressed block
- **Within-block offset** (bits 0-15): position within decompressed block

This is the same addressing used by BAM (BGZF format).

## Index Types

### TBI (Default)

```bash
tabix -p vcf variants.vcf.gz     # → variants.vcf.gz.tbi
```

- Maximum chromosome size: 2^29 = **512 Mb**
- Sufficient for most organisms (human chr1 = 249 Mb)
- Smaller index file

### CSI (Coordinate Sorted Index)

```bash
tabix --csi variants.vcf.gz      # → variants.vcf.gz.csi
# or
bcftools index variants.vcf.gz   # → .csi by default
```

- **No chromosome size limit** (supports arbitrarily large sequences)
- Required for: wheat (17 Gb genome), some plant genomes, concatenated references
- Slightly larger index, slightly slower queries

### When to Use CSI

| Scenario                              | Use TBI | Use CSI |
| ------------------------------------- | ------- | ------- |
| Human/mouse/standard genomes          | Yes     |         |
| Plant genomes (wheat, pine, lily)     |         | Yes     |
| Chromosomes > 512 Mb                  |         | Yes     |
| Pangenome / concatenated references   |         | Yes     |
| Maximum compatibility with old tools  | Yes     |         |

## Performance

| Operation        | Complexity    | Typical Speed                        |
| ---------------- | ------------- | ------------------------------------ |
| Indexing         | O(n)          | ~1 min per GB of compressed data     |
| Region query     | O(log n + k)  | Milliseconds (k = records in region) |
| Full file scan   | O(n)          | Same as zcat (no benefit from index) |
| List chromosomes | O(1)          | Instant (from index)                 |

## Common Patterns

```bash
# Check if file is bgzipped (vs regular gzip)
file variants.vcf.gz
# bgzip: "variants.vcf.gz: gzip compressed data, extra field"
# regular gzip also says this — better test:
htslib_tabix_check() { tabix -l "$1" 2>&1 | grep -q "not BGZF" && echo "NOT bgzip" || echo "bgzip OK"; }

# List all chromosomes in an indexed file
tabix -l variants.vcf.gz

# Count records in a region (without printing them)
tabix variants.vcf.gz chr1:1000000-2000000 | wc -l

# Extract and recompress a subset
tabix -h variants.vcf.gz chr1 | bgzip > chr1_variants.vcf.gz
tabix -p vcf chr1_variants.vcf.gz

# Combine tabix queries with bcftools
tabix -h variants.vcf.gz chr1:1000000-2000000 | \
  bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n'

# Batch query many regions efficiently
tabix -R targets.bed variants.vcf.gz > target_variants.vcf
```

## Troubleshooting

| Error Message                              | Cause                                    | Fix                                     |
| ------------------------------------------ | ---------------------------------------- | --------------------------------------- |
| `[E::hts_open_format] Failed to open`     | File doesn't exist or wrong path         | Check path                              |
| `the file is not BGZF compressed`          | Used gzip instead of bgzip              | `gunzip && bgzip`                       |
| `the file is not sorted`                   | Records not position-ordered             | Sort before bgzip                       |
| `Could not load .tbi index`               | Index missing or misnamed                | Re-run `tabix -p vcf file.vcf.gz`      |
| Query returns nothing                      | Chromosome naming mismatch              | Check `chr1` vs `1` with `tabix -l`    |
| `[E::idx_test_and_fetch] Region out of range` | Region exceeds chromosome length    | Use CSI index or check coordinates      |

## See Also

| Tool/Format                    | Relationship                                |
| ------------------------------ | ------------------------------------------- |
| [bcftools](bcftools.md)        | Uses tabix indices for VCF random access    |
| [samtools](samtools.md)        | BAM indexing (`.bai`) — same ecosystem      |
| [VCF format](../formats/vcf.md) | Primary use case for tabix                |
| [BED format](../formats/bed.md) | Second most common tabix target            |
| [BAM format](../formats/bam.md) | Uses same BGZF compression as tabix       |
